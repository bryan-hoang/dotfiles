-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Add newlines above and below the cursor in normal mode. Source:
-- `tummetott/unimpaired.nvim`.
vim.keymap.set("n", "]<Space>", function()
	vim.cmd("put =repeat(nr2char(10), v:count1)|silent '[-")
end, {
	desc = "Add newline below",
})
vim.keymap.set("n", "[<Space>", function()
	vim.cmd("put! =repeat(nr2char(10), v:count1)|silent ']+")
end, {
	desc = "Add newline above",
})

-- https://theprimeagen.github.io/vim-fundamentals/files-remaps-2
vim.keymap.set("n", "<Leader>fe", vim.cmd.Ex, {
	desc = "Open File Explorer (Netrw)",
})

-- ThePrimeagen "Vim As Your Editor - Vertical Movements"
-- https://youtu.be/KfENDDEpCsI?t=321
-- Centers the cursor after some vertical motions.
vim.keymap.set("n", "<C-d>", "<C-d>zz", { noremap = false })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { noremap = false })
vim.keymap.set("n", "n", "nzzzv", { noremap = false })
vim.keymap.set("n", "N", "Nzzzv", { noremap = false })
-- Maintain default behaviour specified by `:help <C-L>`.
vim.keymap.set(
	"n",
	"<C-L>",
	"<Cmd>nohlsearch<Bar>diffupdate<Bar>normal!<C-L><CR>",
	{ noremap = false }
)

if vim.g.vscode then
	return
end

local wk = require("which-key")

wk.add({
	{ "<Leader>g", group = "Git/debuG" },
	{ "<Leader>gc", group = "Conflict" },
})

-- Remove default open terminal mapping.
-- https://www.lazyvim.org/keymaps#general
vim.keymap.del({ "n" }, "<C-/>")
vim.keymap.del({ "n" }, "<C-_>")

local mini_comment = require("mini.comment")
-- https://github.com/wez/wezterm/issues/3180#issuecomment-1517896371
mini_comment.setup({
	mappings = {
		-- Toggle comment (like `gcip` - comment inner paragraph) for both
		-- Normal and Visual modes
		comment = "<C-/>",
		-- Toggle comment on current line
		comment_line = "<C-/>",
		-- Toggle comment on visual selection
		comment_visual = "<C-/>",
		-- Define 'comment' textobject (like `dgc` - delete whole comment block)
		textobject = "<C-/>",
	},
})
mini_comment.setup({
	mappings = {
		comment = "<C-_>",
		comment_line = "<C-_>",
		comment_visual = "<C-_>",
		textobject = "<C-_>",
	},
})

-- Disable jumping to keyword definition to avoid conflicting with opening
-- hyperlinks in Wezterm.
vim.api.nvim_set_keymap("", "<C-LeftMouse>", "", {})
-- Disable with 'bypass_mouse_reporting_modifiers' key from Wezterm, not sure
-- why the undocumente behaviour occurs.
vim.api.nvim_set_keymap("", "<C-S-LeftMouse>", "", {})

-- Keybinds inspired by ThePrimeagen.
-- https://youtu.be/w7i4amO_zaE?t=1464
vim.keymap.set({ "n", "v" }, "<Leader>y", '"+y', {
	desc = "Yank selections to clipboard",
})
vim.keymap.set("n", "<Leader>Y", '"+Y', {
	desc = "Yank to end of line to clipboard",
})
-- See `:help v_P`.
-- vim.keymap.set("x", "<Leader>p", '"_dP', {
-- 	desc = "Paste and preserve clipboard",
-- })
