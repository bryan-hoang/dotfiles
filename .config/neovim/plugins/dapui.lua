-- Prevent "Setup called twice" message from appearing when calling
-- :PackerSync multiple times.
-- https://github.com/rcarriga/nvim-dap-ui/blob/master/lua/dapui/init.lua#L133
local has_setup_been_called = false

return {
	after = "nvim-dap",
	config = function()
		local dapui = require("dapui")
		local dap = require("dap")

		if not has_setup_been_called then
			dapui.setup()
			has_setup_been_called = true
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
