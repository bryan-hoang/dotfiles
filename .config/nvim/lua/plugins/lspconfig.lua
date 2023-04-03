local util = require("util")

return {
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

			local user_opts = {
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
					async = true,
					timeout_ms = 4000,
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
						filetypes = { "json", "jsonc", "json5" },
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
					bashls = {
						mason = false,
						filetypes = { "sh", "zsh" },
					},
					cssls = {
						mason = false,
					},
					html = {
						mason = false,
					},
					emmet_ls = {
						mason = false,
					},
					texlab = {
						mason = false,
					},
					marksman = {
						mason = false,
					},
					neocmake = {
						mason = false,
					},
				},
			}

			-- FIXME: Performance with w/ tsserver freezing the program.
			if not util.is_os_unix then
				user_opts.servers.rome = {
					masone = false,
				}
			end

			return vim.tbl_deep_extend("force", opts, user_opts)
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
