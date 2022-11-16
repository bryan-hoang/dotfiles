return {
	tag = "*",
	config = function()
		require("git-conflict").setup({
			-- highlights = {
			-- 	incoming = "DiffText",
			-- 	current = "DiffAdd",
			-- },
		})
	end,
}
