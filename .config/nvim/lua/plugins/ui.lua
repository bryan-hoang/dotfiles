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
		event = require("util").get_buf_enter_event_list,
	},
	{
		"nvim-lualine/lualine.nvim",
		event = require("util").get_buf_enter_event_list,
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
		"m4xshen/smartcolumn.nvim",
		enabled = false,
		event = require("util").get_buf_enter_event_list,
		opts = {},
	},
	{
		"folke/noice.nvim",
		-- Disable when `ext_{cmdline,messages}` are enabled by `firenvim`.
		enabled = not vim.g.started_by_firenvim,
	},
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"rcarriga/cmp-dap",
		},
		opts = {
			enabled = function()
				return vim.api.nvim_buf_get_option(0, "buftype") ~= "prompt"
					or require("cmp_dap").is_dap_buffer()
			end,
		},
		config = function(_, opts)
			local cmp = require("cmp")
			cmp.setup(opts)
			cmp.setup.filetype({ "dap-repl", "dapui_watches", "dapui_hover" }, {
				sources = {
					{ name = "dap" },
				},
			})
		end,
	},
}
