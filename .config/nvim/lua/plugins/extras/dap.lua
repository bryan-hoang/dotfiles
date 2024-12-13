return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			{
				"Weissle/persistent-breakpoints.nvim",
				opts = {
					load_breakpoints_event = { "BufReadPost" },
				},
			},
		},
		keys = {
			{
				"<leader>gb",
				"<cmd>PBToggleBreakpoint<cr>",
				desc = "Toggle breakpoint",
			},
			{
				"<leader>gl",
				"<cmd>DapContinue<cr>",
				desc = "Launch debug target",
			},
			{
				"<leader>gt",
				"<cmd>DapTerminate<cr>",
				desc = "Terminate debug session",
			},
			{
				"<leader>gi",
				"<cmd>DapStepInto<cr>",
				desc = "Step in",
			},
			{
				"<leader>go",
				"<cmd>DapStepOut<cr>",
				desc = "Step out",
			},
			{
				"<leader>gn",
				"<cmd>DapStepOver<cr>",
				desc = "Step over",
			},
		},
	},
	{
		"rcarriga/nvim-dap-ui",
		config = function(_, opts)
			local dap, dapui = require("dap"), require("dapui")

			dapui.setup(opts)
			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated["dapui_config"] = function()
				dapui.close()
			end
			dap.listeners.before.event_exited["dapui_config"] = function()
				dapui.close()
			end
			-- https://github.com/rcarriga/nvim-dap-ui/issues/147#issuecomment-1297126808
			dap.listeners.before.disconnect["dapui_config"] = function()
				dapui.close()
			end
		end,
	},
	{
		"theHamsta/nvim-dap-virtual-text",
		opts = {
			all_references = true,
		},
	},
}
