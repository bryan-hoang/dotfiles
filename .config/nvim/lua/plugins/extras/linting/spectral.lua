local spectralSeverities = {
	[0] = vim.diagnostic.severity.ERROR,
	[1] = vim.diagnostic.severity.WARN,
	[2] = vim.diagnostic.severity.INFO,
	[3] = vim.diagnostic.severity.HINT,
}

local no_ruleset_found_msg = [[Spectral could not find a ruleset.
Please define a .spectral file in the current working directory or override the linter args to provide the path to a ruleset.]]

return {
	{
		"mfussenegger/nvim-lint",
		opts = function(_, opts)
			local user_opts = {
				linters_by_ft = {
					yaml = { "spectral" },
				},
				linters = {
					spectral = {
						parser = function(output)
							-- Inform user if no ruleset has been found
							if string.find(output, "No ruleset has been found") ~= nil then
								vim.notify(no_ruleset_found_msg, vim.log.levels.WARN)
								return {}
							end

							local result = vim.json.decode(output)

							-- Prevent warning on `yaml` files without supported schema
							if result[1].code == "unrecognized-format" then
								return {}
							end

							local diagnostics = {}
							local bufpath = vim.fs.normalize(vim.fn.expand("%:p"))
							for _, diagnostic in ipairs(result) do
								if
									-- NOTE(bryan-hoang): Normalize file paths before comparison.
									vim.fs.normalize(diagnostic.source) == bufpath
								then
									table.insert(diagnostics, {
										source = "spectral",
										severity = spectralSeverities[diagnostic.severity],
										code = diagnostic.code,
										message = diagnostic.message,
										lnum = diagnostic.range.start.line,
										end_lnum = diagnostic.range["end"].line,
										col = diagnostic.range.start.character,
										end_col = diagnostic.range["end"].character,
									})
								end
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
