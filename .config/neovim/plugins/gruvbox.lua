return {
	config = function()
		require("gruvbox").setup({
			transparent_mode = true,
			inverse = false,
		})
		vim.o.background = "dark"
		vim.cmd.colorscheme("gruvbox")
	end,
}
