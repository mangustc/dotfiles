{
  pkgs,
  host,
  ...
}: let
	getByHost = first: second:
		if host.name == "main" then first
		else if host.name == "gaming" then second
		else throw "Unsupported host: ${host.name}";
in {
	home.username = "ivan";
	home.homeDirectory = "/home/ivan";
	home.stateVersion = "24.11";
	programs.home-manager.enable = true;

	home.file = {
		".bash_profile" = {
			force = true;
			text = ''
[[ -f ~/.bashrc ]] && . ~/.bashrc
			'';
		};
		".bashrc" = {
			force = true;
			text = '''';
		};
	};
	xdg.configFile = {
		"nvim/init.lua" = {
			force = true;
			text = ''
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
			'';
		};
		"kitty/kitty.conf" = {
			text = ''
font_size        13
font_family      JetBrainsMono Nerd Font
bold_font        auto
italic_font      auto
bold_italic_font auto
confirm_os_window_close 2
enable_audio_bell no
shell_integration disabled
cursor_blink_interval 0

background #262626
foreground #dab997
selection_background #dab997
selection_foreground #262626
url_color #949494
cursor #dab997
active_border_color #8a8a8a
inactive_border_color #3a3a3a
active_tab_background #262626
active_tab_foreground #dab997
inactive_tab_background #3a3a3a
inactive_tab_foreground #949494
tab_bar_background #3a3a3a
color0 #262626
color1 #d75f5f
color2 #afaf00
color3 #ffaf00
color4 #83adad
color5 #d485ad
color6 #85ad85
color7 #dab997
color8 #8a8a8a
color9 #ff8700
color10 #3a3a3a
color11 #4e4e4e
color12 #949494
color13 #d5c4a1
color14 #d65d0e
color15 #ebdbb2
			'';
			force = true;
		};
	} // getByHost {
		"hypr/hyprland.conf" = {
			text = ''
monitor=HDMI-A-1,1920x1080,0x0,1
monitor=eDP-1,2240x1400,0x0,1.458333
exec-once = echo 180 > /sys/class/backlight/amdgpu_bl1/brightness
windowrulev2 = suppressevent maximize, class:.*
windowrulev2 = nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0
workspace = w[tv1], gapsout:0, gapsin:0
workspace = f[1], gapsout:0, gapsin:0
windowrulev2 = bordersize 0, floating:0, onworkspace:w[tv1]
windowrulev2 = rounding 0, floating:0, onworkspace:w[tv1]
windowrulev2 = bordersize 0, floating:0, onworkspace:f[1]
windowrulev2 = rounding 0, floating:0, onworkspace:f[1]
# windowrule = workspace 2 silent, ^(zen-browser)$
# windowrule = float, ^(pavucontrol)$
env = XCURSOR_SIZE,24
env = XCURSOR_THEME,Adwaita
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland
env = XDG_SESSION_DESKTOP,Hyprland
env = QT_QPA_PLATFORM,wayland;xcb
env = GDK_BACKEND,wayland,x11
env = SDL_VIDEODRIVER,wayland
env = CLUTTER_BACKEND,wayland
env = MOZ_ENABLE_WAYLAND,1
env = HYPRCURSOR_THEME,Adwaita
env = HYPRCURSOR_SIZE,24
$base00 = 0xff262626
$base01 = 0xff3a3a3a
$base02 = 0xff4e4e4e
$base03 = 0xff8a8a8a
$base04 = 0xff949494
$base05 = 0xffdab997
$base06 = 0xffd5c4a1
$base07 = 0xffebdbb2
$base08 = 0xffd75f5f
$base09 = 0xffff8700
$base0A = 0xffffaf00
$base0B = 0xffafaf00
$base0C = 0xff85ad85
$base0D = 0xff83adad
$base0E = 0xffd485ad
$base0F = 0xffd65d0e
general {
    gaps_in = 2
    gaps_out = 0
    border_size = 1
    col.active_border = $base05
    col.inactive_border = $base02
    resize_on_border = false
    allow_tearing = true
    layout = dwindle
}
decoration {
    rounding = 0
    active_opacity = 1.0
    inactive_opacity = 1.0
    shadow {
        enabled = false
    }
    blur {
        enabled = false
    }
}
cursor {
    hide_on_key_press = true
    no_warps = true
    inactive_timeout = 5
    enable_hyprcursor = false
    # no_hardware_cursors = false
}
input {
    kb_layout = us,ru
    kb_variant = dvorak,
    kb_model =
    kb_options = grp:caps_toggle
    kb_rules =
    follow_mouse = 1
    sensitivity = 0 # -1.0 - 1.0, 0 means no modification.
    repeat_rate = 50
    repeat_delay = 300
    touchpad {
        natural_scroll = false
        scroll_factor = 0.15
    }
}
device {
    name = compx-2.4g-wireless-receiver
    sensitivity = -0.8
    accel_profile = flat
}
animations {
    enabled = no
}
dwindle {
    pseudotile = true
    preserve_split = true
}
master {
    new_status = master
}
misc {
    force_default_wallpaper = 0
    disable_hyprland_logo = true
    background_color = $base00
}
gestures {
    workspace_swipe = false
}
ecosystem {
    no_update_news = true
    # no_donation_nag = true
}
xwayland {
    force_zero_scaling = true
}
experimental {
    xx_color_management_v4 = true
}
bind = SUPER SHIFT, D, exec, hyprctl keyword monitor eDP-1,disabled
bind = CTRL ALT, Backspace, exit,
bind = SUPER SHIFT, S, exec, ${pkgs.slurp}/bin/slurp -d | ${pkgs.grim}/bin/grim -g - - | convert - -shave 1x1 PNG:- | ${pkgs.wl-clipboard}/bin/wl-copy
bind = , Print, exec, ${pkgs.slurp}/bin/slurp -d | ${pkgs.grim}/bin/grim -g - - | convert - -shave 1x1 PNG:- | ${pkgs.wl-clipboard}/bin/wl-copy
binde = SUPER, Down, exec, new_volume=$(($(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2 * 100}' | cut -d. -f1) + -1)); [ ''${new_volume} -le 150 ] && wpctl set-volume @DEFAULT_AUDIO_SINK@ ''${new_volume}% || exit 1
binde = SUPER SHIFT, Down, exec, new_volume=$(($(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2 * 100}' | cut -d. -f1) + -5)); [ ''${new_volume} -le 150 ] && wpctl set-volume @DEFAULT_AUDIO_SINK@ ''${new_volume}% || exit 1
binde = SUPER SHIFT, Up, exec, new_volume=$(($(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2 * 100}' | cut -d. -f1) + +5)); [ ''${new_volume} -le 150 ] && wpctl set-volume @DEFAULT_AUDIO_SINK@ ''${new_volume}% || exit 1
binde = SUPER, Up, exec, new_volume=$(($(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2 * 100}' | cut -d. -f1) + +1)); [ ''${new_volume} -le 150 ] && wpctl set-volume @DEFAULT_AUDIO_SINK@ ''${new_volume}% || exit 1binde = SUPER SHIFT, Tab, movefocus, l
binde = SUPER, Tab, movefocus, r
bind = SUPER, T, exec, KITTY_ENABLE_WAYLAND=1 kitty
bind = SUPER, C, killactive,
bind = SUPER, W, exec, sh -c "[ \"$(pidof waybar)\" = \"\" ] && exec ${pkgs.waybar}/bin/waybar --config ~/.config/hypr/config --style ~/.config/hypr/style.css || pkill -f waybar"
bind = SUPER, V, togglefloating,
bind = SUPER, F, fullscreen,
bind = SUPER, P, exec, BEMENU_BACKEND=wayland ${pkgs.bemenu}/bin/bemenu-run -H 20 -i
binde = SUPER SHIFT, Y, exec, echo $(($(cat /sys/class/backlight/amdgpu_bl1/brightness)-15)) > /sys/class/backlight/amdgpu_bl1/brightness
binde = SUPER, Y, exec, echo $(($(cat /sys/class/backlight/amdgpu_bl1/brightness)+15)) > /sys/class/backlight/amdgpu_bl1/brightness
bind = SUPER, Left, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle
bind = SUPER, Right, exec, sh -c "[ \"$(pactl list cards | grep 'HiFi' | awk -F': ' '/Active Profile/ { print $2 }')\" = 'HiFi (Mic1, Mic2, Speaker)' ] && pactl set-card-profile 49 'HiFi (Headphones, Mic1, Mic2)' || pactl set-card-profile 49 'HiFi (Mic1, Mic2, Speaker)'"
bind = SUPER, 1, workspace, 1
bind = SUPER, 2, workspace, 2
bind = SUPER, 3, workspace, 3
bind = SUPER, 4, workspace, 4
bind = SUPER, 5, workspace, 5
bind = SUPER, 6, workspace, 6
bind = SUPER, 7, workspace, 7
bind = SUPER, 8, workspace, 8
bind = SUPER, 9, workspace, 9
bind = SUPER, 0, workspace, 10
bind = SUPER SHIFT, 1, movetoworkspace, 1
bind = SUPER SHIFT, 2, movetoworkspace, 2
bind = SUPER SHIFT, 3, movetoworkspace, 3
bind = SUPER SHIFT, 4, movetoworkspace, 4
bind = SUPER SHIFT, 5, movetoworkspace, 5
bind = SUPER SHIFT, 6, movetoworkspace, 6
bind = SUPER SHIFT, 7, movetoworkspace, 7
bind = SUPER SHIFT, 8, movetoworkspace, 8
bind = SUPER SHIFT, 9, movetoworkspace, 9
bind = SUPER SHIFT, 0, movetoworkspace, 10
bind = SUPER, mouse_down, workspace, e+1
bind = SUPER, mouse_up, workspace, e-1
bindm = SUPER, mouse:272, movewindow
bindm = SUPER, mouse:273, resizewindow
			'';
			force = true;
		};
		"hypr/style.css" = {
			text = ''
@define-color base00 #262626;
@define-color base01 #3a3a3a;
@define-color base02 #4e4e4e;
@define-color base03 #8a8a8a;
@define-color base04 #949494;
@define-color base05 #dab997;
@define-color base06 #d5c4a1;
@define-color base07 #ebdbb2;
@define-color base08 #d75f5f;
@define-color base09 #ff8700;
@define-color base0A #ffaf00;
@define-color base0B #afaf00;
@define-color base0C #85ad85;
@define-color base0D #83adad;
@define-color base0E #d485ad;
@define-color base0F #d65d0e;

* {
  font-family: "JetBrainsMono Nerd Font";
  font-size: 10pt;
  font-weight: bold;
  border-radius: 0px;
  transition-property: background-color;
  transition-duration: 0s;
  min-height: 0;
}
@keyframes blink_red {
  to {
    background-color: rgb(242, 143, 173);
    color: rgb(26, 24, 38);
  }
}
.warning,
.critical,
.urgent {
  animation-name: blink_red;
  animation-duration: 1s;
  animation-timing-function: linear;
  animation-iteration-count: infinite;
  animation-direction: alternate;
}
window > box {
  margin-left: 0px;
  margin-right: 0px;
  margin-top: 0px;
  background-color: @base00;
}
#workspaces {
  padding-left: 0px;
  padding-right: 4px;
}
#workspaces button {
  padding-top: 0px;
  padding-bottom: 0px;
  padding-left: 6px;
  padding-right: 6px;
  color: @base05;
}
#workspaces button.active {
  background-color: @base05;
  color: @base00;
}
#workspaces button.urgent {
  color: @base08;
}
#workspaces button:hover {
  background-color: @base01;
  color: @base00;
}
#mode,
#clock,
#temperature,
#cpu,
#custom-wall,
#temperature,
#backlight,
#wireplumber,
#network,
#battery,
#custom-powermenu {
  padding-left: 10px;
  padding-right: 10px;
}
#clock {
  color: @base06;
}
#temperature {
  color: @base0D;
}
#backlight {
  color: @base0A;
}
#wireplumber {
  color: @base0C;
}
#battery {
  color: @base0E;
}
			'';
			force = true;
		};
		"hypr/config" = {
			text = ''
{
      "layer": "top",
      "position": "top",
      "height": 20,
      "modules-left": ["custom/launcher", "hyprland/workspaces", "temperature", "custom/wall"],
      "modules-center": [
        "clock"
      ],
      "modules-right": [
        "wireplumber",
        "backlight",
        "battery",
        "tray"
      ],
      "hyprland/workspaces": {
        "format": "{name}",
        "on-click": "activate"
      },
      "idle_inhibitor": {
        "format": "{icon}",
        "format-icons": {
          "activated": "",
          "deactivated": "",
        },
        "tooltip": false
      },
      "backlight": {
        "device": "amdgpu_bl0",
        "format": "L {percent}%",
      },
      "wireplumber": {
        "scroll-step": 1,
        "format": "VOL {volume}%",
        "format-muted": "VOL {volume}% M",
        "tooltip": false
      },
      "battery": {
        "interval": 60,
        "states": {
          "warning": 20,
          "critical": 10
        },
        "format": "BAT {capacity}%",
        "tooltip": false
      },
      "clock": {
        "interval": 60,
        "format": "{:%I:%M %p  %A %b %d}",
        "tooltip": false,
      },
      "temperature": {
        "tooltip": false,
        "format": "TEMP {temperatureC}°C"
      },
}
			'';
			force = true;
		};
	} {
		"pipewire" = {
			source = ./pipewire;
			recursive = true;
			force = true;
		};
	};
}
