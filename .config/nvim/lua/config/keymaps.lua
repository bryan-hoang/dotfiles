-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local Util = require("lazyvim.util")

-- Keep default line wrapping behaviour.
vim.keymap.del({ "n", "x" }, "gw")
vim.keymap.del("n", "<leader>`")
vim.keymap.del("n", "<leader>gc")
vim.keymap.del("n", "<leader>gs")

-- Set here instead of `keys` section for telescope.nvim to prevent race
-- condition.
vim.keymap.set("n", "<leader>bb", "<cmd>Telescope buffers<cr>", {
	desc = "Open buffer picker",
})

-- Disable jumping to keyword definition to avoid conflicting with opening
-- hyperlinks in Wezterm.
vim.api.nvim_set_keymap("", "<C-LeftMouse>", "", {})
-- Disable with 'bypass_mouse_reporting_modifiers' key from Wezterm, not sure
-- why the undocumented behaviour occurs.
vim.api.nvim_set_keymap("", "<C-S-LeftMouse>", "", {})
