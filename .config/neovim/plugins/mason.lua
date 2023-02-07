return {
	-- Ensure certain tools are always installed during intial
	-- setup/`:MasonInstallAll`.
	override_options = {
		ensure_installed = {
			"editorconfig-checker",
			"powershell-editor-services",
			-- Lua
			"lua-language-server",
			"stylua",
			"selene",
			-- JS/TS, HTML, CSS
			"typescript-language-server",
			"css-lsp",
			"html-lsp",
			"emmet-ls",
			"yaml-language-server",
			"deno",
			"rome",
			"prettier",
			-- Shell
			"bash-language-server",
			"shellcheck",
			"shellharden",
			"shfmt",
			-- Markdown
			"ltex-ls",
			"vale",
			"markdownlint",
			"marksman",
			-- DAPs.
			"js-debug-adapter",
			"bash-debug-adapter",
			-- Python
			"ruff",
			-- Docker
			"dockerfile-language-server",
			"hadolint",
			-- Ruby
			"rubocop",
			-- Rust
			"rust-analyzer",
		},
	},
}
