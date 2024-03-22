return {
	{
		-- Goto filenames with line info.
		"lewis6991/fileline.nvim",
		lazy = false,
	},
	{
		"eandrju/cellular-automaton.nvim",
		cmd = "CellularAutomaton",
		keys = {
			{
				"<leader>ua",
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
