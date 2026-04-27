return {
	{
		-- Lightweight yet powerful formatter plugin for Neovim.
		"stevearc/conform.nvim",
		opts = function(_, opts)
			local shFormatters = { "shellcheck", "shellharden", "shfmt" }

			local user_opts = {
				formatters_by_ft = {
					cmake = { "cmake_format" },
					fish = {},
					json = { "oxfmt" },
					jsonc = { "oxfmt" },
					kdl = { "kdlfmt" },
					markdown = { "oxfmt", "markdownlint-cli2", "markdown-toc" },
					python = { "ruff_fix", "ruff_format" },
					ruby = { "rubyfmt", "rubocop" },
					sh = shFormatters,
					svg = { "prettier" },
					toml = { "oxfmt", "taplo" },
					xml = { "xmlstarlet" },
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
}
