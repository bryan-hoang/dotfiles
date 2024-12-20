local should_load_colorschemes = os.getenv("NVIM_LOAD_COLORSCHEMES")

return {
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "catppuccin",
		},
	},
	{
		"catppuccin/nvim",
		lazy = not should_load_colorschemes,
		name = "catppuccin",
		-- https://github.com/catppuccin/nvim#configuration
		opts = {
			transparent_background = true,
			no_italic = true,
		},
	},
	{
		-- Diff syntax highlighting is off.
		"ellisonleao/gruvbox.nvim",
		lazy = not should_load_colorschemes,
		opts = {
			transparent_mode = true,
			italics = {
				strings = false,
			},
		},
	},
	{
		"folke/tokyonight.nvim",
		lazy = not should_load_colorschemes,
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
		"rose-pine/neovim",
		name = "rose-pine",
		lazy = not should_load_colorschemes,
		opts = {
			disable_background = true,
			disable_float_background = false,
		},
	},
	{
		"EdenEast/nightfox.nvim",
		lazy = not should_load_colorschemes,
		opts = {
			options = {
				transparent = true,
			},
		},
	},
	{
		"navarasu/onedark.nvim",
		lazy = not should_load_colorschemes,
		opts = {
			transparent = true,
		},
	},
	{
		"rebelot/kanagawa.nvim",
		lazy = not should_load_colorschemes,
		opts = {
			transparent = true,
		},
	},
	{
		-- A mcdonald's inspired theme.
		"dundargoc/fakedonalds.nvim",
		lazy = not should_load_colorschemes,
	},
}
