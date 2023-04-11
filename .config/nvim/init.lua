-- https://github.com/neovim/neovim/pull/22668
vim.loader.enable()

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
