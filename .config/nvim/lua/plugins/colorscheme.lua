return {
	{
		-- Diff syntax highlighting is off.
		"ellisonleao/gruvbox.nvim",
		lazy = false,
		opts = {
			transparent_mode = true,
			italics = {
				strings = false,
			},
		},
	},
	{
		"folke/tokyonight.nvim",
		lazy = false,
		opts = {
			style = "night",
			transparent = true,
			styles = {
				sidebars = "transparent",
				floats = "transparent",
				comments = { italic = false },
			},
		},
	},
	{
		"catppuccin/nvim",
		lazy = false,
		name = "catppuccin",
		-- https://github.com/catppuccin/nvim#configuration
		opts = {
			transparent_background = true,
			no_italic = true,
		},
	},
	{
		"rose-pine/neovim",
		name = "rose-pine",
		lazy = false,
		opts = {
			disable_background = true,
			disable_float_background = false,
		},
	},
	{
		"EdenEast/nightfox.nvim",
		lazy = false,
		opts = {
			options = {
				transparent = true,
			},
		},
	},
	{
		"navarasu/onedark.nvim",
		lazy = false,
		opts = {
			transparent = true,
		},
	},
	{
		"rebelot/kanagawa.nvim",
		lazy = false,
		opts = {
			transparent = true,
		},
	},
	{
		-- A mcdonald's inspired theme.
		"dundargoc/fakedonalds.nvim",
		lazy = false,
	},
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "tokyonight",
		},
	},
}
