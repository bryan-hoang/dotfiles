local set_file_associations = require("util").set_file_associations

set_file_associations({
	yaml = { "gemrc", os.getenv("BUNDLE_USER_CONFIG") },
	gitconfig = { ".*gitconfig" },
	gitignore = {
		".*ignore",
		".*/default-pkgs/.*%.list",
		".*/%.config/git/order",
	},
	nginx = { "/etc/nginx/.*/.*%.conf" },
	sshconfig = { ".*/%.ssh/conf%.d/.*%.conf" },
	json = { ".*%.vil", ".swcrc" },
	jsonc = { ".*/%.config/markdownlint/config", ".*/%.vscode/.*%.json" },
	just = { ".*justfile" },
	xdefaults = {
		".*/%.config/X11/xresources",
		".*/%.config/X11/xresources%.d/.*",
	},
	i3config = { ".*/i3/conf%.d/.*%.conf" },
	cfg = { "dunstrc" },
	starlark = { "Tiltfile" },
	dotenv = { ".*%.env%..*" },
	ruby = { ".*/%.config/pry/pryrc" },
	ini = { ".*/%.config/redshift%.conf" },
	toml = { "uv.lock" },
	conf = { ".*/sudoers%.d/.*" },
})

vim.filetype.add({
	extension = {
		mdx = "markdown.mdx",
	},
	filename = {
		-- Override detection from distributed files.
		[".env"] = "dotenv",
	},
})
