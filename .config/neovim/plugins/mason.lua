return {
	-- Ensure certain tools are always installed during intial
	-- setup/`:MasonInstallAll`.
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
}
