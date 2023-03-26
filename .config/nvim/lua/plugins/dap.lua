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
		config = function()
			local dap = require("dap")
			local bash_debug_adapter_install_path = os.getenv("GHQ_ROOT")
				.. "/github.com/rogalmic/vscode-bash-debug"
			local bashdb_dir = bash_debug_adapter_install_path .. "/bashdb_dir"

			-- https://github.com/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation#bash
			dap.adapters.bashdb = {
				type = "executable",
				command = "node",
				args = {
					bash_debug_adapter_install_path .. "/out/bashDebug.js",
				},
				name = "bashdb",
			}
			dap.configurations.sh = {
				{
					name = "Launch file",
					type = "bashdb",
					request = "launch",
					program = "${file}",
					cwd = "${workspaceFolder}",
					env = {},
					args = {},
					showDebugOutput = false,
					trace = false,
					pathBashdb = bashdb_dir .. "/bashdb",
					pathBashdbLib = bashdb_dir,
					pathBash = "bash",
					pathCat = "cat",
					pathMkfifo = "mkfifo",
					pathPkill = "pkill",
				},
			}
		end,
	},
	{
		"rcarriga/nvim-dap-ui",
		event = require("util").buf_enter_event_list,
		dependencies = {
			"mfussenegger/nvim-dap",
		},
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
		event = require("util").buf_enter_event_list,
		dependencies = {
			"mfussenegger/nvim-dap",
			"nvim-treesitter/nvim-treesitter",
		},
		opts = {
			all_references = true,
		},
	},
	{
		"nvim-telescope/telescope-dap.nvim",
		event = require("util").buf_enter_event_list,
		dependencies = {
			"mfussenegger/nvim-dap",
			"nvim-telescope/telescope.nvim",
			"nvim-treesitter/nvim-treesitter",
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
		ft = {
			"javascript",
			"typescript",
		},
		config = function()
			local dap_vscode_js = require("dap-vscode-js")
			local dap = require("dap")

			dap_vscode_js.setup({
				-- Path to vscode-js-debug installation.
				debugger_path = os.getenv("GHQ_ROOT")
					.. "/github.com/microsoft/vscode-js-debug",

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
	{
		"mfussenegger/nvim-dap-python",
		ft = "python",
		config = function()
			local dap_python = require("dap-python")
			dap_python.setup(os.getenv("XDG_DATA_HOME") .. "/rtx/shims/python")
		end,
	},
}
