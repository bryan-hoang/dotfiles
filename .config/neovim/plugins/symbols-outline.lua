return {
	after = "nvim-lspconfig",
	config = function()
		require("symbols-outline").setup({
			show_relative_numbers = true,
		})
	end,
}
