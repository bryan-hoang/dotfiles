return {
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
			if os.getenv("SSH_CONNECTION") ~= nil then
				vim.g.mkdp_open_to_the_world = 1
				-- Where `MDP_HOST` is the machine defined host to connect to.
				vim.g.mkdp_open_ip = os.getenv("MDP_HOST")
				vim.g.mkdp_port = 8080
				vim.cmd([[
					function OpenMarkdownPreview(url)
						execute "silent ! lemonade open " . a:url
					endfunction
				]])
				vim.g.mkdp_browserfunc = "OpenMarkdownPreview"
			end
		end,
	},
	{
		-- A plugin to visualize and resolve merge conflicts in Neovim.
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

			-- Fixes a bug where the conflicts aren't fetched at the right time.
			vim.api.nvim_create_autocmd("BufRead", {
				callback = function()
					vim.cmd([[GitConflictRefresh]])
				end,
			})

			require("git-conflict").setup(opts)

			-- Clear distraction background colors, defer to color scheme.
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
		"folke/flash.nvim",
		-- Don't override default `s` keybinding.
		enabled = false,
	},
	{
		"nvim-mini/mini.files",
		opts = {
			options = {
				-- Whether to use for editing directories.
				-- Disabled by default in LazyVim because `neo-tree` is used for that.
				use_as_default_explorer = true,
			},
		},
	},
	{
		-- A lua Neovim plugin to generate shareable file permanent links (with line
		-- ranges) for several git web frontend hosts. Inspired by
		-- `tpope/vim-fugitive's` `:GBrowse`.
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
	{
		"folke/snacks.nvim",
		keys = {
			{
				-- Helix keybinding for last picker.
				"<leader>s'",
				function()
					require("snacks").picker.resume()
				end,
				desc = "Resume",
			},
		},
		---@type snacks.Config
		opts = {
			gitbrowse = {
				what = "permalink",
				url_patterns = {
					["dev%.azure%.com"] = {
						branch = "?version=GB{branch}",
						file = "?path=/{file}&version=GB{branch}&line={line_start}&lineEnd={line_end}&lineStartColumn=1&lineEndColumn=999",
						permalink = "?path=/{file}&version=GC{commit}&line={line_start}&lineEnd={line_end}&lineStartColumn=1&lineEndColumn=999",
						commit = "/commit/{commit}",
					},
				},
			},
		},
	},
}
