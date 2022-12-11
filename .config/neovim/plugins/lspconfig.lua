return {
	requires = { { "nvim-lua/plenary.nvim" } },
	-- To allow overriding `vim.notify` properly.
	after = "nvim-notify",
	config = function()
		require("plugins.configs.lspconfig")

		local on_attach = require("plugins.configs.lspconfig").on_attach
		local capabilities = require("plugins.configs.lspconfig").capabilities
		local lspconfig = require("lspconfig")

		-- https://github.com/b0o/SchemaStore.nvim/issues/9#issuecomment-1140321123
		local json_schemas = require("schemastore").json.schemas({})
		local yaml_schemas = {}
		vim.tbl_map(function(schema)
			yaml_schemas[schema.url] = schema.fileMatch
		end, json_schemas)

		local servers = {
			"bashls",
			"sumneko_lua",
			"tsserver",
			"cssls",
			"jsonls",
			"yamlls",
			"rome",
			"emmet_ls",
			"powershell_es",
			"html",

			-- TOML
			"taplo",
			-- Markdown
			"ltex",
		}

		for _, lsp in ipairs(servers) do
			local setup_config = {}

			if lsp == "yamlls" then
				setup_config["settings"] = {
					yaml = {
						schemas = yaml_schemas,
					},
				}
			elseif lsp == "sumneko_lua" then
				setup_config["settings"] = {
					Lua = {
						runtime = {
							-- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
							version = "LuaJIT",
						},
						diagnostics = {
							-- Get the language server to recognize the `vim` global
							globals = { "vim" },
						},
						workspace = {
							-- Make the server aware of Neovim runtime files
							library = vim.api.nvim_get_runtime_file("", true),
						},
					},
				}
			elseif lsp == "ltex" then
				setup_config["settings"] = {
					ltex = {
						-- https://github.com/valentjn/ltex-ls/issues/124#issuecomment-973171649
						dictionary = {
							["en-US"] = { "dotfiles", "Neovim", "NvChad" },
						},
					},
				}

				-- Installing ltex-ls through Mason doesn't install the .bat file.local bin_name = 'ltex-ls'
				local bin_name = "ltex-ls"
				if vim.fn.has("win32") == 1 then
					bin_name = bin_name .. ".cmd"
				end
				setup_config["cmd"] = { bin_name }
			elseif lsp == "powershell_es" then
				setup_config["bundle_path"] = vim.fn.stdpath("data")
					.. "/mason/packages/powershell-editor-services"
			elseif lsp == "bashls" then
				setup_config["filetypes"] = { "sh", "zsh" }
			elseif lsp == "jsonls" then
				setup_config["settings"] = {
					json = {
						schemas = json_schemas,
						validate = { enable = true },
					},
				}
			end

			setup_config["on_attach"] = on_attach
			setup_config["capabilities"] = capabilities
			lspconfig[lsp].setup(setup_config)
		end

		-- https://github.com/NvChad/NvChad/issues/1519#issuecomment-1230377198
		vim.notify = require("notify")
	end,
}
