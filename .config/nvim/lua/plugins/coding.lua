return {
	{
		"echasnovski/mini.pairs",
		event = function()
			return { "InsertEnter" }
		end,
	},
	{
		"echasnovski/mini.ai",
		event = require("util").buf_enter_event_list,
	},
}
