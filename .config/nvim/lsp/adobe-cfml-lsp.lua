local port = os.getenv("ADOBE_CFML_LSP_PORT") or "5003"

return {
	cmd = vim.lsp.rpc.connect("127.0.0.1", tonumber(port)),
	filetypes = { "cf" },
	root_markers = { ".git" },
}
