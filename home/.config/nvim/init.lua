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
	formatter_toggle_autoformat_buffer = "<leader>lf",
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
				{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
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
				bashls = {},
			}
			require("mason").setup()

			local ensure_installed = vim.tbl_keys(servers or {})
			vim.list_extend(ensure_installed, {
				"shfmt",
			})
			require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

			require("mason-lspconfig").setup({
				handlers = {
					function(server_name)
						local server = servers[server_name] or {}
						server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
						require("lspconfig")[server_name].setup(server)
					end,
				},
			})
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
			{
				kbds.formatter_toggle_autoformat_buffer,
				function()
					if vim.b.disable_autoformat then
						vim.cmd("FormatEnable")
						vim.notify("Enabled autoformat for current buffer")
					else
						vim.cmd("FormatDisable!")
						vim.notify("Disabled autoformat for current buffer")
					end
				end,
				desc = "Toggle autoformat for current buffer",
			},
		},
		opts = {
			notify_on_error = false,
			format_on_save = function(bufnr)
				if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
					return
				end
				local disable_filetypes = { c = false, cpp = false }
				return {
					timeout_ms = 500,
					lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
				}
			end,
			formatters_by_ft = {
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

			vim.api.nvim_create_user_command("FormatDisable", function(args)
				if args.bang then
					-- :FormatDisable! disables autoformat for this buffer only
					vim.b.disable_autoformat = true
				else
					-- :FormatDisable disables autoformat globally
					vim.g.disable_autoformat = true
				end
			end, {
				desc = "Disable autoformat-on-save",
				bang = true, -- allows the ! variant
			})

			vim.api.nvim_create_user_command("FormatEnable", function()
				vim.b.disable_autoformat = false
				vim.g.disable_autoformat = false
			end, {
				desc = "Re-enable autoformat-on-save",
			})
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
