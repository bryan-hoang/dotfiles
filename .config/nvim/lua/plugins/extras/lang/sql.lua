return {
	{
		"stevearc/conform.nvim",
		optional = true,
		opts = function(_, opts)
			opts.formatters = {
				sqlfluff = {
					args = { "format", "-" },
				},
			}
		end,
	},
	{
		"mfussenegger/nvim-lint",
		optional = true,
		opts = function(_, opts)
			opts.linters = {
				sqlfluff = {
					args = {
						"lint",
						"--format=json",
					},
				},
			}
		end,
	},
}
