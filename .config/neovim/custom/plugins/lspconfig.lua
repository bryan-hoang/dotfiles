-- custom.plugins.lspconfig
local on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities

local lspconfig = require("lspconfig")
local servers = {
	"bashls",
	"sumneko_lua",
	"taplo",
	"tsserver",
	"jsonls",
	"yamlls",
}

for _, lsp in ipairs(servers) do
	local setup_config = {
		on_attach = on_attach,
		capabilities = capabilities,
	}

	if lsp ~= "yamlls" then
		setup_config["settings"] = {
			yaml = {
				schemas = {
					["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
					["https://gitlab.com/gitlab-org/gitlab/-/raw/master/app/assets/javascripts/editor/schema/ci.json"] = "/.gitlab-ci.yml",
				},
			},
		}
	end

	lspconfig[lsp].setup(setup_config)
end
