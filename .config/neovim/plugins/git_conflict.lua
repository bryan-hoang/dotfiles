return {
	tag = "*",
	-- Need colorscheme's colors set up before applying highlights for conflicts.
	after = { "catppuccin" },
	keys = { "]x" },
	config = function()
		require("git-conflict").setup()
	end,
}
