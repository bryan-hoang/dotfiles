return {
	tag = "*",
	config = function()
		require("git-conflict").setup({
			default_mappings = false,
			highlights = {
				incoming = "DiffText",
				current = "DiffAdd",
			},
		})
	end,
}
