-- https://github.com/neovim/neovim/pull/22668
-- :h vim.loader.enable()
vim.loader.enable()

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
