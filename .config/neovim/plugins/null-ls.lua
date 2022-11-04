local present, null_ls = pcall(require, "null-ls")

if not present then
	return
end

local b = null_ls.builtins
local sources = {
	b.diagnostics.editorconfig_checker.with({
		command = "editorconfig-checker",
	}),

	-- Code actions
	b.code_actions.gitsigns,
	b.code_actions.shellcheck,
	b.code_actions.refactoring,
	b.code_actions.gitrebase,
	b.code_actions.eslint,

	-- JS/TS
	b.formatting.rome,
	b.formatting.deno_fmt,
	b.formatting.prettier,
	b.formatting.eslint,
	b.diagnostics.eslint,

	-- Lua
	b.diagnostics.selene.with({
		-- https://github.com/Kampfkarren/selene/issues/339#issuecomment-1191992366
		cwd = function(_params)
			return vim.fs.dirname(
				vim.fs.find(
					{ "selene.toml" },
					{ upward = true, path = vim.api.nvim_buf_get_name(0) }
				)[1]
				-- fallback value
			) or vim.fn.expand(os.getenv("XDG_CONFIG_HOME") .. "/selene/")
		end,
	}),
	b.formatting.stylua,

	-- Shell
	b.formatting.shfmt.with({
		extra_args = { "-ci", "-bn" },
	}),
	b.formatting.shellharden,

	-- TOML
	b.formatting.taplo,

	-- Markdown
	b.diagnostics.markdownlint,
	b.diagnostics.vale,
}

null_ls.setup({
	sources = sources,
	on_attach = function(client, bufnr)
		local lsp_format_modifications = require("lsp-format-modifications")
		lsp_format_modifications.attach(client, bufnr, { format_on_save = false })
	end,
})
