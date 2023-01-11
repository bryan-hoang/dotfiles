return {
	after = "nvim-lspconfig",
	config = function()
		local rt = require("rust-tools")
		local on_attach = require("plugins.configs.lspconfig").on_attach

		rt.setup({
			server = {
				on_attach = on_attach,
			},
		})
	end,
}
