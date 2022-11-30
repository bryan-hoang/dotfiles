return {
	tag = "*",
	after = {
		-- Need colorscheme's colors set up before applying highlights for conflicts.
		"gruvbox.nvim",
	},
	config = function()
		require("git-conflict").setup()
	end,
}
