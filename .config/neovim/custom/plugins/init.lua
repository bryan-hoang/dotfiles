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
				"yaml-language-server",

				-- shell
				"shfmt",
				"shellcheck",
				"bash-language-server",

				-- Markdown
				"vale",
				"ltex-ls",
				"markdownlint",

				-- DAPs.
				"js-debug-adapter",
				"bash-debug-adapter",
			},
		},
	},
	["jose-elias-alvarez/null-ls.nvim"] = {
		after = "nvim-lspconfig",
		config = function()
			require("custom.plugins.null-ls")
		end,
	},
	["iamcco/markdown-preview.nvim"] = {
		run = function()
			vim.fn["mkdp#util#install"]()
		end,
	},
	["mxsdev/nvim-dap-vscode-js"] = {
		requires = { "mfussenegger/nvim-dap" },
		config = function()
			require("dap-vscode-js").setup({
				-- Path to vscode-js-debug installation.
				debugger_path = vim.fn.stdpath("data")
					.. "/mason/packages/js-debug-adapter",
				-- debugger_cmd = { "js-debug-adapter" }, -- Command to use to launch the debug server. Takes precedence over `node_path` and `debugger_path`.

				-- which adapters to register in nvim-dap
				adapters = { "pwa-node" },
			})
		end,
	},
	["mfussenegger/nvim-dap"] = {
		config = function()
			for _, language in ipairs({ "typescript", "javascript" }) do
				require("dap").configurations[language] = {
					{
						type = "pwa-node",
						request = "launch",
						name = "Launch file",
						program = "${file}",
						cwd = "${workspaceFolder}",
					},
				}
			end
		end,
	},
}
