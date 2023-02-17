return {
	{
		"rcarriga/nvim-notify",
		-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/plugins/ui.lua#L23
		init = function()
			-- Avoid notification for unset background color for certain color schemes. e.g. gruvbox.
			require("notify").setup({
				background_colour = "#000000",
			})
			-- When noice is not enabled, install notify on VeryLazy
			local Util = require("lazyvim.util")
			if not Util.has("noice.nvim") then
				Util.on_very_lazy(function()
					vim.notify = require("notify")
				end)
			end
		end,
	},
	{
		"nvim-lualine/lualine.nvim",
		opts = function(_, opts)
			local function noeol()
				local eol_indocator = (vim.opt.eol:get() and "" or "[noeol]")
				return eol_indocator
			end

			table.insert(opts.sections.lualine_c, 4, { noeol })
			return opts
		end,
	},
}
