-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

require("config.editorconfig")

local util = require("util")

local opt = vim.opt
local g = vim.g

-- Avoid https://github.com/neovim/neovim/issues/14605
if not util.is_os_unix and string.match(opt.shell:get(), "bash%.exe") then
	opt.shellcmdflag = "-c"
end

local enable_providers = {
	"python3",
	"node",
	"ruby",
}

for _, plugin in pairs(enable_providers) do
	g["loaded_" .. plugin .. "_provider"] = nil
end

-- Configure Netrw to be a little more sane.
g.netrw_banner = 0
g.netrw_winsize = 16
g.netrw_liststyle = 3
-- g.netrw_browse_split = 4
-- Open previews vertically.
-- g.netrw_preview = 1

-- Always use lemonade as the clipboard program, to avoid issues with
-- `x{sel,clip}` taking precedence over lemonade.
if vim.fn.executable("lemonade") == 1 then
	g.clipboard = {
		name = "lemonade",
		copy = {
			["+"] = { "lemonade", "copy" },
			["*"] = { "lemonade", "copy" },
		},
		paste = {
			["+"] = { "lemonade", "paste" },
			["*"] = { "lemonade", "paste" },
		},
	}
end

-- Jump based on relative line #.
opt.relativenumber = true

-- Textwidth for hard wrapping. I want to encourage writing short lines of
-- code. For long lines of code, use J where needed.
opt.tw = 80

-- Enable line wrap.
opt.wrap = true

-- Use default wrapping behaviour for diff windows.
opt.diffopt:append("followwrap")

-- Auto-wrap text using 'textwidth'.
opt.formatoptions:remove("t")
-- Auto-wrap comments using 'textwidth', inserting the current comment leader
-- automatically.
opt.formatoptions:append("c")
-- Automatically insert the current comment leader after hitting <Enter> in
-- Insert mode.
opt.formatoptions:append("r")
-- Automatically insert the current comment leader after hitting 'o' or 'O' in
-- Normal mode.  In case comment is unwanted in a specific place use CTRL-U to
-- quickly delete it. |i_CTRL-U|
opt.formatoptions:append("o")
-- When 'o' is included: do not insert the comment leader for a // comment after
-- a statement, only when // is at the start of the line.
opt.formatoptions:append("/")
-- Allow formatting of comments with "gq". Note that formatting will not change
-- blank lines or lines containing only the comment leader. A new paragraph
-- starts after such a line, or when the comment leader changes.
opt.formatoptions:append("q")
-- Automatic formatting of paragraphs. Every time text is inserted or deleted
-- the paragraph will be reformatted. See |auto-format|. When the 'c' flag is
-- present this only happens for recognized comments.
--
-- Removing since there are a few situations where it's unwanted. e.g., JS
-- comments, markdown code blocks, etc.
opt.formatoptions:remove("a")
-- When formatting text, recognize numbered lists.
opt.formatoptions:append("n")
-- When formatting text, use the indent of the second line of a paragraph for
-- the rest of the paragraph, instead of the indent of the first line.
opt.formatoptions:append("2")

-- Where it makes sense, remove a comment leader when joining lines.
-- opt.formatoptions:append("j")

opt.breakindent = true
opt.linebreak = true
opt.showbreak = "↪ "
opt.exrc = true

-- Show certain whitespace characters. Don't show all space characters,
-- otherwise messes with wezterm's hyperlink detection.
opt.list = true
opt.listchars = {
	tab = "->",
	trail = "·",
	extends = ">",
	precedes = "<",
	nbsp = "+",
	lead = "·",
	-- eol = "⏎",
}

-- https://vim.fandom.com/wiki/Learn_to_use_help#Comments
opt.wildmode = { "longest:full", "full" }
opt.completeopt = { "longest", "menuone" }

-- Round indent to multiple of 'shiftwidth' when using > and <.
opt.shiftround = true

opt.swapfile = false
opt.backup = false
opt.undofile = true

-- Remove screen line cursor padding so that `zt` and `zb` both work.`
opt.scrolloff = 0

opt.clipboard:append("unnamedplus")

opt.jumpoptions:append("view")

if vim.g.vscode then
	return
end

-- Column lines.
--
-- Disabled due to a rendering bug in `vscode-neovim`. i.e.,
-- https://github.com/vscode-neovim/vscode-neovim/issues/1352
opt.colorcolumn = { "+0", "+20", "+40" }
