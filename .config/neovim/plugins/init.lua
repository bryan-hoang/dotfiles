return {
	-- Creates missing folders on save.
	["jghauser/mkdir.nvim"] = {},
	-- Enables EditorConfig support.
	["gpanders/editorconfig.nvim"] = {},
	-- It's helpful sometimes :D
	["github/copilot.vim"] = {},
	-- Syntax highlighting for Human readable JSON.
	["hjson/vim-hjson"] = {},
	-- Extend NvChad's built-in lsp-config support by enabling language servers.
	["neovim/nvim-lspconfig"] = {
		config = function()
			require("plugins.configs.lspconfig")
			require("custom.plugins.lspconfig")
		end,
	},
	-- Customize default items installed.
	["williamboman/mason.nvim"] = require("custom.plugins.mason"),
	-- Enable custom language servers
	["jose-elias-alvarez/null-ls.nvim"] = {
		after = "nvim-lspconfig",
		config = function()
			require("custom.plugins.null-ls")
		end,
	},
	-- Enable markdown previewing.
	["iamcco/markdown-preview.nvim"] = {
		run = function()
			vim.fn["mkdp#util#install"]()
		end,
		-- Preview markdown over SSH.
		config = require("custom.plugins.markdown-preview"),
	},
	-- Adds support for the debug adapter protocol.
	["mfussenegger/nvim-dap"] = {
		config = require("custom.plugins.dap"),
	},
	-- Manually install debug adapter for JS.
	["mxsdev/nvim-dap-vscode-js"] = {
		requires = { "mfussenegger/nvim-dap" },
		config = require("custom.plugins.dap-vscode-js"),
	},
	-- Improves editing experience for git conflicts.
	["akinsho/git-conflict.nvim"] = {
		tag = "*",
		config = require("custom.plugins.git-conflict"),
	},
	-- Debug adapter for Neovim plugins.
	["jbyuki/one-small-step-for-vimkind"] = {
		config = require("custom.plugins.ossfv"),
	},
	-- The Refactoring library based off the Refactoring book by Martin Fowler.
	["ThePrimeagen/refactoring.nvim"] = {
		requires = {
			{ "nvim-lua/plenary.nvim" },
			{ "nvim-treesitter/nvim-treesitter" },
		},
		config = function()
			require("refactoring").setup()
		end,
	},
	-- Override NvChad's options to always autoinstall treesitter languages for
	-- sticky headers, and whatnot.
	["nvim-treesitter/nvim-treesitter"] = {
		override_options = {
			auto_install = true,
		},
	},
	["nvim-treesitter/nvim-treesitter-context"] = {
		config = function()
			require("treesitter-context").setup({})
		end,
	},
	-- Enable loading project specific config files.
	["windwp/nvim-projectconfig"] = {
		config = function()
			require("nvim-projectconfig").setup({
				-- Set the project directory to the custom path to use personal
				-- utilities.
				project_dir = vim.env.XDG_CONFIG_HOME .. "/neovim/projects/",

				-- Display message after load config file.
				silent = false,

				-- Change directory inside neovim and load project config.
				autocmd = true,
			})
		end,
	},
	-- Format only changed lines of code (from VCS's POV).
	["joechrisellis/lsp-format-modifications.nvim"] = {},
	-- Embed Neovim in Chrome, Firefox, Thunderbird & others.
	["glacambre/firenvim"] = require("custom.plugins.firenvim"),
	-- GhostText plugin to sync editor test with text in the browser.
	-- Experimenting with improving MR review workflow.
	["subnut/nvim-ghost.nvim"] = require("custom.plugins.ghost"),
	--A tree like view for symbols in Neovim using the Language Server Protocol.
	["simrat39/symbols-outline.nvim"] = require("custom.plugins.symbols-outline"),
	-- Override some UI elements.
	["NvChad/ui"] = {
		override_options = {
			statusline = {
				overriden_modules = function()
					return require("custom.plugins.nvchad_ui")
				end,
			},
		},
	},
}
