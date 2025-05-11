{
  ...
}: {
  home.username = "ivan";
  home.homeDirectory = "/home/ivan";
  home.stateVersion = "24.11";
  programs.home-manager.enable = true;

	home.file.".bash_profile" = {
		force = true;
		text = ''
[[ -f ~/.bashrc ]] && . ~/.bashrc
		'';
	};
	home.file.".bashrc" = {
		force = true;
		text = ''
export SSH_AUTH_SOCK="/tmp/ssh-agent.sock"
export HISTFILE="''${XDG_STATE_HOME}/bash/history"
export CUDA_CACHE_PATH="''${XDG_CACHE_HOME}/nv"
export CARGO_HOME="''${XDG_DATA_HOME}/cargo"
export GOPATH="''${XDG_DATA_HOME}/go"
export NPM_CONFIG_INIT_MODULE="''${XDG_CONFIG_HOME}/npm/config/npm-init.js"
export NPM_CONFIG_CACHE="''${XDG_CACHE_HOME}/npm"
export NPM_CONFIG_TMP="''${XDG_RUNTIME_DIR}/npm"
export XAUTHORITY="''${XDG_RUNTIME_DIR}/Xauthority"

export VIRT_BASE_DOMAIN="win-passthrough"
export VIRT_USB_DEVICES="''${HOME}/virt/usb.json"
export WM_NAME="kde"
export WM_ARGS="wayland"
export LIBVIRT_DEFAULT_URI="qemu:///system"

if [[ $- == *i* ]]; then
	exec fish
fi
		'';
	};
  xdg.configFile."nvim/init.lua" = {
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

-- vim.opt.clipboard = "unnamedplus"
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
	"tpope/vim-sleuth", -- Detect tabstop and shiftwidth automatically
	-- {
	-- 	"nmac427/guess-indent.nvim",
	-- 	opts = {},
	-- },
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
			-- vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

			-- NOTE: Shortcut for searching your Neovim configuration files
			vim.keymap.set("n", kbds.telescope_config_dir, function()
				builtin.find_files({ cwd = vim.fn.stdpath("config") })
			end, { desc = "[S]earch [N]eovim files" })
		end,
	},
	{
		-- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
		-- used for completion, annotations and signatures of Neovim apis
		"folke/lazydev.nvim",
		ft = "lua",
		opts = {
			library = {
				-- Load luvit types when the `vim.uv` word is found
				{ path = "''${3rd}/luv/library", words = { "vim%.uv" } },
			},
		},
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{ "williamboman/mason.nvim", config = true }, -- NOTE: Must be loaded before dependants
			"williamboman/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			{ "j-hui/fidget.nvim", opts = {} },
			"hrsh7th/cmp-nvim-lsp",
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
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

			local servers = {
			    lua_ls = {
				cmd = {'lua-language-server'},  -- Use system-installed binary
				filetypes = {'lua'},
				settings = {
				    Lua = {
					completion = {
					    callSnippet = "Replace",
					},
				    },
				},
			    },
			    nil_ls = {
				cmd = {'nil'},  -- Use system-installed binary
				filetypes = {'nix'},
				root_markers = {'flake.nix', '.git'},
			    },
			}

			-- Remove all Mason-related setup
			-- require("mason").setup()
			-- require("mason-lspconfig").setup()

			-- Directly setup LSP servers using system binaries
			for server_name, server_config in pairs(servers) do
			    server_config.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server_config.capabilities or {})
			    require('lspconfig')[server_name].setup(server_config)
			end
		end,
	},
	{
		"stevearc/conform.nvim",
		lazy = false,
		keys = {
			{
				kbds.formatter_format,
				function()
					require("conform").format({ async = true, lsp_fallback = true })
				end,
				mode = "",
				desc = "[F]ormat buffer",
			},
		},
		opts = {
			notify_on_error = false,
			-- format_on_save = function(bufnr)
			-- 	if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
			-- 		return
			-- 	end
			-- 	local disable_filetypes = { c = false, cpp = false }
			-- 	return {
			-- 		timeout_ms = 500,
			-- 		lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
			-- 	}
			-- end,
			formatters_by_ft = {
				lua = { "stylua" },
				-- jsx = { "prettier" },
				typescript = { "prettierd", "prettier", stop_after_first = true },
				typescriptreact = { "prettierd", "prettier", stop_after_first = true },
				javascript = { "prettierd", "prettier", stop_after_first = true },
				javascriptreact = { "prettierd", "prettier", stop_after_first = true },
				json = { "prettierd", "prettier", stop_after_first = true },
				html = { "prettierd", "prettier", stop_after_first = true },
				css = { "prettierd", "prettier", stop_after_first = true },
			},
		},
		config = function(_, opts)
			require("conform").setup(opts)
		end,
	},

	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			{
				"L3MON4D3/LuaSnip",
				build = (function()
					if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
						return
					end
					return "make install_jsregexp"
				end)(),
				dependencies = {
					{
						"rafamadriz/friendly-snippets",
						config = function()
							require("luasnip.loaders.from_vscode").lazy_load()
						end,
					},
				},
			},
			"saadparwaiz1/cmp_luasnip",
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-path",
		},
		config = function()
			-- See `:help cmp`
			local cmp = require("cmp")
			local luasnip = require("luasnip")
			luasnip.config.setup({})

			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				completion = { completeopt = "menu,menuone,noinsert" },
				mapping = cmp.mapping.preset.insert({
					-- ['<C-n>'] = cmp.mapping.select_next_item(),
					-- ['<C-p>'] = cmp.mapping.select_prev_item(),
					[kbds.cmp_next_item] = cmp.mapping.select_next_item(),
					[kbds.cmp_prev_item] = cmp.mapping.select_prev_item(),

					[kbds.cmp_confirm] = cmp.mapping.confirm({ select = true }),
					[kbds.cmp_complete] = cmp.mapping.complete({}),

					-- ['<C-l>'] = cmp.mapping(function()
					--   if luasnip.expand_or_locally_jumpable() then
					--     luasnip.expand_or_jump()
					--   end
					-- end, { 'i', 's' }),
					-- ['<C-h>'] = cmp.mapping(function()
					--   if luasnip.locally_jumpable(-1) then
					--     luasnip.jump(-1)
					--   end
					-- end, { 'i', 's' }),
				}),
				sources = {
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
					{ name = "path" },
				},
				experimental = {
					ghost_text = true,
				},
			})
		end,
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
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		main = "nvim-treesitter.configs", -- Sets main module to use for opts
		-- [[ Configure Treesitter ]] See `:help nvim-treesitter`
		opts = {
			ensure_installed = {
				"bash",
				"c",
				"diff",
				"html",
				"lua",
				"luadoc",
				"markdown",
				"markdown_inline",
				"query",
				"vim",
				"vimdoc",
			},
			auto_install = true,
			highlight = {
				enable = true,
				additional_vim_regex_highlighting = { "ruby" },
			},
			indent = { enable = true, disable = { "ruby" } },
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
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		opts = {
			-- indent = { char = '»' },
		},
	},
	{
		"echasnovski/mini.nvim",
		config = function()
			-- require("mini.ai").setup({ n_lines = 500 })
			-- require("mini.surround").setup()

			local statusline = require("mini.statusline")
			statusline.setup({ use_icons = vim.g.have_nerd_font })
			---@diagnostic disable-next-line: duplicate-set-field
			statusline.section_location = function()
				return "%2l:%-2v"
			end
		end,
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
vim.keymap.set("n", "Q", "<nop>", {})

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
  xdg.configFile."kitty/kitty.conf" = {
  	text = ''
font_size        13
font_family      JetBrainsMono Nerd Font
bold_font        auto
italic_font      auto
bold_italic_font auto

# window_padding_width 10
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
  xdg.configFile."git/config" = {
	text = ''
[user]
	name = Ivan Lifanov
	email = letalbark@gmail.com
[core]
	quotepath = false
	'';
	force = true;
  };
  xdg.configFile."fish/config.fish" = {
  	text = ''
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

    echo -n -s (set_color $color_cwd) (prompt_pwd -D 3) $normal (fish_vcs_prompt) $normal " "$prompt_status $suffix " "
end



alias eza "eza -M --icons=always --no-permissions --group-directories-first --git --color=always"
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
	  force = true;
  };
}
