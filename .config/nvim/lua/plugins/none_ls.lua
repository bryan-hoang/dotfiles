local util = require("util")

return {
	{
		"nvimtools/none-ls.nvim",
		enabled = true,
		keys = {
			{
				"<Leader>cn",
				"<Cmd>NullLsInfo<CR>",
				desc = "null-ls Info",
			},
		},
		opts = function(_, opts)
			local nls = require("null-ls")
			local h = require("null-ls.helpers")
			local cmd_resolver = require("null-ls.helpers.command_resolver")
			local methods = require("null-ls.methods")

			local b = nls.builtins
			local DIAGNOSTICS = methods.internal.DIAGNOSTICS
			local FORMATTING = methods.internal.FORMATTING

			local user_opts = {
				debug = os.getenv("DEBUG") == "nvim:null-ls",
				sources = {
					-- Markdown/text
					b.hover.dictionary,
					-- LanguageTool costs money for a decent experience. So, I'm switching
					-- to a free alternative.
					-- b.diagnostics.ltrs.with({
					-- 	diagnostics_postprocess = function(diagnostic)
					-- 		diagnostic.severity = vim.diagnostic.severity["HINT"]
					-- 	end,
					-- 	-- Add `gitcommit` to the list.
					-- 	filetypes = { "text", "markdown", "gitcommit" },
					-- 	-- Filter frontmatter lines to prevent cli parsing issues.
					-- 	args = {
					-- 		"check",
					-- 		"-m",
					-- 		"-r",
					-- 		"--text",
					-- 		"$(echo \"$TEXT\" | sed '/---/d')",
					-- 	},
					-- }),
					-- b.code_actions.ltrs,
					b.code_actions.proselint,
					b.diagnostics.markuplint,
					b.diagnostics.editorconfig_checker.with({
						command = "editorconfig-checker",
					}),
					b.code_actions.gitsigns,
					b.code_actions.gitrebase,
					b.code_actions.refactoring,
					-- CSS
					-- h.make_builtin({
					-- 	name = "stylelint",
					-- 	meta = {
					-- 		url = "https://github.com/stylelint/stylelint",
					-- 		description = "A mighty, modern linter that helps you avoid errors and enforce conventions in your styles.",
					-- 	},
					-- 	method = FORMATTING,
					-- 	filetypes = { "scss", "less", "css", "sass" },
					-- 	generator_opts = {
					-- 		command = "stylelint",
					-- 		args = { "--fix", "--stdin", "--stdin-filename", "$FILENAME" },
					-- 		to_stdin = true,
					-- 		from_stderr = true,
					-- 		-- NOTE: Ignore stderr be default, otherwise formatting output is
					-- 		-- ignored.
					-- 		ignore_stderr = false,
					-- 		dynamic_command = cmd_resolver.from_node_modules(),
					-- 	},
					-- 	factory = h.formatter_factory,
					-- }),
					-- https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/lua/null-ls/builtins/diagnostics/stylelint.lua
					-- h.make_builtin({
					-- 	name = "stylelint",
					-- 	meta = {
					-- 		url = "https://github.com/stylelint/stylelint",
					-- 		description = "A mighty, modern linter that helps you avoid errors and enforce conventions in your styles.",
					-- 	},
					-- 	method = DIAGNOSTICS,
					-- 	filetypes = { "scss", "less", "css", "sass" },
					-- 	generator_opts = {
					-- 		command = "stylelint",
					-- 		args = { "--formatter", "json", "--stdin-filename", "$FILENAME" },
					-- 		to_stdin = true,
					-- 		format = "json_raw",
					-- 		dynamic_command = cmd_resolver.from_node_modules(),
					-- 		-- NOTE: Don't read messages like "reusing global emitter". Not
					-- 		-- sure when it appears.
					-- 		from_stderr = true,
					-- 		-- ignore_stderr = true,
					-- 		on_output = function(params)
					-- 			local output = params.output
					-- 					and params.output[1]
					-- 					and params.output[1].warnings
					-- 				or {}
					--
					-- 			-- json decode failure means stylelint failed to run
					-- 			if params.err then
					-- 				table.insert(output, { text = params.output })
					-- 			end
					--
					-- 			local parser = h.diagnostics.from_json({
					-- 				attributes = {
					-- 					-- NOTE: Add the rule to the error code.
					-- 					code = "rule",
					-- 					severity = "severity",
					-- 					message = "text",
					-- 				},
					-- 				severities = {
					-- 					h.diagnostics.severities["warning"],
					-- 					h.diagnostics.severities["error"],
					-- 				},
					-- 			})
					--
					-- 			params.output = output
					-- 			return parser(params)
					-- 		end,
					-- 	},
					-- 	factory = h.generator_factory,
					-- }),
					-- lua
					--
					-- https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/lua/null-ls/builtins/diagnostics/dotenv_linter.lua
					h.make_builtin({
						name = "dotenv-linter",
						meta = {
							url = "https://github.com/dotenv-linter/dotenv-linter",
							description = "Lightning-fast linter for .env files.",
						},
						method = DIAGNOSTICS,
						filetypes = { "sh" },
						generator_opts = {
							command = "dotenv-linter",
							args = { "$FILENAME" },
							from_stderr = false,
							ignore_stderr = false,
							format = "line",
							check_exit_code = function(code)
								return code <= 1
							end,
							to_temp_file = true,
							-- NOTE: Customize when source is enabled.
							runtime_condition = h.cache.by_bufnr(function(params)
								return params.bufname:find("%.env.*") ~= nil
									and params.bufname:find(".envrc") == nil
							end),
							on_output = h.diagnostics.from_pattern(
								[[%w+:(%d+) (%w+): (.*)]],
								{ "row", "code", "message" }
							),
						},
						factory = h.generator_factory,
					}),
					b.hover.printenv,
				},

				on_attach = function(client, buffer)
					-- https://github.com/joechrisellis/lsp-format-modifications.nvim#tested-language-servers
					if client.server_capabilities.documentRangeFormattingProvider then
						local lsp_format_modifications = require("lsp-format-modifications")
						lsp_format_modifications.attach(
							client,
							buffer,
							{ format_on_save = false }
						)
					end
				end,
			}

			return vim.tbl_deep_extend("force", opts, user_opts)
		end,
	},
}
