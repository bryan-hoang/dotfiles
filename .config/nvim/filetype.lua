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
	jsonc = { ".*/%.config/markdownlint/config", ".*/%.vscode/.*%.json" },
	just = { ".*justfile" },
	xdefaults = { ".*/%.config/X11/xresources" },
	i3config = { ".*/i3/conf%.d/.*%.conf" },
	cfg = { "dunstrc" },
	starlark = { "Tiltfile" },
	dotenv = { ".*%.env%..*" },
	ruby = { ".*/%.config/pry/pryrc" },
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
