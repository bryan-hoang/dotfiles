return {
	requires = {
		{ "nvim-lua/plenary.nvim" },
	},
	cmd = { "Diffview*" },
	config = function()
		local diffview = require("diffview")
		diffview.setup({})
	end,
}
