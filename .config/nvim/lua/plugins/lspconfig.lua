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

			local keys = require("lazyvim.plugins.lsp.keymaps").get()

			-- https://github.com/LazyVim/LazyVim/discussions/3880#discussioncomment-9975351
			keys[#keys + 1] = { "K", "" }
			keys[#keys + 1] = {
				"<leader>k",
				vim.lsp.buf.hover,
				desc = "Show docs for item under cursor (Hover)",
			}
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
					jsonls = {
						mason = false,
						settings = {
							json = {
								schemas = require("schemastore").json.schemas({
									ignore = {
										-- Ignore files like "app.json" that may be used for
										-- translations instead.
										"Expo SDK",
									},
								}),
							},
						},
						-- Don't auto extend the JSON schema defined previously.
						on_new_config = function() end,
					},
					-- YAML
					yamlls = { mason = false },
					-- Python
					pyright = { mason = false },
					ruff = { mason = false },
					starlark_rust = {
						mason = false,
						filetypes = { "starlark", "bzl", "BUILD.bazel" },
					},
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
					biome = { mason = false },
					astro = { mason = false },
					vtsls = {
						settings = {
							javascript = {
								suggest = {
									-- In Neovim, the names add noise, making it very difficult to
									-- go through suggested fields interspersed throughout the
									-- text based suggestions. I don't know how VS Code sorts it
									-- the way I prefer.
									names = false,
								},
							},
						},
					},
					denols = {
						mason = false,
						root_dir = require("lspconfig.util").root_pattern(
							"deno.json",
							"deno.jsonc"
						),
					},
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
					marksman = {},
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
					vale_ls = {
						filetypes = { "markdown", "text", "tex", "gitcommit" },
					},
				},
			}

			if not util.is_os_unix then
				-- Only install on windows.
				user_opts.servers.powershell_es = {}
			end

			opts = vim.tbl_deep_extend("force", opts, user_opts)

			return opts
		end,
	},
}
