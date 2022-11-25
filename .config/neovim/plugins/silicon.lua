return {
	run = "./install.sh",
	config = function()
		require("silicon").setup({
			tab_width = 2,
			font = "FiraCode Nerd Font Mono",
			line_number = true,
			background = "#BD93F9",
		})
	end,
}