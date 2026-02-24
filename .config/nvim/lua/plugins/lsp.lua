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
			-- local jsFormatters = { "oxlint", "oxfmt", }
			-- local cssFormatters = { "oxlint", "oxfmt", }
			local shFormatters = { "shellcheck", "shellharden", "shfmt" }

			local user_opts = {
				formatters_by_ft = {
					cmake = { "cmake_format" },
					-- css = cssFormatters,
					fish = {},
					-- html = { "oxfmt" },
					-- javascript = jsFormatters,
					-- javascriptreact = jsFormatters,
					-- json = { "oxfmt" },
					-- jsonc = { "oxfmt" },
					kdl = { "kdlfmt" },
					python = { "ruff_fix", "ruff_format" },
					ruby = { "rubyfmt", "rubocop" },
					-- scss = cssFormatters,
					sh = shFormatters,
					svg = { "prettier" },
					toml = { "oxfmt", "taplo" },
					-- typescript = jsFormatters,
					-- typescriptreact = jsFormatters,
					xml = { "xmlstarlet" },
					-- yaml = { "oxfmt" },
					zsh = shFormatters,
				},
				-- LazyVim will merge the options you set here with built-in formatters.
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
					xmlstarlet = {
						args = { "format", "--indent-tab", "-" },
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
					["*"] = { "typos", "editorconfig-checker" },
					css = cssLinters,
					dockerfile = { "hadolint" },
					dotenv = { "dotenv_linter" },
					fish = {},
					gitcommit = { "commitlint" },
					html = { "markuplint" },
					-- May or may not want
					-- https://github.com/kampfkarren/selene/issues/340#issuecomment-1191992366
					lua = { "selene" },
					markdown = { "markdownlint-cli2" },
					scss = cssLinters,
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
					-- Modifying to show warnings as warnings.
					-- https://github.com/mfussenegger/nvim-lint/blob/master/lua/lint/linters/commitlint.lua
					commitlint = {
						parser = function(output)
							local diagnostics = {}
							local result = vim.fn.split(output, "\n")
							for _, line in ipairs(result) do
								local label = line:sub(1, 3)
								if label == "✖" then
									if not string.find(line, "found") then
										table.insert(diagnostics, {
											source = "commitlint",
											lnum = 0,
											col = 0,
											severity = vim.diagnostic.severity.ERROR,
											message = vim.fn.split(line, "   ")[2],
										})
									end
								end
								-- Add warnings as well.
								if label == "⚠" then
									if not string.find(line, "found") then
										table.insert(diagnostics, {
											source = "commitlint",
											lnum = 0,
											col = 0,
											severity = vim.diagnostic.severity.WARN,
											message = vim.fn.split(line, "   ")[2],
										})
									end
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
