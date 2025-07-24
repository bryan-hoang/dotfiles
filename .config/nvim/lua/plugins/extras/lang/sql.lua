return {
	{
		"stevearc/conform.nvim",
		optional = true,
		opts = function(_, opts)
			opts.formatters.sqlfluff = {
				args = { "format", "-" },
			}
		end,
	},
	{
		"mfussenegger/nvim-lint",
		optional = true,
		opts = function(_, opts)
			local user_opts = {
				linters = {
					sqlfluff = {
						args = {
							"lint",
							"--format=json",
						},
					},
				},
			}

			local merged_opts = vim.tbl_deep_extend("force", opts, user_opts)
			return merged_opts
		end,
	},
}
