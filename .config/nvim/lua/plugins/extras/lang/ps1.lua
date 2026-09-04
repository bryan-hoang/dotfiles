return {
	{
		"mason-org/mason.nvim",
		opts = {
			ensure_installed = {
				"powershell-editor-services",
			},
		},
	},
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				-- PowerShell is managed by `powershell.nvim`.
				powershell_es = { enabled = false },
			},
		},
	},
	{
		"TheLeoP/powershell.nvim",
		ft = "ps1",
		opts = {
			bundle_path = vim.fn.stdpath("data")
				.. "/mason/packages/powershell-editor-services",
		},
	},
	{
		"conform.nvim",
		optional = true,
		opts = function(_, opts)
			local user_opts = {
				formatters = {
					ps_script_analyzer = {
						command = "pwsh",
						-- Profiles provide the shared `PSScriptAnalyzer` settings.
						stdin = true,
						args = {
							"-Command",
							"Invoke-Formatter",
							"-ScriptDefinition",
							"($input | Out-String)",
						},
					},
				},
				formatters_by_ft = {
					ps1 = { "ps_script_analyzer" },
				},
			}

			local merged_opts = vim.tbl_deep_extend("force", opts, user_opts)

			return merged_opts
		end,
	},
	{
		"mfussenegger/nvim-lint",
		optional = true,
		opts = function(_, opts)
			local severity = {
				[0] = vim.diagnostic.severity.INFO,
				[1] = vim.diagnostic.severity.WARN,
				[2] = vim.diagnostic.severity.ERROR,
			}
			local user_opts = {
				linters = {
					ps_script_analyzer = {
						cmd = "pwsh",
						stdin = true,
						args = {
							"-Command",
							"Invoke-ScriptAnalyzer",
							"-ScriptDefinition",
							"($input | Out-String) | ConvertTo-Json -Depth 4",
						},
						parser = function(output)
							local decoded = vim.json.decode(output)
							local messages = {}
							if vim.isarray(decoded) then
								messages = decoded
							else
								table.insert(messages, 1, decoded)
							end
							local diagnostics = {}
							for _, item in ipairs(messages) do
								table.insert(diagnostics, {
									lnum = item.Extent.StartLineNumber - 1,
									col = item.Extent.StartColumnNumber - 1,
									end_lnum = item.Extent.EndLineNumber - 1,
									end_col = item.Extent.EndColumnNumber - 1,
									code = item.RuleName,
									source = "PSScriptAnalyzer",
									severity = severity[item.Severity],
									message = item.Message,
								})
							end
							return diagnostics
						end,
					},
				},
				linters_by_ft = {
					ps1 = { "ps_script_analyzer" },
				},
			}

			local merged_opts = vim.tbl_deep_extend("force", opts, user_opts)
			return merged_opts
		end,
	},
}
