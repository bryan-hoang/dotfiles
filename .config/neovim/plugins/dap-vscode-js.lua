return function()
	require("dap-vscode-js").setup({
		-- Path to vscode-js-debug installation.
		debugger_path = vim.fn.stdpath("data")
			.. "/mason/packages/js-debug-adapter",
		-- Command to use to launch the debug server. Takes precedence over
		-- `node_path` and `debugger_path`.
		-- debugger_cmd = { "js-debug-adapter" },

		-- which adapters to register in nvim-dap
		adapters = { "pwa-node" },
	})
end
