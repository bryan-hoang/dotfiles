return {
	{
		"stevearc/conform.nvim",
		optional = true,
		opts = function(_, opts)
			local user_opts = {
				formatters = {
					jqfmt = {
						command = "jqfmt",
						stdin = true,
						args = {
							"-ob",
							"-ar",
							"-op",
							"pipe",
						},
					},
				},
				formatters_by_ft = {
					jq = { "jqfmt" },
				},
			}

			local merged_opts = vim.tbl_deep_extend("force", opts, user_opts)

			return merged_opts
		end,
	},
}
