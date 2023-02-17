return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = {
			-- Automatically install missing parsers when entering buffer
			-- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
			auto_install = true,
		},
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
		dependencies = {
			{
				"nvim-treesitter/playground",
			},
		},
	},
	{
		"nvim-treesitter/playground",
		cmd = "TSPlaygroundToggle",
		dependencies = {
			{
				"nvim-treesitter/playground",
			},
		},
	},
}
