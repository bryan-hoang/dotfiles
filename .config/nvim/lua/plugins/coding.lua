return {
	{
		"echasnovski/mini.comment",
		config = function()
			local mini_comment = require("mini.comment")

			-- https://github.com/wez/wezterm/issues/3180#issuecomment-1517896371
			mini_comment.setup({
				mappings = {
					-- Toggle comment (like `gcip` - comment inner paragraph) for both
					-- Normal and Visual modes
					comment = "<C-/>",
					-- Toggle comment on current line
					comment_line = "<C-/>",
					-- Define 'comment' textobject (like `dgc` - delete whole comment block)
					textobject = "<C-/>",
				},
			})

			mini_comment.setup({
				mappings = {
					comment = "<C-_>",
					comment_line = "<C-_>",
					textobject = "<C-_>",
				},
			})
		end,
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
		event = require("util").buf_enter_event_list,
	},
	{
		"echasnovski/mini.comment",
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
}
