return {
	requires = {
		{ "nvim-telescope/telescope-live-grep-args.nvim" },
	},
	config = function()
		require("plugins.configs.telescope")
		local telescope = require("telescope")
		telescope.load_extension("live_grep_args")
	end,
}
