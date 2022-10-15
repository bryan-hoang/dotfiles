local M = {}

M.disabled = {
	n = {
		["<C-s>"] = "",
	},
}

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

local markdown_preview = {
	["<C-p>"] = {
		"<Plug>MarkdownPreviewToggle",
		"Toggle Markdown preview",
	},
}

M.markdown_preview = {
	n = markdown_preview,
	i = markdown_preview,
}

return M
