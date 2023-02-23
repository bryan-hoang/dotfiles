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
				"nvim-treesitter/nvim-treesitter",
			},
		},
		event = require("util").get_buf_enter_event_list(),
	},
	{
		"nvim-treesitter/playground",
		cmd = "TSPlaygroundToggle",
		dependencies = {
			{
				"nvim-treesitter/nvim-treesitter",
			},
		},
	},
}
