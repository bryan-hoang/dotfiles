return {
	-- Creates missing folders on save.
	["jghauser/mkdir.nvim"] = {},
	-- Try to auto detect indentation settings from the file.
	["tpope/vim-sleuth"] = {},
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
	["williamboman/mason.nvim"] = {
		override_options = {
			ensure_installed = {
				-- lua stuff
				"lua-language-server",
				"stylua",
				"selene",

				-- web dev
				"prettier",
				"css-lsp",
				"html-lsp",
				"typescript-language-server",
				"deno",
				"emmet-ls",
				"yaml-language-server",
				"rome",

				-- shell
				"shfmt",
				"shellcheck",
				"bash-language-server",
				"shellharden",

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
	["akinsho/git-conflict.nvim"] = {
		tag = "*",
		config = function()
			require("git-conflict").setup({
				default_mappings = false,
				highlights = {
					incoming = "DiffText",
					current = "DiffAdd",
				},
			})
		end,

		vim.api.nvim_create_autocmd("User", {
			pattern = "GitConflictDetected",
			callback = function()
				vim.notify("Conflict detected in " .. vim.fn.expand("<afile>"))
				vim.keymap.set("n", "cww", function()
					engage.conflict_buster()
					create_buffer_local_mappings()
				end)
			end,
		}),
	},
	-- Debug adapter for Neovim plugins.
	["jbyuki/one-small-step-for-vimkind"] = {
		config = function()
			local dap = require("dap")
			dap.configurations.lua = {
				{
					type = "nlua",
					request = "attach",
					name = "Attach to running Neovim instance",
				},
			}

			dap.adapters.nlua = function(callback, config)
				callback({
					type = "server",
					host = config.host or "127.0.0.1",
					port = config.port or 8086,
				})
			end
		end,
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
	["glacambre/firenvim"] = {
		run = function()
			vim.fn["firenvim#install"](0)
		end,
		config = function()
			-- Make editing comments on GitHub/GitLab easier.
			vim.api.nvim_create_autocmd({ "BufEnter" }, {
				pattern = { "gitlab.com_*.txt", "github.com_*.txt" },
				command = "set filetype=markdown",
			})
		end,
	},
}
