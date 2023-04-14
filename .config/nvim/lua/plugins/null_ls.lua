local util = require("util")

return {
	{
		"jose-elias-alvarez/null-ls.nvim",
		keys = {
			{
				"<Leader>cn",
				"<Cmd>NullLsInfo<CR>",
				desc = "null-ls Info",
			},
		},
		opts = function()
			local null_ls = require("null-ls")
			local h = require("null-ls.helpers")
			local methods = require("null-ls.methods")

			local b = null_ls.builtins
			local DIAGNOSTICS = methods.internal.DIAGNOSTICS

			return {
				-- debug = true,
				sources = {
					-- Markdown/text
					b.diagnostics.markdownlint,
					b.diagnostics.vale,
					b.hover.dictionary,
					b.diagnostics.ltrs.with({
						diagnostics_postprocess = function(diagnostic)
							diagnostic.severity = vim.diagnostic.severity["HINT"]
						end,
					}),
					b.code_actions.ltrs,
					b.code_actions.proselint,
					b.code_actions.cspell,
					b.diagnostics.cspell.with({
						-- Fails to spawn on windows unless it's called with the extension.
						command = "cspell" .. (util.is_os_unix and "" or ".cmd"),
						env = {
							FORCE_COLOR = "false",
						},
						-- https://github.com/jose-elias-alvarez/null-ls.nvim/issues/538#issuecomment-1037319978
						diagnostics_postprocess = function(diagnostic)
							diagnostic.severity = vim.diagnostic.severity["HINT"]
						end,
						diagnostic_config = {
							virtual_text = false,
						},
					}),
					-- Git commits
					b.diagnostics.commitlint.with({
						-- Fails to spawn on windows unless it's called with the extension.
						command = util.is_os_unix and "commitlint" or "pwsh",
						args = function(params)
							local args = {
								"--format",
								"commitlint-format-json",
								"--config",
								vim.fn.expand(
									"$XDG_CONFIG_HOME/commitlint/commitlint.config.js"
								),
								"--extends",
								vim.fn.expand(
									vim
										.fn
										.system({
											"pnpm",
											"root",
											"--global",
										})
										-- Remove trailing newline character.
										:match(
											"^%s*(.*%S)"
										) .. "/@commitlint/config-conventional"
								),
							}

							if not util.is_os_unix then
								table.insert(
									args,
									1,
									vim.fn.expand("$PNPM_HOME") .. "/commitlint.ps1"
								)
							end

							return args
						end,
					}),

					b.diagnostics.editorconfig_checker.with({
						command = "editorconfig-checker",
					}),
					b.code_actions.gitsigns,
					b.code_actions.gitrebase,
					b.code_actions.refactoring,
					-- JS/TS, CSS
					b.formatting.rome,
					-- b.formatting.deno_fmt,
					b.formatting.eslint_d,
					b.diagnostics.eslint_d,
					b.code_actions.eslint_d,
					b.formatting.prettier,
					b.formatting.stylelint,
					b.diagnostics.stylelint,
					-- lua
					b.diagnostics.selene.with({
						-- https://github.com/kampfkarren/selene/issues/339#issuecomment-1191992366
						cwd = function(_params)
							return vim.fs.dirname(
								vim.fs.find(
									{ "selene.toml" },
									{ upward = true, path = vim.api.nvim_buf_get_name(0) }
								)[1]
								-- fallback value
							) or vim.fn.expand(
								os.getenv("XDG_CONFIG_HOME") .. "/selene/"
							)
						end,
					}),
					b.formatting.stylua,
					-- shell
					b.formatting.shfmt.with({
						extra_args = { "-ci", "-bn", "--simplify" },
						filetypes = { "sh", "zsh" },
					}),
					b.formatting.shellharden.with({
						filetypes = { "sh", "zsh" },
					}),
					b.code_actions.shellcheck.with({
						filetypes = { "sh", "zsh" },
					}),
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
					-- TOML
					b.formatting.taplo.with({
						cwd = function(params)
							return require("null-ls.utils").root_pattern(
								"taplo.toml",
								".taplo.toml",
								".git"
							)(params.bufname)
						end,
					}),
					-- Python
					b.diagnostics.ruff,
					-- Docker
					b.diagnostics.hadolint,
					-- Ruby
					b.diagnostics.rubocop,
					b.formatting.rubocop,
					-- Rust
					b.formatting.rustfmt.with({
						-- https://github.com/jose-elias-alvarez/null-ls.nvim/wiki/Source-specific-Configuration#specifying-edition
						extra_args = function(params)
							local Path = require("plenary.path")
							local cargo_toml = Path:new(params.root .. "/" .. "Cargo.toml")

							if cargo_toml:exists() and cargo_toml:is_file() then
								for _, line in ipairs(cargo_toml:readlines()) do
									local edition = line:match([[^edition%s*=%s*%"(%d+)%"]])
									if edition then
										return { "--edition=" .. edition }
									end
								end
							end

							-- Default edition when we don't find `Cargo.toml` or the `edition` in
							-- it.
							return { "--edition=2021" }
						end,
					}),
				},
			}
		end,
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
	},
}
