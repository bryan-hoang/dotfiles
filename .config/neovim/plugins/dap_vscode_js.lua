return {
	requires = { "mfussenegger/nvim-dap" },
	config = function()
		local dap_vscode_js = require("dap-vscode-js")
		local dap = require("dap")

		dap_vscode_js.setup({
			-- Path to vscode-js-debug installation.
			debugger_path = vim.fn.stdpath("data")
				.. "/mason/packages/js-debug-adapter",

			-- Which adapters to register in nvim-dap.
			adapters = { "pwa-node" },
		})

		for _, language in ipairs({ "typescript", "javascript" }) do
			dap.configurations[language] = {
				{
					type = "pwa-node",
					request = "launch",
					name = "Launch file",
					program = "${file}",
					cwd = "${workspaceFolder}",
				},
				{
					type = "pwa-node",
					request = "attach",
					name = "Attach to (chosen) process",
					processId = require("dap.utils").pick_process,
					cwd = "${workspaceFolder}",
				},
			}
		end
	end,
}
