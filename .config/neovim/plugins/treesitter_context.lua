return {
	after = { "nvim-treesitter" },
	config = function()
		require("treesitter-context").setup()
	end,
}
