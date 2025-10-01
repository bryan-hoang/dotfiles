return {
	{
		"snacks.nvim",
		opts = {
			-- The scroll animation is too distracting.
			scroll = { enabled = false },
			indent = {
				chunk = {
					enabled = true,
				},
			},
		},
	},
	{
		"nvim-lualine/lualine.nvim",
		opts = function(_, opts)
			local function noeol()
				local eol_indocator = (vim.opt.eol:get() and "" or "[noeol]")
				return eol_indocator
			end
			table.insert(opts.sections.lualine_c, 4, { noeol })

			local lint_progress = function()
				local linters = require("lint").get_running()
				if #linters == 0 then
					return "󰦕"
				end
				return "󱉶 " .. table.concat(linters, ", ")
			end
			table.insert(opts.sections.lualine_x, 1, { lint_progress })

			return opts
		end,
	},
	{
		"folke/noice.nvim",
		-- Disable when `ext_{cmdline,messages}` are enabled by `firenvim`.
		cond = not vim.g.started_by_firenvim
			and not vim.g.neovide
			and not vim.g.vscode,
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
		-- 🎈 Floating status lines for Neovim.
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
		-- Cloak allows you to overlay asterisks over defined patterns in defined files.
		"laytan/cloak.nvim",
		ft = { "dotenv", "json" },
		keys = {
			{ "<Leader>ux", "<Cmd>CloakToggle<CR>", desc = "Toggle clocking state" },
		},
		opts = {
			patterns = {
				{
					file_pattern = "*secret*.json",
					cloak_pattern = ":.+",
				},
			},
		},
	},
}
