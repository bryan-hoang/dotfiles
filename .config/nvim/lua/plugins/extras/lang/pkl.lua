return {
	{
		"apple/pkl-neovim",
		ft = "pkl",
		dependencies = {
			{
				"nvim-treesitter/nvim-treesitter",
				{
					"mason-org/mason.nvim",
					opts = {
						ensure_installed = {
							"pkl-lsp",
						},
					},
				},
			},
		},
		build = function()
			require("pkl-neovim").init()

			-- Set up syntax highlighting.
			vim.cmd("TSInstall pkl")
		end,
		init = function()
			vim.g.pkl_neovim = {
				start_command = { "pkl-lsp" },
			}
		end,
	},
}
