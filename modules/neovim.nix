{ config, lib, pkgs, ... }:

let
	cfg = config.modules.neovim;
in {
	options.modules.neovim = {
		enable = lib.mkEnableOption "Enable neovim configuration";
	};

	config = lib.mkIf cfg.enable {
		programs.neovim = {
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
			    pyright = {},
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
		environment.variables = {
			MANPAGER="nvim +Man!";
		};
		environment.systemPackages = with pkgs; [
			nil
			pyright
			lua-language-server
		];
	};
}

