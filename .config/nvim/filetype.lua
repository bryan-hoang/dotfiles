local set_file_associations = require("util").set_file_associations

set_file_associations({
	cfg = { "dunstrc", ".sqlfluff" },
	conf = { ".*/sudoers%.d/.*" },
	dotenv = { ".*%.env%..*" },
	gitconfig = { ".*gitconfig" },
	gitignore = {
		".*ignore",
		".*/default-pkgs/.*%.list",
		".*/%.config/git/order",
	},
	i3config = { ".*/i3/conf%.d/.*%.conf" },
	ini = { ".*/%.config/redshift%.conf" },
	json = { ".*%.vil", ".swcrc" },
	jsonc = { ".*/%.config/markdownlint/config", ".*/%.vscode/.*%.json" },
	just = { ".*justfile" },
	nginx = { "/etc/nginx/.*/.*%.conf" },
	ruby = { ".*/%.config/pry/pryrc" },
	sshconfig = { ".*/%.ssh/conf%.d/.*%.conf" },
	starlark = { "Tiltfile" },
	toml = { "uv.lock" },
	xdefaults = {
		".*/%.config/X11/xresources",
		".*/%.config/X11/xresources%.d/.*",
	},
	yaml = { "gemrc", os.getenv("BUNDLE_USER_CONFIG") },
})

vim.filetype.add({
	extension = {
		mdx = "markdown.mdx",
		cshtml = "razor",
		razor = "razor",
	},
	filename = {
		-- Override detection from distributed files.
		[".env"] = "dotenv",
	},
})
