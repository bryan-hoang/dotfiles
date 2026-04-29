return {
	{
		"mfussenegger/nvim-lint",
		opts = function(_, opts)
			local cssLinters = { "biomejs", "stylelint" }

			local user_opts = {
				linters_by_ft = {
					["*"] = { "typos", "editorconfig-checker" },
					css = cssLinters,
					dockerfile = { "hadolint" },
					dotenv = { "dotenv_linter" },
					fish = {},
					html = { "markuplint" },
					-- May or may not want
					-- https://github.com/kampfkarren/selene/issues/340#issuecomment-1191992366
					lua = { "selene" },
					markdown = { "markdownlint-cli2" },
					scss = cssLinters,
				},
				linters = {
					["editorconfig-checker"] = {
						condition = function()
							-- Make `git.commit = verbose` setting less noisy with diagnostic
							-- messages.
							return vim.bo.filetype ~= "gitcommit"
						end,
					},
					stylelint = {
						-- https://github.com/mfussenegger/nvim-lint/blob/master/lua/lint/linters/stylelint.lua
						parser = function(output)
							local severities = {
								warning = vim.diagnostic.severity.WARN,
								error = vim.diagnostic.severity.ERROR,
							}

							local status, decoded = pcall(vim.json.decode, output)
							if status then
								decoded = decoded[1]
							else
								decoded = {
									warnings = {
										{
											line = 1,
											column = 1,
											text = "Stylelint error, run `stylelint "
												.. vim.fn.expand("%")
												.. "` for more info.",
											severity = "error",
											rule = "none",
										},
									},
									errored = true,
								}
							end
							local diagnostics = {}
							-- Print diagnostics, even when `errored` is `false` for warnings
							-- to show up.
							for _, message in ipairs(decoded.warnings) do
								table.insert(diagnostics, {
									lnum = message.line - 1,
									col = message.column - 1,
									end_lnum = message.line - 1,
									end_col = message.column - 1,
									message = message.text,
									code = message.rule,
									user_data = {
										lsp = {
											code = message.rule,
										},
									},
									severity = severities[message.severity],
									source = "stylelint",
								})
							end
							return diagnostics
						end,
					},
				},
			}

			local merged_opts = vim.tbl_deep_extend("force", opts, user_opts)
			return merged_opts
		end,
	},
}
