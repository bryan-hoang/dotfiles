local severities = {
	warning = vim.diagnostic.severity.WARN,
	error = vim.diagnostic.severity.ERROR,
}

return {
	{
		"joechrisellis/lsp-format-modifications.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		keys = {
			{
				"<leader>cF",
				"<cmd>FormatModifications<cr>",
				desc = "Format Modifications",
			},
		},
		config = function()
			require("lazyvim.util").lsp.on_attach(function(client, buffer)
				if client.server_capabilities.documentRangeFormattingProvider then
					local lsp_format_modifications = require("lsp-format-modifications")
					lsp_format_modifications.attach(
						client,
						buffer,
						{ format_on_save = false }
					)
				end
			end)
		end,
	},
	{
		-- Lightweight yet powerful formatter plugin for Neovim.
		"stevearc/conform.nvim",
		opts = function(_, opts)
			local jsFormatters = { "eslint_d", "biome-check", "biome" }
			local cssFormatters = { "stylelint", "biome-check", "biome" }
			local shFormatters = { "shellcheck", "shellharden", "shfmt" }

			local user_opts = {
				formatters_by_ft = {
					fish = {},
					sh = shFormatters,
					zsh = shFormatters,
					toml = { "taplo" },
					json = { "biome-check", "biome" },
					jsonc = { "biome-check", "biome" },
					yaml = { "prettier" },
					html = { "prettier" },
					svg = { "prettier" },
					css = cssFormatters,
					scss = cssFormatters,
					javascript = jsFormatters,
					typescript = jsFormatters,
					javascriptreact = jsFormatters,
					typescriptreact = jsFormatters,
					ruby = { "rubyfmt", "rubocop" },
					kdl = { "kdlfmt" },
					python = { "ruff_fix", "ruff_format" },
					cmake = { "cmake_format" },
				},
				-- LazyVim will merge the options you set here with builtin formatters.
				-- You can also define any custom formatters here.
				---@type table<string,table>
				formatters = {
					shfmt = {
						args = { "-filename", "$FILENAME", "-ci", "-bn", "--simplify" },
					},
					biome = {
						require_cwd = true,
					},
					["biome-check"] = {
						require_cwd = true,
					},
					eslint_d = {
						require_cwd = true,
						cwd = require("conform.util").root_file({
							"eslint.config.js",
						}),
					},
					kdlfmt = {
						command = "kdlfmt",
						args = { "format", "$FILENAME" },
						stdin = false,
					},
					cmake_format = {
						args = { "--dangle-parens", "--enable-markup=no ", "-" },
					},
				},
			}
			return vim.tbl_deep_extend("force", opts, user_opts)
		end,
	},
	{
		"mfussenegger/nvim-lint",
		opts = function(_, opts)
			local cssLinters = { "biomejs", "stylelint" }

			local user_opts = {
				linters_by_ft = {
					dockerfile = { "hadolint" },
					fish = {},
					markdown = { "markdownlint-cli2" },
					dotenv = { "dotenv_linter" },
					css = cssLinters,
					scss = cssLinters,
					-- May or may not want
					-- https://github.com/kampfkarren/selene/issues/340#issuecomment-1191992366
					lua = { "selene" },
					gitcommit = { "commitlint" },
					html = { "markuplint" },
					["*"] = { "typos", "editorconfig-checker" },
				},
				linters = {
					stylelint = {
						-- https://github.com/mfussenegger/nvim-lint/blob/master/lua/lint/linters/stylelint.lua
						parser = function(output)
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
					["editorconfig-checker"] = {
						condition = function()
							-- Make `git.commit = verbose` setting less noisy with diagnostic
							-- messages.
							return vim.bo.filetype ~= "gitcommit"
						end,
					},
				},
			}

			local merged_opts = vim.tbl_deep_extend("force", opts, user_opts)

			return merged_opts
		end,
	},
}
