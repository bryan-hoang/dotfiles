return {
	tag = "*",
	config = function()
		require("git-conflict").setup()
	end,
	-- Need colorscheme's colors set up before applying highlights for conflicts.
	after = { "catppuccin" },
}
