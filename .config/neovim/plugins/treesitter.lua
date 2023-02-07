return {
	requires = {
		{
			"windwp/nvim-ts-autotag",
		},
	},
	-- https://github.com/nvim-treesitter/nvim-treesitter/wiki/Installation#packernvim
	run = function()
		local ts_update = require("nvim-treesitter.install").update({})
		ts_update()
	end,
	override_options = {
		-- List of parsers to ignore installing (for "all").
		--
		-- norg b/c of a compile error. See
		-- https://github.com/nvim-neorg/tree-sitter-norg/issues/36
		ignore_install = { "norg" },
		-- https://github.com/nvim-treesitter/nvim-treesitter#modules
		--
		-- A list of parser names, or "all".
		ensure_installed = "all",
		autotag = {
			enable = true,
		},
	},
}
