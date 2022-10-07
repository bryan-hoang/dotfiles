local M = {}

M.lspconfig = {
	n = {
		["<leader>fm"] = {
			function()
				vim.lsp.buf.format({
					async = true,
				})
			end,
			"lsp formatting",
		},
	},
}

return M
