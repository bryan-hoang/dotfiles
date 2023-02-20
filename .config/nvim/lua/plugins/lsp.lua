return {
	-- LSP keymaps
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"joechrisellis/lsp-format-modifications.nvim",
		},
		opts = function(_, opts)
			-- https://github.com/b0o/SchemaStore.nvim/issues/9#issuecomment-1140321123
			local json_schemas = require("schemastore").json.schemas({})
			local yaml_schemas = {}
			vim.tbl_map(function(schema)
				yaml_schemas[schema.url] = schema.fileMatch
			end, json_schemas)

			local function format_diagnostic_message(diagnostic)
				local message = diagnostic.message
				if diagnostic.code ~= nil then
					message = message .. " [" .. diagnostic.code .. "]"
				end

				return message
			end

			return vim.tbl_deep_extend("force", opts, {
				-- Options for vim.diagnostic.config()
				diagnostics = {
					virtual_text = {
						source = true,
						format = format_diagnostic_message,
					},
					float = {
						source = true,
					},
				},
				format = {
					timeout_ms = 2000,
				},
				autoformat = false,
				---@type lspconfig.options
				servers = {
					taplo = {
						mason = false,
					},
					yamlls = {
						mason = false,
						settings = {
							yaml = {
								schemas = yaml_schemas,
							},
						},
					},
					pylsp = {
						mason = false,
					},
					tsserver = {
						mason = false,
					},
					jsonls = {
						mason = false,
					},
					lua_ls = {
						mason = false,
					},
					clangd = {
						mason = false,
						capabilities = {
							-- Prevent offset warning.
							offsetEncoding = { "utf-16" },
						},
					},
				},
			})
		end,
		init = function()
			local keys = require("lazyvim.plugins.lsp.keymaps").get()

			keys[#keys + 1] = { "K", false }
			keys[#keys + 1] = {
				"<leader>k",
				vim.lsp.buf.hover,
				desc = "Show docs for item under cursor (Hover)",
			}
			keys[#keys + 1] = { "gt", false }
			keys[#keys + 1] = {
				"gy",
				"<cmd>Telescope lsp_type_definitions<cr>",
				desc = "Goto type definition",
			}
			keys[#keys + 1] = { "gI", false }
			keys[#keys + 1] = {
				"gi",
				"<cmd>Telescope lsp_implementations<cr>",
				desc = "Goto implementation",
			}
			keys[#keys + 1] = { "ca", false }
			keys[#keys + 1] = {
				"<leader>ca",
				vim.lsp.buf.code_action,
				desc = "Perform code action",
				mode = { "n", "v" },
				has = "codeAction",
			}
		end,
	},
	{
		"williamboman/mason.nvim",
		opts = {
			ensure_installed = {
				"selene",
			},
		},
	},
	{
		"jose-elias-alvarez/null-ls.nvim",
		opts = function()
			local present, null_ls = pcall(require, "null-ls")

			if not present then
				return
			end

			local b = null_ls.builtins
			return {
				sources = {
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
			require("lazyvim.util").on_attach(function(client, buffer)
				local lsp_format_modifications = require("lsp-format-modifications")
				lsp_format_modifications.attach(
					client,
					buffer,
					{ format_on_save = false }
				)
			end)
		end,
	},
	{
		"folke/neodev.nvim",
		opts = {
			library = {
				plugins = {
					"nvim-dap-ui",
				},
				types = true,
			},
		},
	},
}
