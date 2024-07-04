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
	{
		"hrsh7th/nvim-cmp",
		opts = function(_, opts)
			opts.completion.autocomplete = false
		end,
	},
	{
		"petertriho/cmp-git",
		dependencies = { "hrsh7th/nvim-cmp" },
		ft = { "gitcommit", "octo", "markdown" },
		config = function(_, _)
			local cmp = require("cmp")
			local cmp_git = require("cmp_git")

			cmp.setup.filetype({ "gitcommit", "octo", "markdown" }, {
				sources = cmp.config.sources({
					{ name = "git" },
					{ name = "path" },
				}, {
					{ name = "buffer" },
				}),
			})

			cmp_git.setup()
		end,
	},
}
