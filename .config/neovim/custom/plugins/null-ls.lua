local present, null_ls = pcall(require, "null-ls")

if not present then
	return
end

local b = null_ls.builtins
local sources = {

	-- Webdev stuff
	b.formatting.deno_fmt,
	b.formatting.prettier,

	-- Lua
	b.formatting.stylua,

	-- Shell
	b.formatting.shfmt.with({
		extra_args = { "-ci", "-bn" },
	}),
	b.diagnostics.shellcheck.with({ diagnostics_format = "#{m} [#{c}]" }),

	-- TOML
	b.formatting.taplo,

	-- Markdown
	b.diagnostics.markdownlint,
	b.diagnostics.vale,
}

null_ls.setup({
	debug = true,
	sources = sources,
})
