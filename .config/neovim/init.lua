local set_file_associations = require('custom.utils').set_file_associations

-- load your globals, autocmds here or anything .__.

local opt = vim.opt
local g = vim.g
local api = vim.api

local enable_providers = {
	"python3",
	"node",
	"ruby",
}

for _, plugin in pairs(enable_providers) do
	g["loaded_" .. plugin .. "_provider"] = nil
end

-- Jump based on relative line #.
opt.relativenumber = true

-- Column lines.
opt.colorcolumn = { 80, 100, 120 }

-- Indent wrapped lines using same indentation as parent.
opt.formatoptions:remove("t")
opt.formatoptions:append("c")
opt.formatoptions:append("r")
opt.formatoptions:append("o")
opt.formatoptions:append("/")
opt.formatoptions:append("q")
opt.formatoptions:append("n")
opt.formatoptions:append("j")
opt.breakindent = true
opt.linebreak = true
opt.showbreak = "↪ "

-- Show whitespace characters.
opt.listchars = { tab = "->", space = "·", trail = "·" }
opt.list = true

-- https://vim.fandom.com/wiki/Learn_to_use_help#Comments
opt.wildmode = { "longest:full", "full" }
opt.completeopt = { "longest", "menuone" }

-- API calls.

set_file_associations({
	["yaml"] = { "gemrc" },
})
