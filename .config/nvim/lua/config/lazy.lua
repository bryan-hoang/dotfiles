local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	-- bootstrap lazy.nvim
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(vim.env.LAZY or lazypath)

-- https://github.com/folke/lazy.nvim#%EF%B8%8F-configuration
require("lazy").setup({
	spec = {
		-- Add LazyVim and import its plugins.
		{ "LazyVim/LazyVim", import = "lazyvim.plugins" },
		-- Import any extras modules here.
		-- { import = "lazyvim.plugins.extras.dap.core" },
		-- { import = "lazyvim.plugins.extras.dap.nlua" },
		-- { import = "lazyvim.plugins.extras.test.core" },
		{ import = "lazyvim.plugins.extras.lang.json" },
		{ import = "lazyvim.plugins.extras.lang.yaml" },
		{ import = "lazyvim.plugins.extras.lang.typescript" },
		{ import = "lazyvim.plugins.extras.lang.docker" },
		{ import = "lazyvim.plugins.extras.lang.markdown" },
		-- { import = "lazyvim.plugins.extras.lang.rust" },
		-- { import = "lazyvim.plugins.extras.lang.clangd" },
		-- { import = "lazyvim.plugins.extras.lang.cmake" },
		-- { import = "lazyvim.plugins.extras.lang.tex" },
		{ import = "lazyvim.plugins.extras.util.dot" },
		{ import = "lazyvim.plugins.extras.vscode" },
		{ import = "lazyvim.plugins.extras.editor.navic" },
		{ import = "lazyvim.plugins.extras.linting.eslint" },
		{ import = "lazyvim.plugins.extras.lsp.none-ls" },
		-- Import/override with your plugins.
		{ import = "plugins" },
	},
	defaults = {
		-- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
		-- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
		lazy = true,
		-- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
		-- have outdated releases, which may break your Neovim install.
		version = false, -- always use the latest git commit
		-- version = "*", -- try installing the latest stable version for plugins that support semver
	},
	install = {
		-- Try to load one of these colorschemes when starting an installation
		-- during startup.
		colorscheme = { "tokyonight" },
	},
	checker = {
		-- Automatically check for plugin updates.
		enabled = true,
		-- Get a notification when new updates are found.
		notify = true,
		-- Seconds
		frequency = 24 * 3600,
	},
	performance = {
		rtp = {
			-- disable some rtp plugins
			disabled_plugins = {
				"gzip",
				-- "matchit",
				-- "matchparen",
				-- "netrwPlugin",
				"tarPlugin",
				"tohtml",
				"tutor",
				"zipPlugin",
			},
		},
	},
})
