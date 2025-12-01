return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = function(_, opts)
			-- https://github.com/nvim-treesitter/nvim-treesitter/wiki/Windows-support#how-will-the-parser-be-downloaded
			vim.treesitter.language.register("markdown", "markdown.mdx")
			vim.treesitter.language.register("bash", "dotenv")
		end,
	},
}
