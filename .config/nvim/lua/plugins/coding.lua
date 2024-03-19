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
		"petertriho/cmp-git",
		dependencies = { "hrsh7th/nvim-cmp" },
		ft = { "gitcommit", "octo", "markdown" },
		config = function(_, opts)
			local cmp = require("cmp")
			local cmp_git = require("cmp_git")

			cmp.setup(opts)
			cmp.setup.filetype({ "gitcommit", "octo", "markdown" }, {
				sources = {
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
					{ name = "buffer" },
					{ name = "path" },
					{ name = "git" },
				},
			})
			cmp_git.setup()
		end,
	},
	{
		"hrsh7th/nvim-cmp",
		opts = {
			completion = {
				autocomplete = false,
			},
		},
	},
}
