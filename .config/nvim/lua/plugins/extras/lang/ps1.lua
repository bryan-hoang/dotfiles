return {
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				powershell_es = {},
			},
		},
	},
	{
		"TheLeoP/powershell.nvim",
		---@type powershell.user_config
		opts = {
			bundle_path = vim.fn.stdpath("data")
				.. "/mason/packages/powershell-editor-services",
		},
	},
}
