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
