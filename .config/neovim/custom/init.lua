-- example file i.e lua/custom/init.lua

-- load your globals, autocmds here or anything .__.

local opt = vim.opt
local g = vim.g

-- Jump based on relative line #.
opt.relativenumber = true

-- Column lines.
opt.colorcolumn = { 80, 100, 120 }

-- Show whitespace characters.
opt.listchars = { tab = "->", space = "·", trail = "·" }
opt.list = true
opt.formatoptions = "cq"

local enable_providers = {
	"python3",
	"node",
	"ruby",
}

for _, plugin in pairs(enable_providers) do
	g["loaded_" .. plugin .. "_provider"] = nil
end
