return {
	{
		"mfussenegger/nvim-dap",
		lazy = true,
		keys = {
			{
				"<leader>gb",
				"<cmd>lua require('dap').toggle_breakpoint()<cr>",
				desc = "Toggle breakpoint",
			},
		},
	},
	{
		"jay-babu/mason-nvim-dap.nvim",
		dependencies = {
			"williamboman/mason.nvim",
			"mfussenegger/nvim-dap",
		},
		opts = {
			ensure_installed = { "python" },
		},
	},
	{
		"rcarriga/nvim-dap-ui",
		dependencies = {
			"mfussenegger/nvim-dap",
		},
		config = function()
			local dap, dapui = require("dap"), require("dapui")
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
	},
	{
		"theHamsta/nvim-dap-virtual-text",
		dependencies = {
			"mfussenegger/nvim-dap",
			"nvim-treesitter/nvim-treesitter",
		},
	},
	{
		"nvim-telescope/telescope-dap.nvim",
		dependencies = {
			"mfussenegger/nvim-dap",
			"nvim-treesitter/nvim-treesitter",
			"nvim-telescope/telescope.nvim",
		},
		config = function()
			require("telescope").load_extension("dap")
		end,
	},
	{
		"mxsdev/nvim-dap-vscode-js",
		dependencies = {
			"mfussenegger/nvim-dap",
		},
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
	},
}
