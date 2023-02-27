-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local wk = require("which-key")

wk.register({
	m = {
		name = "+minimap/md",
	},
	h = {
		name = "+harpoon",
	},
	g = {
		name = "+git/debug",
	},
}, {
	prefix = "<Leader>",
})

-- Keep default line wrapping behaviour.
vim.keymap.del({ "n", "x" }, "gw")
vim.keymap.del("n", "<Leader>`")
vim.keymap.del("n", "<Leader>gc")
vim.keymap.del("n", "<Leader>gs")

-- Set here instead of `keys` section for telescope.nvim to prevent race
-- condition.
vim.keymap.set("n", "<Leader>bb", "<cmd>Telescope buffers<cr>", {
	desc = "Open buffer picker",
})

-- Disable jumping to keyword definition to avoid conflicting with opening
-- hyperlinks in Wezterm.
vim.api.nvim_set_keymap("", "<C-LeftMouse>", "", {})
-- Disable with 'bypass_mouse_reporting_modifiers' key from Wezterm, not sure
-- why the undocumente behaviour occurs.
vim.api.nvim_set_keymap("", "<C-S-LeftMouse>", "", {})

-- Add newlines above and below the cursor in normal mode. Source:
-- `tummetott/unimpaired.nvim`.
vim.keymap.set("n", "]<Space>", function()
	vim.cmd("put =repeat(nr2char(10), v:count1)|silent '[-")
end, {
	desc = "Add newline below",
})
vim.keymap.set("n", "[<Space>", function()
	vim.cmd("put! =repeat(nr2char(10), v:count1)|silent ']+")
end, {
	desc = "Add newline above",
})
