-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

local function augroup(name)
	return vim.api.nvim_create_augroup("lazyvim_" .. name, { clear = true })
end

-- Automatically jump to the last place I’ve visited in a file before exiting.
-- https://github.com/phaazon/this-week-in-neovim-contents/blob/master/contents/2023/Jan/02/5-did-you-know.md
--
-- go to last loc when opening a buffer
vim.api.nvim_create_autocmd("BufReadPost", {
	group = augroup("last_loc"),
	callback = function()
		local exclude = { "gitcommit", "gitrebase" }
		local buf = vim.api.nvim_get_current_buf()
		if vim.tbl_contains(exclude, vim.bo[buf].filetype) then
			return
		end
		local mark = vim.api.nvim_buf_get_mark(buf, '"')
		local lcount = vim.api.nvim_buf_line_count(buf)
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
			vim.cmd("norm! zz")
		end
	end,
})

-- Work around annoying shada error message on Windows.
--
-- https://github.com/neovim/neovim/issues/8587
if vim.fn.has("win32") then
	vim.api.nvim_create_autocmd({ "VimLeavePre" }, {
		group = vim.api.nvim_create_augroup("curse_shada_temp", { clear = true }),
		pattern = { "*" },
		callback = function()
			local status = 0
			for _, f in
				ipairs(
					vim.fn.globpath(
						vim.fs.joinpath(vim.fn.stdpath("state"), "shada"),
						"*tmp*",
						false,
						true
					)
				)
			do
				if vim.tbl_isempty(vim.fn.readfile(f)) then
					status = status + vim.fn.delete(f)
				end
			end
			if status ~= 0 then
				vim.notify(
					"Could not delete empty temporary ShaDa files.",
					vim.log.levels.ERROR
				)
				vim.fn.getchar()
			end
		end,
		desc = "Delete empty temp ShaDa files",
	})
end
