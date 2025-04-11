-- https://myriad-dreamin.github.io/tinymist/frontend/neovim.html
-- https://github.com/Myriad-Dreamin/tinymist/blob/main/editors/neovim/plugins/tinymist.lua
return {
	-- requires tinymist
	{
		"williamboman/mason.nvim",
		opts = {
			ensure_installed = {
				"tinymist",
			},
		},
	},
	-- add tinymist to lspconfig
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"mason.nvim",
			"williamboman/mason-lspconfig.nvim",
		},
		---@class PluginLspOpts
		opts = {
			---@type lspconfig.options
			servers = {
				tinymist = {
					--- todo: these configuration from lspconfig maybe broken
					single_file_support = true,
					root_dir = function()
						return vim.fn.getcwd()
					end,
					--- See [Tinymist Server Configuration](https://github.com/Myriad-Dreamin/tinymist/blob/main/Configuration.md) for references.
					settings = {
						formatterMode = "typstyle",
					},
				},
			},
		},
	},
	{
		"chomosuke/typst-preview.nvim",
		cmd = { "TypstPreviewToggle", "TypstPreview", "TypstPreviewStop" },
		version = "1.*",
		keys = {
			{
				"<leader>cp",
				ft = "typst",
				"<cmd>TypstPreviewToggle<cr>",
				desc = "Typst Preview",
			},
		},
		opts = function(_, opts)
			if os.getenv("SSH_CONNECTION") ~= nil then
				opts.open_cmd = "lemonade open %s"
			else
				-- NOTE: Should set `WM_CLASS` to 'doc-prvw'.
				opts.open_cmd = "firefox-devedition -P doc-prvw --class doc-prvw %s"
			end
		end,
	},
}
