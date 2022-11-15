return {
	-- Overrides it to supress lsp error messages.
	config = function()
		local notify = require("notify")
		notify.setup({
			background_colour = "#000000",
		})
		-- b/c of NvChad, need to override it in lspconfig.
		-- vim.notify = notify
	end,
}
