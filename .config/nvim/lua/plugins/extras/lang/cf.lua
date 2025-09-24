return {
	{
		"mfussenegger/nvim-lint",
		optional = true,
		opts = function(_, opts)
			local function get_path_arg()
				return "path=" .. vim.api.nvim_buf_get_name(0)
			end
			local function get_file_name()
				return vim.api.nvim_buf_get_name(0)
			end

			local fixinatorSeverities = {
				[1] = vim.diagnostic.severity.INFO,
				[2] = vim.diagnostic.severity.WARN,
				[3] = vim.diagnostic.severity.ERROR,
			}
			local cflintSeverities = {
				INFO = vim.diagnostic.severity.INFO,
				WARNING = vim.diagnostic.severity.WARN,
				ERROR = vim.diagnostic.severity.ERROR,
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
									col = result.column - 1,
									severity = fixinatorSeverities[result.severity],
									message = result.description,
									source = "fixinator",
									code = result.id,
								}
								table.insert(diagnostics, diagnostic)
							end

							return diagnostics
						end,
					},
					cflint = {
						cmd = "java",
						stdin = true,
						args = {
							"-jar",
							os.getenv("XDG_DATA_HOME") .. "/cflint/CFLint-1.5.0-all.jar",
							"-e",
							"-quiet",
							"-json",
							"-stdout",
							"-stdin",
							get_file_name,
						},
						parser = function(output)
							local diagnostics = {}
							local ok, decoded = pcall(vim.json.decode, output)

							if not ok then
								return diagnostics
							end

							for _, issue in ipairs(decoded.issues or {}) do
								for _, location in ipairs(issue.locations) do
									local diagnostic = {
										lnum = location.line - 1,
										col = location.column,
										severity = cflintSeverities[issue.severity],
										message = location.message,
										source = "cflint",
										code = issue.id,
									}
									table.insert(diagnostics, diagnostic)
								end
							end

							return diagnostics
						end,
					},
				},

				linters_by_ft = {
					cf = { "fixinator", "cflint" },
				},
			}

			local merged_opts = vim.tbl_deep_extend("force", opts, user_opts)
			return merged_opts
		end,
	},
}
