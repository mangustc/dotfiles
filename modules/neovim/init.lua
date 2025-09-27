-- PRETTY MUCH DEFAULTS
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
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
vim.opt.inccommand = "split"
vim.opt.hlsearch = true
vim.opt.statusline = [[%<%f %h%m%r %y%=%{v:register} %-14.(%l,%c%V%) %P]]
vim.opt.winborder = "rounded"
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
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])
vim.keymap.set("n", "<leader>yy", [["+yy]])
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])
vim.keymap.set("n", "<leader>p", '"_dp')
vim.keymap.set("x", "<leader>p", [["_dP]])





-- MAIN CONFIG

vim.pack.add({
	{ src = "https://github.com/nvim-lua/plenary.nvim", },
	{ src = "https://github.com/neovim/nvim-lspconfig", },
	{ src = "https://github.com/vague2k/vague.nvim", },
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter", },
	{ src = "https://github.com/folke/todo-comments.nvim", },
	{ src = "https://github.com/lewis6991/gitsigns.nvim", },
	{ src = "https://github.com/windwp/nvim-autopairs", },
	{ src = "https://github.com/lukas-reineke/indent-blankline.nvim", },
	{ src = "https://github.com/ThePrimeagen/harpoon", version = "harpoon2", },
	{ src = "https://github.com/nvim-telescope/telescope-fzf-native.nvim", },
	{ src = "https://github.com/nvim-telescope/telescope.nvim", },
	{ src = "https://github.com/Saghen/blink.cmp", version = "v1.6.0" },
	{ src = "https://github.com/nmac427/guess-indent.nvim", },
})

vim.cmd("colorscheme vague")

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

require('guess-indent').setup({})

require("ibl").setup({})

require("nvim-treesitter.configs").setup({
	auto_install = true,
	highlight = {
		enable = true,
		additional_vim_regex_highlighting = { 'ruby' },
	},
	indent = { enable = true, disable = { 'ruby' } },

})

vim.diagnostic.config {
	severity_sort = true,
	float = { border = 'rounded', source = 'if_many' },
	underline = { severity = vim.diagnostic.severity.ERROR },
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
vim.api.nvim_create_autocmd('LspAttach', {
	group = vim.api.nvim_create_augroup('my.lsp', {}),
	callback = function(args)
		local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
		if client:supports_method('textDocument/implementation') then
			-- Create a keymap for vim.lsp.buf.implementation ...
		end
		if client:supports_method('textDocument/completion') then
			-- vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
		end
	end,
})
vim.cmd("set completeopt+=noselect")
vim.keymap.set("n", "<leader>lf", vim.lsp.buf.format)
vim.lsp.enable({
	"lua_ls",
	"bashls",
	"hls",
})
require("blink.cmp").setup({
	signature = { enabled = true },
	completion = {
		documentation = { auto_show = true, auto_show_delay_ms = 500 },
		ghost_text = { enabled = true },
		menu = {
			auto_show = true,
			draw = {
				treesitter = { "lsp" },
				columns = {
					{ "kind_icon", "label", "label_description", gap = 1 },
					{ "kind" },
				},
			},
		},
	},
})

local harpoon = require("harpoon")
harpoon:setup()
vim.keymap.set("n", "<C-j>", ":bn<CR>")
vim.keymap.set("n", "<C-k>", ":bp<CR>")
vim.keymap.set("n", "<C-a>", function() harpoon:list():add() end)
vim.keymap.set("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)
vim.keymap.set("n", "<C-h>", function() harpoon:list():select(1) end)
vim.keymap.set("n", "<C-t>", function() harpoon:list():select(2) end)
vim.keymap.set("n", "<C-n>", function() harpoon:list():select(3) end)
vim.keymap.set("n", "<C-s>", function() harpoon:list():select(4) end)

require("telescope").setup({})
-- TODO: wait until proper build phase in neovim native plugin manager appears
local fzflib_file = io.open(string.format("%s/%s/build/libfzf.so", os.getenv("HOME"), ".local/share/nvim/site/pack/core/opt/telescope-fzf-native.nvim"), "r")
if fzflib_file then
	fzflib_file:close()
else
	os.execute(string.format("cd %s/%s && make", os.getenv("HOME"), ".local/share/nvim/site/pack/core/opt/telescope-fzf-native.nvim"))
end
require('telescope').load_extension('fzf')
local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>f", builtin.find_files, { desc = "[S]earch [F]iles" })
vim.keymap.set("n", "<leader>g", builtin.live_grep, { desc = "[S]earch by [G]rep" })
vim.keymap.set("n", "<leader>td", builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })
vim.keymap.set("n", "<leader>pf", builtin.oldfiles, { desc = '[S]earch Recent Files' })
vim.keymap.set("n", "gtd", vim.diagnostic.open_float)

vim.keymap.set("n", "<leader>pt", ":Ex .<CR>")
vim.keymap.set("n", "<leader>pc", ":Ex<CR>")

-- native lsp default keybinds:
-- "grn" is mapped in Normal mode to vim.lsp.buf.rename()
-- "gra" is mapped in Normal and Visual mode to vim.lsp.buf.code_action()
-- "grr" is mapped in Normal mode to vim.lsp.buf.references()
-- "gri" is mapped in Normal mode to vim.lsp.buf.implementation()
-- "grt" is mapped in Normal mode to vim.lsp.buf.type_definition()
-- "gO" is mapped in Normal mode to vim.lsp.buf.document_symbol()
-- CTRL-S is mapped in Insert mode to vim.lsp.buf.signature_help()
-- "an" and "in" are mapped in Visual mode to outer and inner incremental selections, respectively, using vim.lsp.buf.selection_range()
