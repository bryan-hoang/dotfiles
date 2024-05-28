-- Suppress warnings in lspconfig.options table.
---@diagnostic disable: missing-fields

local util = require("util")

return {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{
				-- nvim-lspconfig plugin for bundler.
				"mihyaeru21/nvim-lspconfig-bundler",
				opts = {},
			},
		},
		lazy = false,
		opts = function(_, opts)
			vim.g.autoformat = false

			local function format_diagnostic_message(diagnostic)
				if diagnostic.code ~= nil then
					return " [" .. diagnostic.code .. "]"
				end

				return ""
			end

			local user_opts = {
				-- Options for vim.diagnostic.config()
				diagnostics = {
					virtual_text = {
						source = true,
						-- Append error code to match float diagnostic formatting.
						suffix = format_diagnostic_message,
						-- This will set set the prefix to a function that returns the diagnostics icon based on the severity
						-- this only works on a recent 0.10.0 build. Will be set to "●" when not supported
						prefix = "icons",
					},
					float = { source = true },
				},
				-- Be aware that you also will need to properly configure your LSP
				-- server to provide the inlay hints.
				inlay_hints = { enabled = false },
				format = { async = true },
				---@type lspconfig.options
				servers = {
					-- JSON
					jsonls = { mason = false },
					-- YAML
					yamlls = {
						mason = false,
						-- Lazy-load schemastore when needed.
						on_new_config = function(new_config)
							-- NOTE: Use `vim.tbl_extend` over `vim.list_extend` to fix
							-- issues.
							new_config.settings.yaml.schemas = vim.tbl_extend(
								"error",
								new_config.settings.yaml.schemas or {},
								require("schemastore").yaml.schemas()
							)
						end,
						settings = {
							yaml = {
								schemaStore = {
									-- TODO: Remove after LazyVim Update happens.
									--
									-- Avoid TypeError: Cannot read properties of undefined (reading 'length')
									url = "",
								},
							},
						},
					},
					-- Python
					pyright = { mason = false },
					ruff_lsp = { mason = false },
					starlark_rust = {
						mason = false,
						filetypes = { "starlark", "bzl", "BUILD.bazel" },
					},
					-- Lua
					lua_ls = { mason = false },
					-- Shell script
					bashls = {
						mason = false,
						filetypes = { "sh", "zsh" },
						on_attach = function(client, bufnr)
							-- Disable `shellcheck` and semantic token highlighting in dotenv
							-- files.
							local filename = vim.api.nvim_buf_get_name(bufnr)
							if filename:find("%.env$") or filename:find("%.env%.") then
								client.stop(true)
							end
						end,
					},
					-- LaTeX
					texlab = { mason = false },
					rust_analyzer = { mason = false },
					clangd = { mason = false },
					taplo = { mason = false },
					svelte = { mason = false },

					-- Ruby
					solargraph = { mason = false },

					-- TODO: Wait for v0.10.0 release to address push based diagnostics.
					-- https://shopify.github.io/ruby-lsp/EDITORS_md.html#label-Neovim+LSP
					-- ruby_ls = {
					-- 	autostart = false,
					-- 	mason = false,
					-- 	on_attach = function(client, buffer)
					-- 		setup_diagnostics(client, buffer)
					-- 		add_ruby_deps_command(client, buffer)
					-- 	end,
					-- },

					-- C#/F#
					-- omnisharp = {
					-- 	mason = false,
					-- 	cmd = { "OmniSharp" },
					-- 	handlers = {
					-- 		["textDocument/definition"] = require("omnisharp_extended").handler,
					-- 	},
					-- },
					neocmake = {
						-- NOTE: Currently fails to install due to `--locked` option.
						mason = false,
					},
					dockerls = { mason = false },
					docker_compose_language_service = { mason = false },
					-- JS/TS
					denols = { mason = false },
					tsserver = {
						mason = false,
						cmd = { "typescript-language-server", "--stdio", "--log-level=4" },
					},
					biome = { mason = false },
					astro = { mason = false },
					-- HTML/CSS
					html = { mason = false },
					emmet_language_server = { mason = false },
					cssls = { mason = false },
					-- cssmodules_ls = {},
					tailwindcss = {
						filetypes_include = { "markdown.mdx" },
						filetypes_exclude = { "mdx" },
					},
					-- Markdown/MDX
					marksman = { mason = false },
					mdx_analyzer = {
						init_options = {
							typescript = { enabled = true },
						},
						capabilities = {
							dynamicRegistration = true,
						},
					},
					eslint = {
						filetypes = {
							"javascript",
							"javascriptreact",
							"javascript.jsx",
							"typescript",
							"typescriptreact",
							"typescript.tsx",
							"vue",
							"svelte",
							"astro",
							"markdown",
							"markdown.mdx",
						},
						capabilities = {
							workspace = {
								didChangeWorkspaceFolders = {
									-- Workaround "The language server eslint triggers a
									-- registerCapability handler for
									-- workspace/didChangeWorkspaceFolders despite
									-- dynamicRegistration set to false. Report upstream, this
									-- warning is harmless"
									dynamicRegistration = true,
								},
							},
						},
					},
				},
			}

			-- FIXME: Performance with w/ tsserver freezing the program.
			if not util.is_os_unix then
				-- Only install on windows.
				user_opts.servers.powershell_es = {}
			end

			opts = vim.tbl_deep_extend("force", opts, user_opts)

			return opts
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
}
