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
				Util.pick("diagnostics", {
					bufnr = 0,
				}),
				desc = "Open diagnostic picker (current buffer)",
			},
			{
				"<leader>sD",
				Util.pick("diagnostics", {
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
		---@class wk.Opts
		opts = {
			---@type false | "classic" | "modern" | "helix"
			preset = "helix",
			plugins = {
				presets = {
					-- Avoid overwriting custom g<> keybindings.
					g = false,
				},
			},
		},
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
		-- A lua neovim plugin to generate shareable file permalinks (with line
		-- ranges) for several git web frontend hosts. Inspired by
		-- tpope/vim-fugitive's `:GBrowse`.
		"ruifm/gitlinker.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		keys = {
			{
				"<Leader>gy",
				"<Cmd>lua require('gitlinker').get_buf_range_url('n')<CR>",
				mode = { "n", "v" },
				desc = "Generate shareable permalink",
			},
		},
		opts = {
			mappings = nil,
		},
	},
	{
		"brenoprata10/nvim-highlight-colors",
		ft = {
			"css",
		},
		opts = {},
	},
}
