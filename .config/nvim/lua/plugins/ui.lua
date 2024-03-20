return {
	{
		"rcarriga/nvim-notify",
		opts = {
			background_colour = "#000000",
		},
		config = function(_, opts)
			require("notify").setup(opts)
			require("telescope").load_extension("notify")
		end,
	},
	{
		"akinsho/bufferline.nvim",
		event = require("util").buf_enter_event_list,
	},
	{
		"nvim-lualine/lualine.nvim",
		event = require("util").buf_enter_event_list,
		opts = function(_, opts)
			local function noeol()
				local eol_indocator = (vim.opt.eol:get() and "" or "[noeol]")
				return eol_indocator
			end

			table.insert(opts.sections.lualine_c, 4, { noeol })
			return opts
		end,
	},
	{
		"folke/noice.nvim",
		-- Disable when `ext_{cmdline,messages}` are enabled by `firenvim`.
		enabled = not vim.g.started_by_firenvim,
		opts = {
			lsp = {
				hover = {
					-- Don't show a message if hover is not available. Helpful if multiple
					-- LSP's are attached, but only some have info on the symbol to hover.
					silent = true,
				},
			},
		},
	},
	{
		"folke/twilight.nvim",
	},
	{
		"folke/zen-mode.nvim",
		dependencies = { "folke/twilight.nvim" },
		cmd = "ZenMode",
		opts = {
			tmux = { enabled = true },
		},
		keys = {
			{ "<Leader>uz", "<Cmd>ZenMode<CR>", desc = "Toggle Zen Mode" },
		},
	},
	{
		"nvimdev/dashboard-nvim",
		enabled = false,
	},
	{
		-- 🎈 Floating statuslines for Neovim.
		"b0o/incline.nvim",
		event = "VeryLazy",
		opts = {
			window = {
				placement = {
					vertical = "bottom",
				},
			},
		},
	},
	{
		-- Cloak allows you to overlay *'s over defined patterns in defined files.
		"laytan/cloak.nvim",
		ft = "dotenv",
		keys = {
			{ "<Leader>ux", "<Cmd>CloakToggle<CR>", desc = "Toggle clocking state" },
		},
		opts = {},
	},
}
