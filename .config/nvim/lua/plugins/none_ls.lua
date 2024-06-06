return {
	{
		"nvimtools/none-ls.nvim",
		enabled = true,
		keys = {
			{
				"<Leader>co",
				"<Cmd>NullLsInfo<CR>",
				desc = "null-ls Info",
			},
		},
		opts = function(_, opts)
			local nls = require("null-ls")

			local b = nls.builtins

			local user_opts = {
				debug = os.getenv("DEBUG") == "nvim:null-ls",
				sources = {
					-- Markdown/text
					b.hover.dictionary,
					-- b.code_actions.ltrs,
					b.code_actions.proselint,
					b.code_actions.gitsigns,
					b.code_actions.gitrebase,
					b.hover.printenv,
				},
			}

			return vim.tbl_deep_extend("force", opts, user_opts)
		end,
	},
}
