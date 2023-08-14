return {
	{
		-- Make Vim handle line and column numbers in file names with a minimum of
		-- fuss.
		"wsdjeg/vim-fetch",
		lazy = false,
	},
	{
		"eandrju/cellular-automaton.nvim",
		cmd = "CellularAutomaton",
		keys = {
			{
				"<leader>fml",
				"<Cmd>CellularAutomaton make_it_rain<CR>",
				desc = "Make it rain",
			},
		},
	},
	{
		"folke/persistence.nvim",
		enabled = false,
	},
}
