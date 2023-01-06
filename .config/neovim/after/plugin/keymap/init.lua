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

-- Automatically jump to the last place visited in a file before exiting.
--
-- https://this-week-in-neovim.org/2023/Jan/02#tips
vim.api.nvim_create_autocmd("BufReadPost", {
	callback = function()
		local mark = vim.api.nvim_buf_get_mark(0, '"')
		local lcount = vim.api.nvim_buf_line_count(0)
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})
