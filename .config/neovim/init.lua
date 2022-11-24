local set_file_associations = require("custom.utils").set_file_associations

-- load your globals, autocmds here or anything .__.

local opt = vim.opt
local g = vim.g

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

-- Textwidth for hard wrapping. I want to encourage writing short lines of
-- code. For long lines of code, use J where needed.
opt.tw = 80

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
opt.formatoptions:append("j")
opt.breakindent = true
opt.linebreak = true
opt.showbreak = "↪ "

-- Show certain whitespace characters. Don't show all space characters,
-- otherwise messes with wezterm's hyperlink detection.
opt.listchars = { tab = "->", lead = "·", trail = "·", nbsp = "+" }
opt.list = true

-- https://vim.fandom.com/wiki/Learn_to_use_help#Comments
opt.wildmode = { "longest:full", "full" }
opt.completeopt = { "longest", "menuone" }

-- Use default wrapping behaviour for diff windows.
opt.diffopt:append("followwrap")

-- Round indent to multiple of 'shiftwidth' when using > and <.
opt.shiftround = true

-- API calls.

set_file_associations({
	["yaml"] = { "gemrc" },
})
