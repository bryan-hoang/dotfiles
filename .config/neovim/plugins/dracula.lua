return {
	after = "ui",
	config = function()
		local dracula = require("dracula")
		dracula.setup({
			transparent_bg = true,
			italic_comment = true,
			overrides = {
				DiffText = { bg = "#880000" },
			},
		})

		vim.cmd([[colorscheme dracula]])
	end,
}
