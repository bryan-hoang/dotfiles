return {
	{
		"NoahTheDuke/vim-just",
		ft = "just",
	},
	{
		"Hoffs/omnisharp-extended-lsp.nvim",
	},
	{
		"Civitasv/cmake-tools.nvim",
		-- Don't load by default on BufRead.
		event = function()
			return {}
		end,
		ft = "cmake",
	},
	{
		"simrat39/rust-tools.nvim",
		ft = "rust",
	},
	{
		"lervag/vimtex",
		lazy = true,
		ft = "tex",
	},
}
