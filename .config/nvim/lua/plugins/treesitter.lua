return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = {
			ensure_installed = {},
			-- Automatically install missing parsers when entering buffer
			-- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
			auto_install = true,
		},
		config = function(_, opts)
			-- https://github.com/nvim-treesitter/nvim-treesitter/wiki/Windows-support#how-will-the-parser-be-downloaded
			require("nvim-treesitter.install").prefer_git = vim.fn.has("win32") ~= 1
			require("nvim-treesitter.configs").setup(opts)
			vim.treesitter.language.register("markdown", "mdx")
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
		event = require("util").buf_enter_event_list,
		opts = {},
		keys = {
			{
				"[c",
				function()
					require("treesitter-context").go_to_context()
				end,
				desc = "Jump to treesitter context",
			},
		},
	},
	{
		"nvim-treesitter/playground",
		cmd = "TSPlaygroundToggle",
	},
	{
		"windwp/nvim-ts-autotag",
		-- https://github.com/windwp/nvim-ts-autotag#default-values
		ft = {
			"html",
			"javascript",
			"typescript",
			"javascriptreact",
			"typescriptreact",
			"svelte",
			"vue",
			"tsx",
			"jsx",
			"rescript",
			"xml",
			"php",
			"markdown",
			"glimmer",
			"handlebars",
			"hbs",
		},
		opts = {},
	},
}
