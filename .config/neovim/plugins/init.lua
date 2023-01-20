local module = {
	-- Soothing pastel theme for the high-spirited!
	-- ["catppuccin/nvim"] = require("custom.plugins.catppuccin"),
	-- Lua port of the most famous vim colorscheme.
	["ellisonleao/gruvbox.nvim"] = require("custom.plugins.gruvbox"),
	-- Enables EditorConfig support.
	["gpanders/editorconfig.nvim"] = require("custom.plugins.editorconfig"),
	-- Syntax highlighting for Human readable JSON.
	["hjson/vim-hjson"] = require("custom.plugins.hjson"),
	-- Format only changed lines of code (from VCS's POV).
	["joechrisellis/lsp-format-modifications.nvim"] = require(
		"custom.plugins.lsp_format_modifications"
	),
	-- Extend NvChad's built-in lsp-config support by enabling language servers.
	["neovim/nvim-lspconfig"] = require("custom.plugins.lspconfig"),
	-- Customize default items installed.
	["williamboman/mason.nvim"] = require("custom.plugins.mason"),
	-- Enable custom language servers.
	["jose-elias-alvarez/null-ls.nvim"] = require("custom.plugins.null_ls"),
	-- JSON schemas for Neovim.
	["b0o/schemastore.nvim"] = {},
	-- Enable markdown previewing.
	["iamcco/markdown-preview.nvim"] = require("custom.plugins.markdown_preview"),
	-- Adds support for the debug adapter protocol.
	["mfussenegger/nvim-dap"] = require("custom.plugins.dap"),
	-- Manually install debug adapter for JS.
	["mxsdev/nvim-dap-vscode-js"] = require("custom.plugins.dap_vscode_js"),
	-- Debug adapter for Neovim plugins.
	["jbyuki/one-small-step-for-vimkind"] = require("custom.plugins.ossfv"),
	-- Improves editing experience for git conflicts.
	["akinsho/git-conflict.nvim"] = require("custom.plugins.git_conflict"),
	-- The Refactoring library based off the Refactoring book by Martin Fowler.
	["ThePrimeagen/refactoring.nvim"] = require("custom.plugins.refactoring"),
	-- Override NvChad's options to always autoinstall treesitter languages for
	-- sticky headers, and whatnot.
	["nvim-treesitter/nvim-treesitter"] = require("custom.plugins.treesitter"),
	-- Show code context.
	["nvim-treesitter/nvim-treesitter-context"] = require(
		"custom.plugins.treesitter_context"
	),
	-- Enable loading project specific config files.
	["windwp/nvim-projectconfig"] = require("custom.plugins.projectconfig"),
	-- Embed Neovim in Chrome, Firefox, Thunderbird & others.
	["glacambre/firenvim"] = require("custom.plugins.firenvim"),
	--A tree like view for symbols in Neovim using the Language Server Protocol.
	["simrat39/symbols-outline.nvim"] = require("custom.plugins.symbols_outline"),
	-- Override some UI elements.
	["NvChad/ui"] = require("custom.plugins.nvchad_ui"),
	-- Adds a minimap that integrates with treesitter and the built-in LSP.
	["gorbit99/codewindow.nvim"] = require("custom.plugins.codewindow"),
	-- A UI for nvim-dap.
	["rcarriga/nvim-dap-ui"] = require("custom.plugins.dapui"),
	-- Extensible Neovim Scrollbar. Mainly for the gitsigns integration.
	["petertriho/nvim-scrollbar"] = require("custom.plugins.scrollbar"),
	-- Copies the exact file location where the cursor is.
	["diegoulloao/nvim-file-location"] = require("custom.plugins.file_location"),
	-- A fancy, configurable, notification manager for NeoVim.
	["rcarriga/nvim-notify"] = require("custom.plugins.notify"),
	-- Find, Filter, Preview, Pick. All lua, all the time.
	["nvim-telescope/telescope.nvim"] = require("custom.plugins.telescope"),
	-- Make your nvim window separators colorful.
	["nvim-zh/colorful-winsep.nvim"] = require("custom.plugins.colorful_winsep"),
	-- Discord Rich Presence for Neovim.
	["andweeb/presence.nvim"] = require("custom.plugins.presence"),
	-- Single tabpage interface for easily cycling through diffs for all modified
	-- files for any git rev.
	["sindrets/diffview.nvim"] = require("custom.plugins.diffview"),
	-- A duck that waddles arbitrarily in neovim.
	["tamton-aquib/duck.nvim"] = require("custom.plugins.duck"),
	-- Make Vim handle line and column numbers in file names with a minimum of
	-- fuss.
	["wsdjeg/vim-fetch"] = {},
	-- Tools for better development in rust using neovim's builtin lsp.
	["simrat39/rust-tools.nvim"] = require("custom.plugins.rust_tools"),
	-- Vim Just Syntax.
	["NoahTheDuke/vim-just"] = {},
}

local is_os_unix = string.sub(package.config, 1, 1) == "/"

-- Segmentation faults on Windows.
if is_os_unix then
	-- Neovim plugin for silicon in Rust.
	module["krivahtoo/silicon.nvim"] = require("custom.plugins.silicon")
end

return module
