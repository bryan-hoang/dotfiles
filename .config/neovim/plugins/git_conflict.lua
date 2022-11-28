return {
	tag = "*",
	-- Need colorscheme's colors set up before applying highlights for conflicts.
	after = { "catppuccin", "gitsigns.nvim" },
	config = function()
		require("git-conflict").setup()
	end,
}
