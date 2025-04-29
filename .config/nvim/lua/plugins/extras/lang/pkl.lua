return {
	"apple/pkl-neovim",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		{
			"williamboman/mason.nvim",
			opts = {
				ensure_installed = {
					"pkl-lsp",
				},
			},
		},
	},
	build = function()
		require("pkl-neovim").init()
	end,
	ft = "pkl",
	init = function()
		-- Configure pkl-lsp
		vim.g.pkl_neovim = {
			start_command = { "pkl-lsp" },
		}
	end,
}
