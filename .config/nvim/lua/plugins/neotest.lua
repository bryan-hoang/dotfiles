return {
	{
		"nvim-neotest/neotest",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
			"antoinemadec/FixCursorHold.nvim",
			"haydenmeade/neotest-jest",
			"rouge8/neotest-rust",
		},
		keys = {
			{
				"<Leader>tn",
				function()
					require("neotest").run.run()
				end,
				desc = "Run the nearest test",
			},
			{
				"<Leader>tf",
				function()
					require("neotest").run.run(vim.fn.expand("%"))
				end,
				desc = "Run the current file's tests",
			},
			{
				"<Leader>td",
				function()
					require("neotest").run.run({ strategy = "dap" })
				end,
				desc = "Debug the nearest test",
			},
		},
		config = function()
			return {
				adapters = {
					require("neotest-jest")({
						jestCommand = "pnpm test --",
						jestConfigFile = "jest.config.js",
						cwd = function()
							return vim.fn.getcwd()
						end,
					}),
					require("neotest-rust")({
						args = {},
					}),
				},
			}
		end,
	},
}
