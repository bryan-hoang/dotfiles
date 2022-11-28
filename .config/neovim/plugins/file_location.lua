return {
	event = { "BufNewFile", "BufRead" },
	config = function()
		require("nvim-file-location").setup()
	end,
}
