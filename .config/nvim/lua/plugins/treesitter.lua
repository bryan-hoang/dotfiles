return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = function(_, _opts)
			vim.treesitter.language.register("markdown", { "markdown.mdx" })
			vim.treesitter.language.register("bash", { "dotenv" })
		end,
	},
}
