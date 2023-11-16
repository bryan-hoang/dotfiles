local Util = require("lazyvim.util")

return {
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			{
				"nvim-telescope/telescope-live-grep-args.nvim",
				cmd = "Telescope",
			},
		},
		config = function(_, opts)
			local telescope = require("telescope")
			telescope.setup(opts)
			telescope.load_extension("live_grep_args")
		end,
		opts = function(_, opts)
			local lga_actions = require("telescope-live-grep-args.actions")

			return vim.tbl_deep_extend("force", opts, {
				defaults = {
					layout_strategy = "horizontal",
					sorting_strategy = "ascending",
					layout_config = {
						prompt_position = "top",
					},
				},
				extensions = {
					live_grep_args = {
						mappings = {
							i = {
								["<C-k>"] = lga_actions.quote_prompt(),
							},
						},
					},
				},
			})
		end,
		keys = {
			-- Search
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
				"<leader>sb",
				false,
			},
			{
				"<leader>sj",
				"<cmd>Telescope jumplist<cr>",
				desc = "Open jumplist picker",
			},
			{
				"<leader>sR",
				false,
			},
			{
				"<leader>s'",
				"<cmd>Telescope resume<cr>",
				desc = "Open last picker",
			},
			{
				"<leader>sd",
				Util.telescope("diagnostics", {
					bufnr = 0,
				}),
				desc = "Open diagnostic picker (current buffer)",
			},
			{
				"<leader>sD",
				Util.telescope("diagnostics", {
					bufnr = nil,
				}),
				desc = "Open diagnostic picker (all buffers)",
			},
			{
				"<leader>/",
				function()
					require("telescope").extensions.live_grep_args.live_grep_args()
				end,
				desc = "Global search in workspace folder",
			},
			{
				"<leader><space>",
				false,
			},
			{
				"<leader>,",
				false,
			},
			{
				"<leader>fb",
				false,
			},
		},
	},
	{
		"nvim-neo-tree/neo-tree.nvim",
		enabled = false,
	},
	{
		"ThePrimeagen/harpoon",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		lazy = false,
		keys = {
			{
				"<leader>hm",
				"<cmd>lua require('harpoon.mark').add_file()<cr>",
				desc = "Add Harpoon mark",
			},
			{
				"<leader>ht",
				"<cmd>lua require('harpoon.ui').toggle_quick_menu()<cr>",
				desc = "Toggle Harpoon quick menu",
			},
			{
				"<leader>hf",
				"<cmd>lua require('harpoon.ui').nav_file(vim.v.count1)<cr>",
				desc = "Navigate to harpooned file",
			},
		},
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
				-- Fit better on vertically split views.
				height = { min = 4, max = 30 },
				-- Min and max width of the columns
				width = { min = 20, max = 40 },
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
	{
		-- Markdown preview plugin for (neo)vim.
		"iamcco/markdown-preview.nvim",
		config = function()
			vim.cmd([[do FileType]])
			vim.g.mkdp_echo_preview_url = 1
			-- Preview markdown over SSH.
			-- https://github.com/iamcco/markdown-preview.nvim/pull/9
			-- $HOSTNAME would usually be defined per remote machine.
			-- e.g., in ~/.config/shell/extra.
			if os.getenv("SSH_CONNECTION") ~= nil then
				vim.g.mkdp_open_to_the_world = 1
				vim.g.mkdp_open_ip = os.getenv("HOSTNAME")
				vim.g.mkdp_port = 8080
				vim.cmd([[
					function! g:Open_browser(url)
						silent exe "!lemonade open "a:url
					endfunction
					let g:mkdp_browserfunc = "g:Open_browser"
				]])
			end
		end,
	},
	{
		-- A plugin to visualise and resolve merge conflicts in neovim.
		"akinsho/git-conflict.nvim",
		event = require("util").buf_enter_event_list,
		opts = {
			default_mappings = {
				ours = "<Leader>gco",
				theirs = "<Leader>gct",
				none = "<Leader>gcn",
				both = "<Leader>gcb",
				next = "]x",
				prev = "[x",
			},
		},
		config = function(_, opts)
			-- Make it easier to know when conflicts are actually present in a file,
			-- instead of being handled by `git rerere`.
			vim.api.nvim_create_autocmd("User", {
				pattern = "GitConflictDetected",
				callback = function()
					vim.notify("Git merge conflict detected.")
				end,
			})

			-- Fixes a bug where the conflicts arent' fetched at the right time.
			vim.api.nvim_create_autocmd("BufRead", {
				callback = function()
					vim.cmd([[GitConflictRefresh]])
				end,
			})

			require("git-conflict").setup(opts)

			-- Clear distraction background colors, defer to colorscheme.
			vim.api.nvim_set_hl(0, "GitConflictCurrent", {})
			vim.api.nvim_set_hl(0, "GitConflictAncestor", {})
		end,
	},
	{
		"folke/todo-comments.nvim",
		-- https://github.com/folke/todo-comments.nvim#%EF%B8%8F-configuration
		opts = {
			highlight = {
				keyword = "bg",
				pattern = [[.*<(KEYWORDS).*:]],
			},
		},
	},
	{
		"diegoulloao/nvim-file-location",
		keys = {
			{
				"<leader>L",
				"<cmd>lua require('nvim-file-location').copy_file_location('workdir', true, false)<cr>",
				desc = "Copy file location",
			},
		},
		opts = {},
	},
	{
		"pwntester/octo.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			"folke/which-key.nvim",
			-- Breaks keymaps if uncommented.
			-- "nvim-telescope/telescope.nvim",
		},
		cmd = "Octo",
		opts = {},
	},
	{
		"sindrets/diffview.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		cmd = {
			"DiffviewOpen",
			"DiffviewFileHistory",
		},
	},
	{
		-- Work with several variants of a word at once. e.g., search and replacing
		-- variants.
		"tpope/vim-abolish",
		event = require("util").buf_enter_event_list,
	},
	{
		-- Defaults everyone can agree on.
		"tpope/vim-sensible",
		event = require("util").buf_enter_event_list,
	},
	{
		"folke/flash.nvim",
		-- Don't override default `s` keybind.
		enabled = false,
	},
	{
		"echasnovski/mini.files",
		opts = {
			options = {
				-- Whether to use for editing directories.
				-- Disabled by default in LazyVim because `neo-tree` is used for that.
				use_as_default_explorer = true,
			},
		},
	},
	{
		-- 🎈 Floating statuslines for Neovim.
		"b0o/incline.nvim",
		event = "VeryLazy",
		opts = {},
	},
}
