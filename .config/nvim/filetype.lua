local set_file_associations = require("util").set_file_associations

set_file_associations({
	yaml = { "gemrc", os.getenv("BUNDLE_USER_CONFIG") },
	gitconfig = { ".*gitconfig" },
	gitignore = { ".*ignore", ".*/default-pkgs/.*%.list" },
	nginx = { "/etc/nginx/.*/.*%.conf" },
	sshconfig = { ".*/%.ssh/conf%.d/.*%.conf" },
	jsonc = { ".*/%.config/markdownlint/config", ".*/%.vscode/.*%.json" },
	just = { ".*justfile" },
	sh = { "%.env%.local" },
	xdefaults = { ".*/%.config/X11/xresources" },
	i3config = { ".*/i3/conf%.d/.*%.conf" },
	cfg = { "dunstrc" },
})
