return {
	-- Override NvChad/ui's colours.
	after = "ui",
	as = "catppuccin",
	config = function()
		require("catppuccin").setup({
			transparent_background = true,
		})
		-- vim.cmd.colorscheme("catppuccin")
	end,
}
