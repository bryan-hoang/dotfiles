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
			vim.treesitter.language.register("markdown", "markdown.mdx")
			vim.treesitter.language.register("bash", "dotenv")
		end,
	},
	{
		"nvim-treesitter/playground",
		cmd = "TSPlaygroundToggle",
	},
}
