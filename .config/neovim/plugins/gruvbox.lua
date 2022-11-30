return {
	after = { "ui" },
	config = function()
		require("gruvbox").setup({
			transparent_mode = true,
			inverse = false,
			italic = false,
		})
		vim.o.background = "dark"
		vim.cmd.colorscheme("gruvbox")
	end,
}
