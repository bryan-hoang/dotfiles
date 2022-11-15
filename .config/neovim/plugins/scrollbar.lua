return {
	after = "gitsigns.nvim",
	config = function()
		require("scrollbar").setup()
		require("scrollbar.handlers.gitsigns").setup()
	end,
}
