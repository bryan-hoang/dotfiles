local Util = require("lazyvim.util")

return {
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			{ "nvim-telescope/telescope-live-grep-args.nvim" },
		},
		keys = {
			{
				"<leader>j",
				"<cmd>Telescope jumplist<cr>",
				desc = "Open jumplist picker",
			},
			{
				"<leader>sS",
				-- Work around certain language servers requiring a query.
				-- https://github.com/nvim-telescope/telescope.nvim/issues/568#issuecomment-793748612
				function()
					require("telescope.builtin").lsp_workspace_symbols({
						query = vim.fn.input("Query >"),
					})
				end,
				desc = "Open workspace symbol picker",
			},
			{
				"<leader>'",
				"<cmd>Telescope resume<cr>",
				desc = "Open last picker",
			},
			{
				"<leader>d",
				"<cmd>Telescope diagnostics<cr>",
				desc = "Open diagnostic picker",
			},
			{ "<leader>sg", false },
			{
				"<leader>sG",
				function()
					require("telescope").extensions.live_grep_args.live_grep_args({
						cwd = false,
					})
				end,
				desc = "Grep (cwd)",
			},
			{
				"<leader>/",
				function()
					require("telescope").extensions.live_grep_args.live_grep_args()
				end,
				desc = "Global search in workspace folder",
			},
		},
		opts = {
			defaults = {
				sorting_strategy = "ascending",
				layout_config = {
					prompt_position = "top",
				},
			},
		},
		init = function()
			require("telescope").load_extension("live_grep_args")
		end,
	},
	{
		"nvim-neo-tree/neo-tree.nvim",
		enabled = false,
	},
	{
		"ThePrimeagen/harpoon",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"folke/which-key.nvim",
		},
		-- lazy = true,
		config = function()
			local mark = require("harpoon.mark")
			local ui = require("harpoon.ui")
			local wk = require("which-key")

			wk.register({
				m = { mark.add_file, "Add Harpoon mark" },
				t = { ui.toggle_quick_menu, "Toggle Harpoon quick menu" },
				-- https://github.com/ThePrimeagen/harpoon/issues/125#issuecomment-1138543399
				h = {
					function()
						ui.nav_file(vim.v.count1)
					end,
					"Navigate to harpooned file",
				},
			}, {
				prefix = "<leader>",
			})
		end,
	},
	{
		"mbbill/undotree",
		cmd = "UndotreeToggle",
		keys = {
			{ "<leader>fu", "<cmd>UndotreeToggle<cr>", desc = "Toggle undotree" },
		},
	},
	{
		"tpope/vim-fugitive",
		cmd = "Git",
	},
	{
		"folke/which-key.nvim",
		-- https://github.com/folke/which-key.nvim#%EF%B8%8F-configuration
		opts = {
			plugins = {
				presets = {
					-- Avoid overwriting custom g<> keybindings.
					g = false,
				},
			},
			window = {
				-- Match Helix's 'WhichKey' panel.
				border = "single",
			},
			layout = {
				-- Better fit on vertically split views.
				height = { min = 4, max = 30 },
				width = { min = 20, max = 40 }, -- min and max width of the columns
			},
		},
	},
	{
		"simrat39/symbols-outline.nvim",
		cmd = "SymbolsOutline",
		keys = {
			{ "<leader>cs", "<cmd>SymbolsOutline<cr>", desc = "Symbols Outline" },
		},
		opts = {
			show_numbers = true,
			show_relative_numbers = true,
			auto_preview = true,
			auto_close = true,
		},
	},
	{
		"folke/neodev.nvim",
		ft = "lua",
	},
	{
		"ggandor/leap.nvim",
		enabled = false,
	},
	{
		"ggandor/flit.nvim",
		enabled = false,
	},
}
