return {
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
		run = function()
			local ts_update =
				require("nvim-treesitter.install").update({ with_sync = true })
			ts_update()
		end,
	},
}
