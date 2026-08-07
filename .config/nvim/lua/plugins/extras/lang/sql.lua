return {
	{
		"mason-org/mason.nvim",
		opts = function(_, opts)
			opts.ensure_installed = vim.tbl_filter(function(p)
				return not vim.tbl_contains({ "sqlfluff" }, p)
			end, opts.ensure_installed)
		end,
	},
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
