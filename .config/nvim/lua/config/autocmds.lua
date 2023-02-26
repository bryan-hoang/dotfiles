-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

local set_file_associations = require("util").set_file_associations

set_file_associations({
	["yaml"] = { "gemrc" },
	["gitconfig"] = { "*gitconfig" },
	["gitignore"] = { "*ignore" },
	["nginx"] = { "/etc/nginx/**/*.conf" },
	["sshconfig"] = { "**/.ssh/conf.d/*.conf" },
	["jsonc"] = { "**/.config/markdownlint/config" },
})
