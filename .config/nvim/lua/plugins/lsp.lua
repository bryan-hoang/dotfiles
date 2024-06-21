return {
	{
		"williamboman/mason.nvim",
		-- I want to use the command in the editor as well as on the CLI.
		enabled = true,
		opts = {
			ensure_installed = {},
		},
	},
	{
		"mason-nvim-dap.nvim",
		enabled = true,
		opts = {
			automatic_installation = false,
		},
	},
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
		keys = {
			{
				"<Leader>cc",
				function()
					vim.cmd([[ConformInfo]])
				end,
				mode = { "n", "v" },
				desc = "Conform Info",
			},
		},
		opts = function(_, opts)
			local prettier = { "prettierd", "prettier" }
			local biome = { "biome-check", "biome" }
			local jsFormatters = { "biome-check", "biome", prettier, "eslint_d" }
			local cssFormatters = { "stylelint", prettier }
			local shFormatters = { "shellcheck", "shellharden", "shfmt" }

			local user_opts = {
				formatters_by_ft = {
					fish = {},
					sh = shFormatters,
					zsh = shFormatters,
					toml = { "taplo" },
					json = { "prettier" },
					jsonc = biome,
					yaml = { prettier },
					html = { prettier },
					svg = { prettier },
					markdown = { "markdownlint", prettier },
					css = cssFormatters,
					scss = cssFormatters,
					javascript = jsFormatters,
					typescript = jsFormatters,
					javascriptreact = jsFormatters,
					typescriptreact = jsFormatters,
					ruby = { "rubyfmt", "rubocop" },
					kdl = { "kdlfmt" },
					python = { "ruff_fix", "ruff_format" },
				},
				-- LazyVim will merge the options you set here with builtin formatters.
				-- You can also define any custom formatters here.
				---@type table<string,table>
				formatters = {
					shfmt = {
						args = { "-filename", "$FILENAME", "-ci", "-bn", "--simplify" },
					},
					biome = {
						cwd = require("conform.util").root_file({
							"biome.json",
							"biome.jsonc",
						}),
						require_cwd = true,
					},
					["biome-check"] = {
						cwd = require("conform.util").root_file({
							"biome.json",
							"biome.jsonc",
						}),
						require_cwd = true,
					},
					prettier = {
						require_cwd = true,
						options = {
							ft_parsers = {
								json = "json",
							},
						},
					},
					prettierd = {
						require_cwd = true,
					},
					eslint_d = {
						cwd = require("conform.util").root_file({
							"eslint.config.js",
						}),
						require_cwd = true,
					},
					kdlfmt = {
						command = "kdlfmt",
						args = { "format", "$FILENAME" },
						stdin = false,
					},
				},
			}
			return vim.tbl_deep_extend("force", opts, user_opts)
		end,
	},
	{
		"mfussenegger/nvim-lint",
		opts = function(_, opts)
			local cssLinters = { "stylelint" }

			local user_opts = {
				linters_by_ft = {
					dockerfile = { "hadolint" },
					fish = {},
					markdown = { "markdownlint", "vale" },
					dotenv = { "dotenv_linter" },
					css = cssLinters,
					scss = cssLinters,
					-- May or may not want
					-- https://github.com/kampfkarren/selene/issues/340#issuecomment-1191992366
					lua = { "selene" },
					gitcommit = { "commitlint", "vale" },
					html = { "markuplint" },
					["*"] = { "typos", "editorconfig-checker" },
				},
				linters = {
					stylelint = {
						-- v16 switched from reporting on stdout to stderr.
						stream = "stderr",
					},
				},
			}

			local merged_opts = vim.tbl_deep_extend("force", opts, user_opts)

			return merged_opts
		end,
	},
}
