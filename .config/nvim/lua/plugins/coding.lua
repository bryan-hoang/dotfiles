return {
	{
		"echasnovski/mini.comment",
		opts = {
			mappings = {
				-- Toggle comment (like `gcip` - comment inner paragraph) for both
				-- Normal and Visual modes
				comment = "<C-c>",
				-- Toggle comment on current line
				comment_line = "<C-c>",
				-- Define 'comment' textobject (like `dgc` - delete whole comment block)
				textobject = "<C-c>",
			},
		},
	},
	{
		"echasnovski/mini.pairs",
		event = function()
			return {
				"InsertEnter",
			}
		end,
	},
	{
		"echasnovski/mini.ai",
		event = require("util").get_buf_enter_event_list,
	},
	{
		"echasnovski/mini.comment",
		event = require("util").get_buf_enter_event_list,
	},
}
