-- custom.plugins.lspconfig
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
	end

	setup_config["on_attach"] = function(client, bufnr)
		on_attach(client, bufnr)

		-- Use the internal formatter rather than the LSP formatter.
		vim.opt.formatexpr = ""
	end

	setup_config["capabilities"] = capabilities

	lspconfig[lsp].setup(setup_config)
end
