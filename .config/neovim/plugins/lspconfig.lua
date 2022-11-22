return {
	requires = { { "nvim-lua/plenary.nvim" } },
	-- To allow overriding `vim.notify` properly.
	after = "nvim-notify",
	config = function()
		require("plugins.configs.lspconfig")

		local on_attach = require("plugins.configs.lspconfig").on_attach
		local capabilities = require("plugins.configs.lspconfig").capabilities
		local lspconfig = require("lspconfig")

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
						schemas = {
							["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
							["https://gitlab.com/gitlab-org/gitlab/-/raw/master/app/assets/javascripts/editor/schema/ci.json"] = "/.gitlab-ci.yml",
						},
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
			end

			setup_config["on_attach"] = on_attach
			setup_config["capabilities"] = capabilities
			lspconfig[lsp].setup(setup_config)
		end

		-- https://github.com/NvChad/NvChad/issues/1519#issuecomment-1230377198
		vim.notify = require("notify")
	end,
}
