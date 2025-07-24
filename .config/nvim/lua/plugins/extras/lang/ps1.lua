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
	{
		"conform.nvim",
		opts = function(_, opts)
			opts.formatters.psscriptanalyzer = {
				command = "pwsh",
				stdin = true,
				args = {
					"-NoProfile",
					"-Command",
					"Invoke-Formatter",
					"-ScriptDefinition",
					"($input | Out-String)",
				},
			}
			opts.formatters_by_ft.ps1 = { "psscriptanalyzer" }
		end,
	},
}
