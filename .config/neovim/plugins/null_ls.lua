return {
	-- Load it after nvim-lspconfig cuz we lazy loaded lspconfig.
	after = { "nvim-lspconfig", "lsp-format-modifications.nvim" },
	config = function()
		local present, null_ls = pcall(require, "null-ls")

		if not present then
			return
		end

		local b = null_ls.builtins
		local sources = {
			b.diagnostics.editorconfig_checker.with({
				command = "editorconfig-checker",
			}),
			b.code_actions.gitsigns,
			b.code_actions.gitrebase,
			b.code_actions.refactoring,
			-- JS/TS, CSS
			b.formatting.rome,
			b.formatting.deno_fmt,
			b.formatting.eslint,
			b.diagnostics.eslint,
			b.code_actions.eslint,
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
					) or vim.fn.expand(os.getenv("xdg_config_home") .. "/selene/")
				end,
			}),
			b.formatting.stylua,
			-- shell
			b.formatting.shfmt.with({
				extra_args = { "-ci", "-bn" },
				filetypes = { "sh", "zsh" },
			}),
			b.formatting.shellharden.with({
				filetypes = { "sh", "zsh" },
			}),
			b.code_actions.shellcheck,
			-- TOML
			b.formatting.taplo,
			-- Markdown
			b.diagnostics.markdownlint,
			b.diagnostics.vale,
			-- Python
			b.diagnostics.ruff,
			-- Docker
			b.diagnostics.hadolint,
			-- Ruby
			b.diagnostics.rubocop,
			b.formatting.rubocop,
		}

		null_ls.setup({
			sources = sources,
			on_attach = function(client, bufnr)
				require("lsp-format-modifications").attach(
					client,
					bufnr,
					{ format_on_save = false }
				)
			end,
		})
	end,
}
