return {
	{
		-- Go to filenames with line info.
		"lewis6991/fileline.nvim",
		lazy = false,
	},
	{
		-- Work with several variants of a word at once. For example, search and
		-- replacing variants.
		"tpope/vim-abolish",
		event = require("util").buf_enter_event_list,
	},
	{
		-- Defaults everyone can agree on.
		"tpope/vim-sensible",
		event = require("util").buf_enter_event_list,
	},
}
