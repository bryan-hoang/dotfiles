return {
	requires = {
		"mfussenegger/nvim-dap",
	},
	config = function()
		local dap = require("dap")
		local dapui = require("dapui")
		local UIState = require("dapui.state")

		-- Prevent "Setup called twice" message from appearing when calling
		-- :PackerSync multiple times.
		-- https://github.com/rcarriga/nvim-dap-ui/blob/master/lua/dapui/init.lua#L133
		local ui_state = UIState()
		if not ui_state then
			dapui.setup()
		end

		-- Using nvim-dap events to open and close the windows automatically.
		dap.listeners.after.event_initialized["dapui_config"] = function()
			dapui.open()
		end
		dap.listeners.before.event_terminated["dapui_config"] = function()
			dapui.close()
		end
		dap.listeners.before.event_exited["dapui_config"] = function()
			dapui.close()
		end
	end,
}
