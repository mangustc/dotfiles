-- PLUGINS
vim.pack.add({
	-- deps
	"https://github.com/nvim-tree/nvim-web-devicons",

	-- plugins
	{ src = "https://github.com/vague2k/vague.nvim", version = "087ff41d1b4d90e7b64e1c97860700fa6b7f0daf" },
	"https://github.com/nvim-tree/nvim-tree.lua",
	"https://github.com/ibhagwan/fzf-lua",
	"https://github.com/folke/todo-comments.nvim",
	"https://github.com/lewis6991/gitsigns.nvim",
	"https://github.com/windwp/nvim-autopairs",
	"https://github.com/lukas-reineke/indent-blankline.nvim",
	"https://github.com/folke/which-key.nvim",
	{
		src = "https://github.com/nvim-treesitter/nvim-treesitter",
		branch = "main",
		build = ":TSUpdate",
	},
	"https://www.github.com/neovim/nvim-lspconfig",
	"https://github.com/mason-org/mason.nvim",
	{
		src = "https://github.com/saghen/blink.cmp",
		version = vim.version.range("1.*"),
	},
	"https://github.com/L3MON4D3/LuaSnip",
})

-- PRETTY MUCH DEFAULTS

vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = true
vim.opt.termguicolors = true
vim.cmd("colorscheme vague")

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.wrap = false
vim.opt.scrolloff = 10
vim.opt.sidescrolloff = 10

-- vim.opt.tabstop = 2 -- tabwidth
-- vim.opt.shiftwidth = 2 -- indent width
-- vim.opt.softtabstop = 2 -- soft tab stop not tabs on tab/backspace
-- vim.opt.expandtab = true -- use spaces instead of tabs
vim.opt.smartindent = true -- smart auto-indent
vim.opt.autoindent = true -- copy indent from current line

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true

vim.opt.signcolumn = "yes"
vim.opt.showmatch = true
vim.opt.cmdheight = 1
vim.opt.completeopt = "menuone,noinsert,noselect"
vim.opt.showmode = false -- do not show the mode, instead have it in statusline
vim.opt.pumheight = 10 -- popup menu height
vim.opt.pumblend = 10 -- popup menu transparency
vim.opt.winblend = 0 -- floating window transparency
vim.opt.conceallevel = 0 -- do not hide markup
vim.opt.concealcursor = "" -- do not hide cursorline in markup
vim.opt.lazyredraw = true -- do not redraw during macros
vim.opt.synmaxcol = 300 -- syntax highlighting limit

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.undofile = true
vim.opt.undodir = os.getenv("HOME") .. "/.local/share/nvim/undodir"
vim.opt.updatetime = 300
vim.opt.timeoutlen = 500
vim.opt.ttimeoutlen = 50
vim.opt.autoread = true
vim.opt.autowrite = false

vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})

-- change macros: "Q" to start or end writing macro to register a, "q" to use macro from register a
local recording_group = vim.api.nvim_create_augroup("RecordingToggleQ", {})
vim.api.nvim_create_autocmd({ "VimEnter", "RecordingLeave" }, {
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

-- Center on some movements
vim.keymap.set("n", "<C-d>", "<C-d>zz", {})
vim.keymap.set("n", "<C-u>", "<C-u>zz", {})
vim.keymap.set("n", "n", "nzzzv", {})
vim.keymap.set("n", "N", "Nzzzv", {})

-- Clear search on escape
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- system clipboard stuff
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]], { desc = "Copy (System clipboard)" })
vim.keymap.set("n", "<leader>Y", [["+Y]], { desc = "Copy line (System clipboard)" })
vim.keymap.set("n", "<leader>yy", [["+yy]], { desc = "Copy line (System clipboard)" })
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete (System clipboard)" })

-- buffers
vim.keymap.set("n", "<C-j>", ":bn<CR>")
vim.keymap.set("n", "<C-k>", ":bp<CR>")
vim.keymap.set("n", "<C-x>", ":bd<CR>")

-- statusline
local function file_size()
	local size = vim.fn.getfsize(vim.fn.expand("%"))
	if size < 0 then
		return ""
	end
	local size_str
	if size < 1024 then
		size_str = size .. "B"
	elseif size < 1024 * 1024 then
		size_str = string.format("%.1fK", size / 1024)
	else
		size_str = string.format("%.1fM", size / 1024 / 1024)
	end
	return "size " .. size_str .. " "
end
_G.file_size = file_size
vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter", "WinLeave", "BufLeave" }, {
	callback = function()
		vim.opt_local.statusline = table.concat({
			" ",
			"%{v:lua.vim.fn.mode()}",
			" | %f %h%m%r%y",
			" | %{v:lua.file_size()}",
			"%=",
			" | %l:%c  %P ",
		})
	end,
})

-- PLUGIN CONFIGS

require("gen").setup({})

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
require("nvim-tree").setup({
	view = {
		width = 9999,
	},
	filters = {
		dotfiles = true,
	},
	actions = {
		open_file = {
			quit_on_open = true,
		},
	},
})
vim.keymap.set("n", "<leader>pt", require("nvim-tree.api").tree.open, { desc = "File Browser" })
vim.keymap.set("n", "<leader>pc", function()
	local buf = vim.api.nvim_get_current_buf()
	local file = vim.api.nvim_buf_get_name(buf)
	if file == "" then
		require("nvim-tree.api").tree.open()
	else
		local dir = vim.fn.fnamemodify(file, ":p:h")
		require("nvim-tree.api").tree.open({
			path = dir,
		})
	end
end, { desc = "File Browser (buffer)" })

require("fzf-lua").setup({})
vim.keymap.set("n", "<leader>f", function()
	require("fzf-lua").files()
end, { desc = "FZF Files" })
vim.keymap.set("n", "<leader>g", function()
	require("fzf-lua").live_grep()
end, { desc = "FZF Live Grep" })

require("gitsigns").setup({
	signs = {
		add = { text = "+" },
		change = { text = "~" },
		delete = { text = "_" },
		topdelete = { text = "‾" },
		changedelete = { text = "~" },
	},
})

require("todo-comments").setup({})

require("nvim-autopairs").setup({})

require("ibl").setup({})

require("which-key").setup({})
vim.keymap.set("n", "<leader>?", function() require("which-key").show({ global = false }) end,
	{ desc = "Buffer Local Keymaps (which-key)" })

do
	local treesitter = require("nvim-treesitter")
	treesitter.setup({
		install_dir = vim.fn.stdpath('data') .. '/site'
	})
	local ensure_installed = {
		"vim",
		"vimdoc",
		"rust",
		"c",
		"cpp",
		"go",
		"html",
		"css",
		"javascript",
		"json",
		"lua",
		"markdown",
		"python",
		"typescript",
		"vue",
		"svelte",
		"bash",
	}
	local config = require("nvim-treesitter.config")
	local already_installed = config.get_installed()
	local parsers_to_install = {}
	for _, parser in ipairs(ensure_installed) do
		if not vim.tbl_contains(already_installed, parser) then
			table.insert(parsers_to_install, parser)
		end
	end
	if #parsers_to_install > 0 then
		treesitter.install(parsers_to_install)
	end
	local group = vim.api.nvim_create_augroup("TreeSitterConfig", { clear = true })
	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		callback = function(args)
			if vim.list_contains(treesitter.get_installed(), vim.treesitter.language.get_lang(args.match)) then
				vim.treesitter.start(args.buf)
			end
		end,
	})
end

require("mason").setup({})
local function lsp_on_attach(ev)
	local client = vim.lsp.get_client_by_id(ev.data.client_id)
	if not client then
		return
	end
	local bufnr = ev.buf
	local function opts(desc)
		return { noremap = true, silent = true, buffer = bufnr, desc = desc }
	end

	-- goto
	vim.keymap.set("n", "gnd", function()
		vim.diagnostic.jump({ count = 1 })
	end, opts("Goto next diagnostic"))
	vim.keymap.set("n", "gpd", function()
		vim.diagnostic.jump({ count = -1 })
	end, opts("Goto previous diagnostic"))
	vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts("Goto definition"))

	-- menus
	vim.keymap.set("n", "<leader>lca", vim.lsp.buf.code_action, opts("code actions"))
	vim.keymap.set("n", "<leader>lrn", vim.lsp.buf.rename, opts("Rename"))
	vim.keymap.set("n", "<leader>lD", function()
		vim.diagnostic.open_float({ scope = "line" })
	end, opts("Open diagnostic (Line)"))
	vim.keymap.set("n", "<leader>ld", function()
		vim.diagnostic.open_float({ scope = "cursor" })
	end, opts("Open diagnostic (Cursor)"))
	vim.keymap.set("n", "K", vim.lsp.buf.hover, opts("Info"))

	vim.keymap.set("n", "<leader>lfd", function()
		require("fzf-lua").lsp_definitions()
	end, opts("List definitions"))
	vim.keymap.set("n", "<leader>lfr", function()
		require("fzf-lua").lsp_references()
	end, opts("List refernces"))
	vim.keymap.set("n", "<leader>lft", function()
		require("fzf-lua").lsp_typedefs()
	end, opts("List type definitions"))
	vim.keymap.set("n", "<leader>lfs", function()
		require("fzf-lua").lsp_document_symbols()
	end, opts("List document symbols"))
	vim.keymap.set("n", "<leader>lfw", function()
		require("fzf-lua").lsp_workspace_symbols()
	end, opts("List workspace symbols"))
	vim.keymap.set("n", "<leader>lfi", function()
		require("fzf-lua").lsp_implementations()
	end, opts("List implementations"))
	if client:supports_method("textDocument/codeAction", bufnr) then
		vim.keymap.set("n", "<leader>loi", function()
			vim.lsp.buf.code_action({
				context = { only = { "source.organizeImports" }, diagnostics = {} },
				apply = true,
				bufnr = bufnr,
			})
			vim.defer_fn(function()
				vim.lsp.buf.format({ bufnr = bufnr })
			end, 50)
		end, opts("Organize Imports"))
	end
end
vim.api.nvim_create_autocmd("LspAttach", { group = augroup, callback = lsp_on_attach })

vim.cmd("set completeopt+=noselect")
require("blink.cmp").setup({
	-- keymap = {
	-- 	preset = "none",
	-- 	["<C-Space>"] = { "show", "hide" },
	-- 	["<C-y>"] = { "accept", "fallback" },
	-- 	["<C-j>"] = { "select_next", "fallback" },
	-- 	["<C-k>"] = { "select_prev", "fallback" },
	-- 	["<Tab>"] = { "snippet_forward", "fallback" },
	-- 	["<S-Tab>"] = { "snippet_backward", "fallback" },
	-- },
	appearance = { nerd_font_variant = "mono" },
	completion = {
		ghost_text = { enabled = true },
		menu = { auto_show = true }
	},
	sources = { default = { "lsp", "path", "buffer", "snippets" } },
	snippets = {
		expand = function(snippet)
			require("luasnip").lsp_expand(snippet)
		end,
	},
	fuzzy = {
		implementation = "prefer_rust",
		prebuilt_binaries = { download = true },
	},
})
vim.lsp.config["*"] = {
	capabilities = require("blink.cmp").get_lsp_capabilities(),
}

vim.lsp.config("lua_ls", {
	settings = {
		Lua = {
			diagnostics = { globals = { "vim" } },
			telemetry = { enable = false },
		},
	},
})
vim.lsp.config("pyright", {})
vim.lsp.config("bashls", {})
vim.lsp.config("ts_ls", {})
vim.lsp.config("gopls", {})
vim.lsp.config("clangd", {})

vim.lsp.enable({
	"lua_ls",
	"pyright",
	"bashls",
	"ts_ls",
	"gopls",
	"clangd",
})
