return {
	cmd = { "Dap*" },
	config = function()
		local dap = require("dap")

		-- Set up bashdb. Sources:
		-- https://github.com/williamboman/mason.nvim/discussions/539
		-- https://github.com/williamboman/mason.nvim/issues/578

		-- Hardcoding the path since resolving it using the `mason-core.package`
		-- module lead to some issues.
		local bash_debug_adapter_install_path = vim.fn.stdpath("data")
			.. "/mason/packages/bash-debug-adapter"
		local bashdb_dir = bash_debug_adapter_install_path
			.. "/extension"
			.. "/bashdb_dir"

		dap.adapters.sh = {
			type = "executable",
			command = "bash-debug-adapter",
		}

		dap.configurations.sh = {
			{
				name = "Launch bash debugger",
				type = "sh",
				request = "launch",
				program = "${file}",
				cwd = "${fileDirname}",
				pathBashdb = bashdb_dir .. "/bashdb",
				pathBashdbLib = bashdb_dir,
				pathBash = "bash",
				pathCat = "cat",
				pathMkfifo = "mkfifo",
				pathPkill = "pkill",
				env = {},
				args = {},
				showDebugOutput = false,
				trace = false,
			},
		}
	end,
}
