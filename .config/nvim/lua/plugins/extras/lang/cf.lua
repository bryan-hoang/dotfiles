return {
	{
		"mfussenegger/nvim-lint",
		optional = true,
		opts = function(_, opts)
			local function get_path_arg()
				return "path=" .. vim.api.nvim_buf_get_name(0)
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
						stdin = false,
						append_fname = false,
						ignore_exitcode = true,
						-- https://github.com/foundeo/fixinator#command-line-arguments
						args = {
							"fixinator",
							"json=true",
							get_path_arg,
						},
						parser = function(output)
							local diagnostics = {}
							local ok, decoded = pcall(vim.json.decode, output)

							if not ok then
								return diagnostics
							end

							for _, result in ipairs(decoded.results or {}) do
								local diagnostic = {
									lnum = result.line - 1,
									col = result.column,
									severity = severities[result.severity],
									message = result.description,
									source = "fixinator",
									code = result.id,
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
