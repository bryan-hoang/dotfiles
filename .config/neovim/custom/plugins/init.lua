return {
	["glacambre/firenvim"] = {
		run = function()
			vim.fn["firenvim#install"](0)
		end,
	},
	-- Creates missing folders on save.
	["jghauser/mkdir.nvim"] = {},
	["tpope/vim-sleuth"] = {},
	["github/copilot.vim"] = {},
	["neoclide/coc.nvim"] = {
		branch = "release",
	},
	["hjson/vim-hjson"] = {},
	["neovim/nvim-lspconfig"] = {
		config = function()
			require("plugins.configs.lspconfig")
			require("custom.plugins.lspconfig")
		end,
	},
	["williamboman/mason.nvim"] = {
		override_options = {
			ensure_installed = {
				-- lua stuff
				"lua-language-server",
				"stylua",

				-- web dev
				"prettier",
				"css-lsp",
				"html-lsp",
				"typescript-language-server",
				"deno",
				"emmet-ls",

				-- shell
				"shfmt",
				"shellcheck",
				"bash-language-server",

				-- TOML
				"taplo",
			},
		},
	},
	["jose-elias-alvarez/null-ls.nvim"] = {
		after = "nvim-lspconfig",
		config = function()
			require("custom.plugins.null-ls")
		end,
	},
}
