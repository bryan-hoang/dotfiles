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
		"ThePrimeagen/refactoring.nvim",
		dependencies = {
			{ "nvim-lua/plenary.nvim" },
			{ "nvim-treesitter/nvim-treesitter" },
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
		"folke/neodev.nvim",
		opts = {
			library = {
				plugins = {
					"nvim-dap-ui",
					"neotest",
				},
				types = true,
			},
		},
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
			local jsFormatters = { prettier }
			local cssFormatters = { "stylelint", prettier }
			local shFormatters = { "shellcheck", "shellharden", "shfmt" }

			local user_opts = {
				formatters_by_ft = {
					fish = {},
					sh = shFormatters,
					zsh = shFormatters,
					toml = { "taplo" },
					json = { prettier },
					jsonc = { prettier },
					yaml = { prettier },
					html = { prettier },
					markdown = { "markdownlint", prettier },
					css = cssFormatters,
					scss = cssFormatters,
					javascript = jsFormatters,
					typescript = jsFormatters,
					javascriptreact = jsFormatters,
					typescriptreact = jsFormatters,
					ruby = { "rubyfmt", "rubocop" },
					-- rust = { "rustfmt" },
				},
				-- LazyVim will merge the options you set here with builtin formatters.
				-- You can also define any custom formatters here.
				---@type table<string,table>
				formatters = {
					-- -- Example of using dprint only when a dprint.json file is present
					-- dprint = {
					--   condition = function(ctx)
					--     return vim.fs.find({ "dprint.json" }, { path = ctx.filename, upward = true })[1]
					--   end,
					-- },
					shfmt = {
						args = { "-filename", "$FILENAME", "-ci", "-bn", "--simplify" },
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
					["*"] = { "typos" },
				},
				linters = {
					-- TODO: Contribute `ltrs`, `markuplint`
					-- `editorconfig_checker`, to `nvim-lint`!
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
