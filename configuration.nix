{ config, lib, pkgs, host, ... }:

let
	mh = "main";
	gh = "gaming";
	getByHost = first: second:
		if host.name == mh then first
		else if host.name == gh then second
		else throw "Unsupported host: ${host.name}";
	gitsshsetup = import ./scripts/gitsshsetup.nix pkgs;
	chlayout = import ./scripts/chlayout.nix pkgs;
	cpuperf = import ./scripts/cpuperf.nix pkgs;
	game-performance = import ./scripts/game-performance.nix pkgs;
	virt = import ./scripts/virt.nix pkgs;
	desiredFlatpaks = [
		"com.discordapp.Discord"
	] ++ getByHost [
	] [
	];
	nixupd = pkgs.writeShellScriptBin "nixupd" ''
if_root_chown() {
	if [ "$(stat -c "%U" "$1")" == "root" ]; then
		sudo chown ivan "$dotsdir/flake.lock"
	fi
}

dotsdir="$HOME/dotfiles"
if [ ! -d "$dotsdir" ]; then
	echo "can't find dotfiles in directory $dotsdir"
	return 1
fi

# optional update
if [ "$1" == "upgrade" ]; then
	nix flake update --flake "$dotsdir"
fi

# Prepare
if [ -f "$dotsdir/flake.lock" ]; then
	if_root_chown "$dotsdir/flake.lock"
	mv -v "$dotsdir/flake.lock" "$dotsdir/flake.lock.${host.name}"
fi
if [ -d "$dotsdir/.git.no" ]; then
	mv -v "$dotsdir/.git.no" "$dotsdir/.git"
fi

# Building
if [ -f "$dotsdir/flake.lock.${host.name}" ]; then
	if_root_chown "$dotsdir/flake.lock.${host.name}"
	mv -v "$dotsdir/flake.lock.${host.name}" "$dotsdir/flake.lock"
fi
if [ -d "$dotsdir/.git" ]; then
	mv -v "$dotsdir/.git" "$dotsdir/.git.no"
fi
sudo nixos-rebuild --flake "$dotsdir/#${host.name}" switch

# After build
if [ -f "$dotsdir/flake.lock" ]; then
	if_root_chown "$dotsdir/flake.lock"
	cp -vf "$dotsdir/flake.lock" "$dotsdir/flake.lock.${host.name}"
fi
if [ -d "$dotsdir/.git.no" ]; then
	mv -v "$dotsdir/.git.no" "$dotsdir/.git"
fi
	'';
	flatpak-update = pkgs.writeShellScriptBin "flatpak-update" ''
echo "Adding flathub repo if not exists"
${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
installedFlatpaks=$(${pkgs.flatpak}/bin/flatpak list --app --columns=application)

for installed in $installedFlatpaks; do
	if ! echo ${toString desiredFlatpaks} | ${pkgs.gnugrep}/bin/grep -q $installed; then
		echo "Removing $installed"
		${pkgs.flatpak}/bin/flatpak uninstall -y --noninteractive $installed
	fi
done

for app in ${toString desiredFlatpaks}; do
	echo "Installing $app"
	${pkgs.flatpak}/bin/flatpak install -y flathub $app
done

echo "Removing unused apps and updating"
${pkgs.flatpak}/bin/flatpak uninstall --unused -y
${pkgs.flatpak}/bin/flatpak update -y
	'';
	dualsound = pkgs.writeShellScriptBin "dualsound" ''
dualsense_name="alsa_output.usb-Sony_Interactive_Entertainment_DualSense_Wireless_Controller-00.analog-surround-40"
if [ "$1" == "toggle" ]; then
	if [ "$(pw-link -l | xargs | grep "playback.surround_40_output:output_FL |-> $dualsense_name:playback_FL |-> $dualsense_name:playback_RL")" == "" ]; then
		${if config.services.desktopManager.plasma6.enable then "${pkgs.libnotify}/bin/notify-send 'Dualsense Haptic' 'Activated'" else ""}
		echo "activating"
		pw-link playback.surround_40_output:output_FL $dualsense_name:playback_RL
		pw-link playback.surround_40_output:output_FR $dualsense_name:playback_RR
	else
		${if config.services.desktopManager.plasma6.enable then "${pkgs.libnotify}/bin/notify-send 'Dualsense Haptic' 'Deactivated'" else ""}
		echo "deactivating"
		pw-link -d playback.surround_40_output:output_FL $dualsense_name:playback_RL
		pw-link -d playback.surround_40_output:output_FR $dualsense_name:playback_RR
	fi
elif [ "$1" == "level" ]; then
	if [ "$2" == "" ]; then
		echo "provide a level (number in range 0 to 100)"
		exit 1
	fi
	level="$2"
	${if config.services.desktopManager.plasma6.enable then ''${pkgs.libnotify}/bin/notify-send 'Dualsense Haptic' "Set level to $level%"'' else ""}
	pactl set-sink-volume $dualsense_name 100% 100% $level% $level%
else
	echo "no such command"
	exit 1
fi
	'';
	killsteamgame = pkgs.writeShellScriptBin "killsteamgame" ''
${pkgs.killall}/bin/killall GameThread
	'';
in {
	nix = {
		settings = {
			experimental-features = ["nix-command" "flakes"];
			auto-optimise-store = true;
		};
	};
	nixpkgs.config.allowUnfree = true;

	imports =
	[
		./hardware-configuration-${host.name}.nix
	];

	boot = {
		loader.systemd-boot.enable = getByHost (lib.mkForce false) true;
		loader.efi.canTouchEfiVariables = true;
		kernelPackages = pkgs.linuxPackages_6_14;
		blacklistedKernelModules = [
		] ++ getByHost [
			"pcspkr"
		] [
			"iTCO_wdt"
			"i915"
		];
		kernelParams = [
			"nowatchdog"
		] ++ getByHost [
		] [
			"intel_iommu=on"
			"nvidia.NVreg_UsePageAttributeTable=1"
			"nvidia.NVreg_DynamicPowerManagement=0"
			"nvidia.Nvreg_PreserveVideoMemoryAllocations=1"
		];
	} // getByHost {
		lanzaboote = {
			enable = true;
			pkiBundle = "/var/lib/sbctl";
		};
	} {
	};

	networking = {
		wireless.iwd = {
			enable = getByHost true false;
			settings = {
				Settings = {
					AutoConnect = true;
				};
			};
		};
		firewall.enable = false;
		nftables = {
			enable = true;
			flushRuleset = true;
			ruleset = ''
table ip nethandler {
	chain INPUT {
		type filter hook input priority filter; policy accept;
		ct original packets 1-6 meta mark & 0x40000000 != 0x40000000 counter packets 1 bytes 36 queue flags bypass to 200
	}

	chain FORWARD {
		type filter hook forward priority filter; policy accept;
		ct original packets 1-6 meta mark & 0x40000000 != 0x40000000 counter packets 0 bytes 0 queue flags bypass to 200
	}

	chain OUTPUT {
		type filter hook output priority filter; policy accept;
		ct original packets 1-6 meta mark & 0x40000000 != 0x40000000 counter packets 2 bytes 96 queue flags bypass to 200
	}
}
			'';
		};
		hostName = "nixos";
	};
	time.timeZone = "Asia/Tomsk";
	i18n.defaultLocale = "en_US.UTF-8";
	console.keyMap = "dvorak";

	hardware = {
		graphics.enable = true;
		graphics.enable32Bit = true;
		nvidia = getByHost {
		} {
			powerManagement.enable = false;
			powerManagement.finegrained = false;
			open = false;
			nvidiaSettings = true;
			package = config.boot.kernelPackages.nvidiaPackages.stable;
		};
	};

	services = {
		xserver = {
			enable = true;
			xkb = {
				layout = "us,ru";
				variant = "dvorak,";
				options = "grp:caps_toggle,terminate:ctrl_alt_bksp";
			};
			videoDrivers = getByHost [ "amdgpu" ] [ "nvidia" ];
			displayManager.lightdm.enable = lib.mkForce false;
		};
		desktopManager = {
			plasma6.enable = getByHost false true;
		};
		displayManager.ly = {
			enable = true;
			settings = {
				animation = "doom";
			};
		};
		pipewire = {
			enable = true;
			pulse.enable = true;
		};
		tlp.enable = getByHost true false;
		sunshine = {
			enable = getByHost false true;
			autoStart = false;
			capSysAdmin = true;
			openFirewall = true;
		};
	};
	environment.plasma6.excludePackages = with pkgs; [
		kdePackages.discover
		kdePackages.krdp
		kdePackages.elisa
		kdePackages.konsole
		kdePackages.khelpcenter
	];

	services.flatpak.enable = true;

	users.defaultUserShell = pkgs.bash;
	users.users.ivan = {
		isNormalUser = true;
		extraGroups = [
			"wheel"
			"audio"
			"video"
			"input"
			"tty"
			"kvm"
			"libvirtd"
		];
		useDefaultShell = true;
	};

	programs = {
		firefox = {
			enable = true;
			package = pkgs.firefox.override (args: args // {
				cfg = args.cfg or {};
				extraPrefs = ''
lockPref("browser.tabs.insertAfterCurrent", true);
lockPref("sidebar.verticalTabs", true);
lockPref("sidebar.sidebarRevamp", true);
lockPref("sidebar.main.tools", "history");
lockPref("browser.ctrlTab.sortByRecentlyUsed", true);
lockPref("general.smoothScroll", true);
lockPref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
lockPref("signon.rememberSignons", false);
lockPref("browser.startup.page", 3);
				'';
			});
			policies = {
				DisableTelemetry = true;
				DisableFirefoxStudies = true;
				DisablePocket = true;
				DisableFirefoxAccounts = true;
				DisableAccounts = true;
				DisableFirefoxScreenshots = true;
				OverrideFirstRunPage = "";
				OverridePostUpdatePage = "";
				DontCheckDefaultBrowser = true;
				DisplayBookmarksToolbar = "never"; # alternatives: "always" or "newtab"
				# DisplayMenuBar = "default-off"; # alternatives: "always", "never" or "default-on"
				# SearchBar = "unified"; # alternative: "separate"

				ExtensionSettings = {
					"*".installation_mode = "blocked";
					"uBlock0@raymondhill.net" = {
						install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
						installation_mode = "force_installed";
					};
					"addon@darkreader.org" = {
						install_url = "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi";
						installation_mode = "force_installed";
					};
					"{762f9885-5a13-4abd-9c77-433dcd38b8fd}" = {
						install_url = "https://addons.mozilla.org/ru/firefox/downloads/latest/return-youtube-dislikes/latest.xpi";
						installation_mode = "force_installed";
					};
					"sponsorBlocker@ajay.app" = {
						install_url = "https://addons.mozilla.org/ru/firefox/downloads/latest/sponsorblock/latest.xpi";
						installation_mode = "force_installed";
					};
					"{74145f27-f039-47ce-a470-a662b129930a}" = {
						install_url = "https://addons.mozilla.org/ru/firefox/downloads/latest/clearurls/latest.xpi";
						installation_mode = "force_installed";
					};
				};
			};
		};
		git = {
			enable = true;
			config = {
				user.name = "Ivan Lifanov";
				user.email = "letalbark@gmail.com";
				init.defaultBranch = "main";
				core.quotepath = false;
			};
		};
		ssh.startAgent = true;
		kdeconnect.enable = true;
		steam = {
			enable = getByHost false true;
			remotePlay.openFirewall = true;
			localNetworkGameTransfers.openFirewall = true;
		};
		neovim = {
			enable = true;
			defaultEditor = true;
			configure = {
				customRC = ''
lua <<EOF
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.showmode = false
vim.opt.cursorline = true
vim.opt.scrolloff = 10
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.local/share/nvim/undodir"
vim.opt.undofile = true
vim.opt.breakindent = true
vim.opt.wrap = false
vim.opt.updatetime = 250
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
vim.opt.inccommand = "split"
vim.opt.hlsearch = true
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_netrw = 1
vim.g.loaded_netrwSettings = 1
vim.g.loaded_netrwFileHandlers = 1
vim.g.loaded_netrw_gitignore = 1
vim.o.statusline = [[%<%f %h%m%r %y%=%{v:register} %-14.(%l,%c%V%) %P]]

vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

local kbds = {
	filetree_open_close = "<leader>pt",
	filetree_open_cwd_current_buffer_dir = "<leader>pT",
	filetree_cwd_current_buffer_dir = "<leader>pc",
	telescope_find_files = "<leader>pf",
	telescope_builtins = "<leader>pp",
	telescope_grep = "<leader>pg",
	telescope_diagnostics = "<leader>pd",
	telescope_recent = "<leader>g.",
	telescope_config_dir = "<leader>g$",
	lsp_definitions = "gd",
	lsp_references = "gr",
	lsp_implementations = "gI",
	lsp_type_definitions = "gt",
	lsp_symbols = "gs",
	lsp_workspace_symbols = "<leader>lws",
	lsp_rename = "<leader>lrn",
	lsp_code_action = "<leader>lca",
	lsp_diagnostic = "<leader>ld",
	lsp_restart = "<leader>lr",
	lsp_hover = "K",
	lsp_goto_declaration = "gD",
	lsp_toggle_inlay_hints = "<leader>th",
	formatter_format = "<leader>f",
	cmp_next_item = "<C-j>",
	cmp_prev_item = "<C-k>",
	cmp_confirm = "<C-y>",
	cmp_complete = "<C-Space>",
}

-- other keybindings at the end of the file

require("lazy").setup({
	'NMAC427/guess-indent.nvim',
	{ "numToStr/Comment.nvim", opts = {} },
	{
		"nvim-telescope/telescope.nvim",
		event = "VimEnter",
		branch = "0.1.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
				cond = function()
					return vim.fn.executable("make") == 1
				end,
			},
			{ "nvim-telescope/telescope-ui-select.nvim" },
			{ "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
		},
		config = function()
			require("telescope").setup({
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown(),
					},
				},
			})

			pcall(require("telescope").load_extension, "fzf")
			pcall(require("telescope").load_extension, "ui-select")

			local builtin = require("telescope.builtin")
			vim.keymap.set("n", kbds.telescope_find_files, builtin.find_files, { desc = "[S]earch [F]iles" })
			vim.keymap.set("n", kbds.telescope_builtins, builtin.builtin, { desc = "[S]earch [S]elect Telescope" })
			vim.keymap.set("n", kbds.telescope_grep, builtin.live_grep, { desc = "[S]earch by [G]rep" })
			vim.keymap.set("n", kbds.telescope_diagnostics, builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })
			vim.keymap.set(
				"n",
				kbds.telescope_recent,
				builtin.oldfiles,
				{ desc = '[S]earch Recent Files ("." for repeat)' }
			)
			vim.keymap.set("n", kbds.telescope_config_dir, function()
				builtin.find_files({ cwd = vim.fn.stdpath("config") })
			end, { desc = "[S]earch [N]eovim files" })
		end,
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{ "j-hui/fidget.nvim", opts = {} },
			'saghen/blink.cmp',
		},
		config = function()
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
				callback = function(event)
					local map = function(keys, func, desc)
						vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
					end

					map(kbds.lsp_definitions, require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
					map(kbds.lsp_references, require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
					map(
						kbds.lsp_implementations,
						require("telescope.builtin").lsp_implementations,
						"[G]oto [I]mplementation"
					)
					map(
						kbds.lsp_type_definitions,
						require("telescope.builtin").lsp_type_definitions,
						"Type [D]efinition"
					)
					map(kbds.lsp_symbols, require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
					map(
						kbds.lsp_workspace_symbols,
						require("telescope.builtin").lsp_dynamic_workspace_symbols,
						"[W]orkspace [S]ymbols"
					)
					map(kbds.lsp_rename, vim.lsp.buf.rename, "[R]e[n]ame")
					map(kbds.lsp_code_action, vim.lsp.buf.code_action, "[C]ode [A]ction")
					map(kbds.lsp_diagnostic, vim.diagnostic.open_float, "Open float diagnostic")
					map(kbds.lsp_restart, "<cmd>LspRestart<CR>", "Restart LSP Servers")
					map(kbds.lsp_hover, vim.lsp.buf.hover, "Hover Documentation")
					map(kbds.lsp_goto_declaration, vim.lsp.buf.declaration, "[G]oto [D]eclaration")

					local client = vim.lsp.get_client_by_id(event.data.client_id)
					if client and client.server_capabilities.documentHighlightProvider then
						local highlight_augroup = vim.api.nvim_create_augroup("lsp-highlight", { clear = false })
						vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
							buffer = event.buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.document_highlight,
						})
						vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
							buffer = event.buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.clear_references,
						})
						vim.api.nvim_create_autocmd("LspDetach", {
							group = vim.api.nvim_create_augroup("lsp-detach", { clear = true }),
							callback = function(event2)
								vim.lsp.buf.clear_references()
								vim.api.nvim_clear_autocmds({ group = "lsp-highlight", buffer = event2.buf })
							end,
						})
					end

					if client and client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
						map(kbds.lsp_toggle_inlay_hints, function()
							vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
						end, "[T]oggle Inlay [H]ints")
					end
				end,
			})

			vim.diagnostic.config {
				severity_sort = true,
				float = { border = 'rounded', source = 'if_many' },
				underline = { severity = vim.diagnostic.severity.ERROR },
				signs = vim.g.have_nerd_font and {
					text = {
						[vim.diagnostic.severity.ERROR] = '󰅚 ',
						[vim.diagnostic.severity.WARN] = '󰀪 ',
						[vim.diagnostic.severity.INFO] = '󰋽 ',
						[vim.diagnostic.severity.HINT] = '󰌶 ',
					},
				} or {},
				virtual_text = {
					source = 'if_many',
					spacing = 2,
					format = function(diagnostic)
						local diagnostic_message = {
							[vim.diagnostic.severity.ERROR] = diagnostic.message,
							[vim.diagnostic.severity.WARN] = diagnostic.message,
							[vim.diagnostic.severity.INFO] = diagnostic.message,
							[vim.diagnostic.severity.HINT] = diagnostic.message,
						}
						return diagnostic_message[diagnostic.severity]
					end,
				},
			}

			local capabilities = require('blink.cmp').get_lsp_capabilities()
			local servers = {
			    lua_ls = {},
			    nil_ls = {},
			    ruff = {},
			}
			for server_name, server_config in pairs(servers) do
			    server_config.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server_config.capabilities or {})
			    require('lspconfig')[server_name].setup(server_config)
			end
		end,
	},
	{ -- Autoformat
	    'stevearc/conform.nvim',
	    event = { 'BufWritePre' },
	    cmd = { 'ConformInfo' },
	    keys = {
	      {
		kbds.formatter_format,
		function()
		  require('conform').format { async = true, lsp_format = 'fallback' }
		end,
		mode = "",
		desc = '[F]ormat buffer',
	      },
	    },
	    opts = {
	      notify_on_error = false,
	      formatters_by_ft = {
		-- lua = { 'stylua' },
	      },
	    },
	  },
	{ -- Autocompletion
    'saghen/blink.cmp',
    event = 'VimEnter',
    version = '1.*',
    dependencies = {
      {
        'L3MON4D3/LuaSnip',
        version = '2.*',
        build = (function()
          if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then
            return
          end
          return 'make install_jsregexp'
        end)(),
        dependencies = {
          -- {
          --   'rafamadriz/friendly-snippets',
          --   config = function()
          --     require('luasnip.loaders.from_vscode').lazy_load()
          --   end,
          -- },
        },
        opts = {},
      },
    },
    --- @module 'blink.cmp'
    --- @type blink.cmp.Config
    opts = {
      keymap = {
        preset = 'default',
      },
      appearance = {
        nerd_font_variant = 'mono',
      },
      completion = {
        documentation = { auto_show = false, auto_show_delay_ms = 500 },
      },
      sources = {
        default = { 'lsp', 'path', 'snippets' },
        providers = {},
      },
      snippets = { preset = 'luasnip' },
      fuzzy = { implementation = 'lua' },
      signature = { enabled = true },
    },
  },
  {
		"RRethy/base16-nvim",
		lazy = false,
		priority = 1000,
		config = function()
			vim.cmd.colorscheme("base16-gruvbox-dark-pale")
		end,
	},
	{
		"folke/todo-comments.nvim",
		event = "VimEnter",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = { signs = false },
	},
	{ -- Highlight, edit, and navigate code
	    'nvim-treesitter/nvim-treesitter',
	    build = ':TSUpdate',
	    main = 'nvim-treesitter.configs', -- Sets main module to use for opts
	    opts = {
	      ensure_installed = { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' },
	      auto_install = true,
	      highlight = {
		enable = true,
		additional_vim_regex_highlighting = { 'ruby' },
	      },
	      indent = { enable = true, disable = { 'ruby' } },
	    },
	},
	{
		"nvim-neo-tree/neo-tree.nvim",
		version = "*",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			"MunifTanjim/nui.nvim",
		},
		cmd = "Neotree",
		keys = {
			{ kbds.filetree_open_close, ":Neotree reveal<CR>", { desc = "NeoTree reveal", silent = true } },
		},
		opts = {
			filesystem = {
				window = {
					mappings = {
						[kbds.filetree_open_close] = "close_window",
					},
				},
			},
		},
	},
	{
		"lewis6991/gitsigns.nvim",
		opts = {
			signs = {
				add = { text = "+" },
				change = { text = "~" },
				delete = { text = "_" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
			},
		},
	},
	{
	  'windwp/nvim-autopairs',
	  event = 'InsertEnter',
	  opts = {},
	},
	{
	  {
	    'lukas-reineke/indent-blankline.nvim',
	    main = 'ibl',
	    opts = {},
	  },
	},
}, {
	ui = {
		icons = vim.g.have_nerd_font and {} or {
			cmd = "⌘",
			config = "🛠",
			event = "📅",
			ft = "📂",
			init = "⚙",
			keys = "🗝",
			plugin = "🔌",
			runtime = "💻",
			require = "🌙",
			source = "📄",
			start = "🚀",
			task = "📌",
			lazy = "💤 ",
		},
	},
})

local recording_group = vim.api.nvim_create_augroup("RecordingToggleQ", {})
vim.api.nvim_create_autocmd({"VimEnter", "RecordingLeave"}, {
  group = recording_group,
  callback = function()
    vim.keymap.set("n", "Q", "qa", { noremap = true, silent = true })
  end,
})
vim.api.nvim_create_autocmd("RecordingEnter", {
  group = recording_group,
  callback = function()
    vim.keymap.set("n", "Q", "q", { noremap = true, silent = true })
  end,
})
vim.keymap.set("n", "q", "@a", {})

-- system clipboard stuff
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]], {})
vim.keymap.set("n", "<leader>Y", [["+Y]], {})
vim.keymap.set("n", "<leader>yy", [["+yy]], {})
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]], {})
vim.keymap.set("n", "<leader>p", '"_dp', {})
vim.keymap.set("x", "<leader>p", [["_dP]], {})

-- remove useless binds
vim.keymap.set("", "gu", "<nop>", {})
vim.keymap.set("", "gU", "<nop>", {})
vim.keymap.set("", "<F1>", "<nop>", {})

-- Center on some movements
vim.keymap.set("n", "<C-d>", "<C-d>zz", {})
vim.keymap.set("n", "<C-u>", "<C-u>zz", {})
vim.keymap.set("n", "n", "nzzzv", {})
vim.keymap.set("n", "N", "Nzzzv", {})

vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz", { silent = true })
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz", { silent = true })

vim.keymap.set("n", kbds.filetree_cwd_current_buffer_dir, function()
	vim.cmd("Neotree close")
	vim.cmd("cd %:p:h")
end, {})
vim.keymap.set("n", kbds.filetree_open_cwd_current_buffer_dir, function()
	vim.cmd("Neotree close")
	vim.cmd("cd %:p:h")
	vim.cmd("Neotree reveal")
end, {})
EOF
      '';
			};
		};
		hyprland.enable = getByHost true false;
		bash = {
			interactiveShellInit = ''
if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]; then
	shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
	exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
fi
			'';
		};
		fish = {
			enable = true;
			interactiveShellInit = ''
  set color00 26/26/26 # Base 00 - Black
  set color01 d7/5f/5f # Base 08 - Red
  set color02 af/af/00 # Base 0B - Green
  set color03 ff/af/00 # Base 0A - Yellow
  set color04 83/ad/ad # Base 0D - Blue
  set color05 d4/85/ad # Base 0E - Magenta
  set color06 85/ad/85 # Base 0C - Cyan
  set color07 da/b9/97 # Base 05 - White
  set color08 8a/8a/8a # Base 03 - Bright Black
  set color09 $color01 # Base 08 - Bright Red
  set color10 $color02 # Base 0B - Bright Green
  set color11 $color03 # Base 0A - Bright Yellow
  set color12 $color04 # Base 0D - Bright Blue
  set color13 $color05 # Base 0E - Bright Magenta
  set color14 $color06 # Base 0C - Bright Cyan
  set color15 eb/db/b2 # Base 07 - Bright White
  set color16 ff/87/00 # Base 09
  set color17 d6/5d/0e # Base 0F
  set color18 3a/3a/3a # Base 01
  set color19 4e/4e/4e # Base 02
  set color20 94/94/94 # Base 04
  set color21 d5/c4/a1 # Base 06
  set colorfg $color07 # Base 05 - White
  set colorbg $color00 # Base 00 - Black

  if test -n "$TMUX"
    # Tell tmux to pass the escape sequences through
    # (Source: http://permalink.gmane.org/gmane.comp.terminal-emulators.tmux.user/1324)
    function put_template; printf '\033Ptmux;\033\033]4;%d;rgb:%s\033\033\\\033\\' $argv; end;
    function put_template_var; printf '\033Ptmux;\033\033]%d;rgb:%s\033\033\\\033\\' $argv; end;
    function put_template_custom; printf '\033Ptmux;\033\033]%s%s\033\033\\\033\\' $argv; end;
  else if string match 'screen*' $TERM # [ "''${TERM%%[-.]*}" = "screen" ]
    # GNU screen (screen, screen-256color, screen-256color-bce)
    function put_template; printf '\033P\033]4;%d;rgb:%s\007\033\\' $argv; end;
    function put_template_var; printf '\033P\033]%d;rgb:%s\007\033\\' $argv; end;
    function put_template_custom; printf '\033P\033]%s%s\007\033\\' $argv; end;
  else if string match 'linux*' $TERM # [ "''${TERM%%-*}" = "linux" ]
    function put_template; test $argv[1] -lt 16 && printf "\e]P%x%s" $argv[1] (echo $argv[2] | sed 's/\///g'); end;
    function put_template_var; true; end;
    function put_template_custom; true; end;
  else
    function put_template; printf '\033]4;%d;rgb:%s\033\\' $argv; end;
    function put_template_var; printf '\033]%d;rgb:%s\033\\' $argv; end;
    function put_template_custom; printf '\033]%s%s\033\\' $argv; end;
  end

  # 16 color space
  put_template 0  $color00
  put_template 1  $color01
  put_template 2  $color02
  put_template 3  $color03
  put_template 4  $color04
  put_template 5  $color05
  put_template 6  $color06
  put_template 7  $color07
  put_template 8  $color08
  put_template 9  $color09
  put_template 10 $color10
  put_template 11 $color11
  put_template 12 $color12
  put_template 13 $color13
  put_template 14 $color14
  put_template 15 $color15

  # 256 color space
  put_template 16 $color16
  put_template 17 $color17
  put_template 18 $color18
  put_template 19 $color19
  put_template 20 $color20
  put_template 21 $color21

  # foreground / background / cursor color
  if test -n "$ITERM_SESSION_ID"
    # iTerm2 proprietary escape codes
    put_template_custom Pg dab997 # foreground
    put_template_custom Ph 262626 # background
    put_template_custom Pi dab997 # bold color
    put_template_custom Pj 4e4e4e # selection color
    put_template_custom Pk dab997 # selected text color
    put_template_custom Pl dab997 # cursor
    put_template_custom Pm 262626 # cursor text
  else
    put_template_var 10 $colorfg
    if [ "$BASE16_SHELL_SET_BACKGROUND" != false ]
      put_template_var 11 $colorbg
      if string match 'rxvt*' $TERM # [ "''${TERM%%-*}" = "rxvt" ]
        put_template_var 708 $colorbg # internal border (rxvt)
      end
    end
    put_template_custom 12 ";7" # cursor (reverse video)
  end

  # set syntax highlighting colors
  set -U fish_color_autosuggestion 4e4e4e
  set -U fish_color_cancel -r
  set -U fish_color_command green #white
  set -U fish_color_comment 4e4e4e
  set -U fish_color_cwd green
  set -U fish_color_cwd_root red
  set -U fish_color_end brblack #blue
  set -U fish_color_error red
  set -U fish_color_escape yellow #green
  set -U fish_color_history_current --bold
  set -U fish_color_host normal
  set -U fish_color_match --background=brblue
  set -U fish_color_normal normal
  set -U fish_color_operator blue #green
  set -U fish_color_param 949494
  set -U fish_color_quote yellow #brblack
  set -U fish_color_redirection cyan
  set -U fish_color_search_match bryellow --background=4e4e4e
  set -U fish_color_selection white --bold --background=4e4e4e
  set -U fish_color_status red
  set -U fish_color_user brgreen
  set -U fish_color_valid_path --underline
  set -U fish_pager_color_completion normal
  set -U fish_pager_color_description yellow --dim
  set -U fish_pager_color_prefix white --bold #--underline
  set -U fish_pager_color_progress brwhite --background=cyan

  # remember current theme
  set -U base16_theme gruvbox-dark-pale

  # clean up
  functions -e put_template put_template_var put_template_custom


# fish_config theme choose Catppuccin\ Mocha
set fzf_fd_opts --hidden --no-ignore --max-depth 5
set fzf_preview_dir_cmd eza --time-style relative -lA

function fish_greeting
    printf "\e[31m●\e[0m \e[33m●\e[0m \e[32m●\e[0m \e[36m●\e[0m \e[34m●\e[0m \e[35m●\e[0m \n"
end

function fish_prompt
    set -l nix_shell_info (
      if test -n "$IN_NIX_SHELL"
        echo -n "<nix-shell> "
      end
    )
    set -l last_pipestatus $pipestatus
    set -lx __fish_last_status $status # Export for __fish_print_pipestatus.
    set -l normal (set_color normal)
    set -q fish_color_status
    or set -g fish_color_status red

    # Color the prompt differently when we're root
    set -l color_cwd $fish_color_cwd
    set -l suffix '>'
    if functions -q fish_is_root_user; and fish_is_root_user
        if set -q fish_color_cwd_root
            set color_cwd $fish_color_cwd_root
        end
        set suffix '#'
    end

    # Write pipestatus
    # If the status was carried over (if no command is issued or if `set` leaves the status untouched), don't bold it.
    set -l bold_flag --bold
    set -q __fish_prompt_status_generation; or set -g __fish_prompt_status_generation $status_generation
    if test $__fish_prompt_status_generation = $status_generation
        set bold_flag
    end
    set __fish_prompt_status_generation $status_generation
    set -l status_color (set_color $fish_color_status)
    set -l statusb_color (set_color $bold_flag $fish_color_status)
    set -l prompt_status (__fish_print_pipestatus "[" "]" "|" "$status_color" "$statusb_color" $last_pipestatus)

    echo -n -s "$nix_shell_info" (set_color $color_cwd) (prompt_pwd -D 3) $normal (fish_vcs_prompt) $normal " "$prompt_status $suffix " "
end

function nix-index
	sudo nix-channel --add https://nixos.org/channels/nixos-unstable nixos
	sudo nix-channel --update
end

function nix-clean
	nix-collect-garbage --delete-old
	sudo nix-collect-garbage -d
	sudo /run/current-system/bin/switch-to-configuration boot
end

function nix-edit
	nvim "$(whereis $argv | cut -d " " -f 2)"
end
alias eza "eza -M --icons=always --no-permissions --group-directories-first --git --color=always"
abbr --position anywhere ns "nix-shell --run fish -p";
abbr --position anywhere rm "rm -vrf";
abbr --position anywhere cp "cp -vr";
abbr --position anywhere mv "mv -vf";
abbr --position anywhere t "tldr";
abbr --position anywhere tree "tree -C";
abbr --position anywhere ls "eza --time-style relative -lA";
abbr --position anywhere lst "eza --time-style relative -lA -T";
abbr --position anywhere lss "eza --time-style relative -lA --total-size";
abbr --position anywhere lsst "eza --time-style relative -lA -T --total-size";
abbr --position anywhere lsts "eza --time-style relative -lA -T --total-size";
abbr --position anywhere pgenx "pgen | xclip -sel clip";
abbr --position anywhere pgenw "pgen | wl-copy";
			'';
		};
	};
	environment.variables = let
			xdg-cache-home = "$HOME/.cache";
			xdg-config-home = "$HOME/.config";
			xdg-data-home = "$HOME/.local/share";
			xdg-state-home = "$HOME/.local/state";
	in {
		XDG_CACHE_HOME  = xdg-cache-home;
		XDG_CONFIG_HOME = xdg-config-home;
		XDG_DATA_HOME   = xdg-data-home;
		XDG_STATE_HOME  = xdg-state-home;
		PATH = [
			"$HOME/.local/bin"
		];
		HISTFILE = "${xdg-state-home}/bash/history";
		CUDA_CACHE_PATH = "${xdg-cache-home}/nv";
		CARGO_HOME = "${xdg-data-home}/cargo";
		GOPATH = "${xdg-data-home}/go";
		NPM_CONFIG_INIT_MODULE = "${xdg-config-home}/npm/config/npm-init.js";
		NPM_CONFIG_CACHE = "${xdg-cache-home}/npm";
		NPM_CONFIG_TMP = "$XDG_RUNTIME_DIR/npm";
		# XAUTHORITY = "$XDG_RUNTIME_DIR/Xauthority";
		MANPAGER="nvim +Man!";
	} // getByHost {
	} {
		VIRT_BASE_DOMAIN = "win-passthrough";
		VIRT_USB_DEVICES = "$HOME/virt/usb.json";
		LIBVIRT_DEFAULT_URI = "qemu:///system";
	};

	environment.systemPackages = with pkgs; [
		kitty
		eza
		obsidian
		libreoffice-qt6-still
		pavucontrol
		brave
		qbittorrent
		mpv
		tealdeer
		unzip
		nil
		ruff
		lua-language-server
		lazygit
		btop
		wl-clipboard
		gcc
		kdePackages.dolphin
		libnetfilter_queue
		adwaita-icon-theme
		python3Minimal
		flatpak-update
		dualsound
		killsteamgame
		nixupd
	] ++ getByHost [
		sbctl
		moonlight-qt
	] [
		mangohud
		protonup-qt
		godot
		rpcs3
	] ++ getByHost (
		[]
		++ gitsshsetup
	) (
		[]
		++ gitsshsetup
		++ chlayout
		++ cpuperf
		++ game-performance
		++ virt
	);
	fonts.packages = with pkgs; [
		noto-fonts
		noto-fonts-emoji
		nerd-fonts.jetbrains-mono
	];

	systemd.services.libvirtd = {
		preStart = ''
rm -rf /var/lib/libvirt/hooks
mkdir -p /var/lib/libvirt/hooks
mkdir -p /var/lib/libvirt/hooks/qemu.d/win-passthrough/prepare/begin
mkdir -p /var/lib/libvirt/hooks/qemu.d/win-passthrough/release/end

echo '#!/run/current-system/sw/bin/bash

GUEST_NAME="$1"
HOOK_NAME="$2"
STATE_NAME="$3"

BASEDIR="$(dirname $0)"

if [ "$(echo "$GUEST_NAME" | grep "tmp-")" ]; then
	GUEST_NAME="$(echo "$GUEST_NAME" | sed "s|tmp-||")"
fi
HOOKPATH="$BASEDIR/qemu.d/$GUEST_NAME/$HOOK_NAME/$STATE_NAME"
set -e # If a script exits with an error, we should as well.

if [ -f "$HOOKPATH" ]; then
	eval \""$HOOKPATH"\" "$@"
elif [ -d "$HOOKPATH" ]; then
	while read file; do
		eval \""$file"\" "$@"
	done <<< "$(find -L "$HOOKPATH" -maxdepth 1 -type f -executable -print;)"
fi
' > /var/lib/libvirt/hooks/qemu
echo '#!/run/current-system/sw/bin/bash
set -x

echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind
modprobe -r nvidia_drm nvidia_modeset nvidia_uvm nvidia snd_hda_intel

systemctl set-property --runtime -- system.slice AllowedCPUs=5
systemctl set-property --runtime -- user.slice AllowedCPUs=5
systemctl set-property --runtime -- init.scope AllowedCPUs=5
echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference
' > /var/lib/libvirt/hooks/qemu.d/win-passthrough/prepare/begin/start.sh
echo '#!/run/current-system/sw/bin/bash
set -x

systemctl set-property --runtime -- system.slice AllowedCPUs=0-5
systemctl set-property --runtime -- user.slice AllowedCPUs=0-5
systemctl set-property --runtime -- init.scope AllowedCPUs=0-5
echo powersave | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
echo balance_performance | tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference

echo "efi-framebuffer.0" > /sys/bus/platform/drivers/efi-framebuffer/bind
modprobe nvidia_drm
modprobe nvidia_modeset
modprobe nvidia_uvm
modprobe nvidia
modprobe snd_hda_intel
' > /var/lib/libvirt/hooks/qemu.d/win-passthrough/release/end/stop.sh

chmod +x /var/lib/libvirt/hooks/qemu
chmod +x /var/lib/libvirt/hooks/qemu.d/win-passthrough/prepare/begin/start.sh
chmod +x /var/lib/libvirt/hooks/qemu.d/win-passthrough/release/end/stop.sh
		'';
	};
	virtualisation.libvirtd = {
		enable = getByHost false true;
		qemu = {
			package = pkgs.qemu_kvm;
			ovmf = {
				enable = true;
				packages = [ pkgs.OVMFFull.fd ];
			};
		};
		onBoot = "ignore";
		onShutdown = "shutdown";
	};
	programs.virt-manager.enable = getByHost false true;
	services.spice-vdagentd.enable = getByHost false true;

	systemd.services.nethandler = {
		enable = true;
		description = "Nethandler";
		wantedBy = [ "default.target" ];
		serviceConfig = {
			ExecStart = pkgs.writeShellScript "nethandler" (builtins.readFile ./nethandler);
		};
	};

	services.udev.extraRules = getByHost ''
SUBSYSTEM=="backlight", ACTION=="add", \
	RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/backlight/%k/brightness", \
	RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"
	'' ''
SUBSYSTEM=="cpu", ACTION=="add", \
	RUN+="${pkgs.coreutils}/bin/chgrp video /sys/devices/system/cpu/%k/cpufreq/scaling_governor", \
	RUN+="${pkgs.coreutils}/bin/chgrp video /sys/devices/system/cpu/%k/cpufreq/energy_performance_preference", \
	RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/devices/system/cpu/%k/cpufreq/scaling_governor", \
	RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/devices/system/cpu/%k/cpufreq/energy_performance_preference"

# Disable DS4 touchpad acting as mouse
# USB
ATTRS{name}=="Sony Interactive Entertainment Wireless Controller Touchpad", ENV{LIBINPUT_IGNORE_DEVICE}="1"
# Bluetooth
ATTRS{name}=="Wireless Controller Touchpad", ENV{LIBINPUT_IGNORE_DEVICE}="1"

# USB
ATTRS{name}=="Sony Interactive Entertainment DualSense Wireless Controller Touchpad", ENV{LIBINPUT_IGNORE_DEVICE}="1"
# Bluetooth
ATTRS{name}=="DualSense Wireless Controller Touchpad", ENV{LIBINPUT_IGNORE_DEVICE}="1"
	'';

	security.polkit.extraConfig = ''
  polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.systemd1.manage-units" &&
        (action.lookup("unit") == "nethandler.service") &&
        subject.user == "ivan") {
      return polkit.Result.YES;
    }
  });
  polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.systemd1.manage-units" &&
        (action.lookup("unit") == "scx.service") &&
        subject.user == "ivan") {
      return polkit.Result.YES;
    }
  });
'';
	security.sudo.enable = false;
	security.sudo-rs.enable = true;
	services.scx = {
		enable = getByHost false true;
		scheduler = "scx_lavd";
		extraArgs = [ "--performance" ];

	};
	systemd.services.scx.wantedBy = lib.mkForce [];

	system.stateVersion = "24.11"; # Did you read the comment?
}

