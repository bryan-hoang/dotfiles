return {
	["glacambre/firenvim"] = {
		run = function()
			vim.fn["firenvim#install"](0)
		end,
	},
	-- Creates missing folders on save.
	["jghauser/mkdir.nvim"] = {},
	["tpope/vim-sleuth"] = {},
	["github/copilot.vim"] = {},
	["neoclide/coc.nvim"] = {
		branch = 'release',
	},
	["hjson/vim-hjson"] = {},
}
