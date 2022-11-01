return {
	run = function()
		vim.fn["nvim_ghost#installer#install"]()
	end,
	config = function()
		vim.g.nvim_ghost_super_quiet = 1
	end,
}
