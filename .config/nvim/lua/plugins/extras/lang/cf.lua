return {
	{
		"mfussenegger/nvim-lint",
		optional = true,
		opts = function(_, opts)
			local function get_file_name()
				return vim.api.nvim_buf_get_name(0)
			end
			local severities = {
				[1] = vim.diagnostic.severity.INFO,
				[2] = vim.diagnostic.severity.WARN,
				[3] = vim.diagnostic.severity.ERROR,
			}
			local user_opts = {
				linters = {
					fixinator = {
						cmd = "box",
						-- https://github.com/foundeo/fixinator#command-line-arguments
						args = {
							"path=" .. get_file_name(),
						},
						parser = function(output)
							local diagnostics = {}
							local ok, decoded = pcall(vim.json.decode, output)

							if not ok then
								return diagnostics
							end

							for _, result in ipairs(decoded.results or {}) do
								local diagnostic = {
									message = result.description,
									lnum = result.row,
									end_lnum = result.row,
									col = result.column,
									end_col = result.column,
									code = result.id,
									severity = severities[result.severity],
									source = "fixinator",
								}
								table.insert(diagnostics, diagnostic)
							end
							return diagnostics
						end,
					},
				},
				linters_by_ft = {
					cf = { "fixinator" },
				},
			}

			local merged_opts = vim.tbl_deep_extend("force", opts, user_opts)
			return merged_opts
		end,
	},
}
