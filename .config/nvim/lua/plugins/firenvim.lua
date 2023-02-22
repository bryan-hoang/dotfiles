return {
	"glacambre/firenvim",

	-- Lazy load firenvim. Explanation:
	-- https://github.com/folke/lazy.nvim/discussions/463#discussioncomment-4819297
	cond = not not vim.g.started_by_firenvim,
	lazy = false,
	build = function()
		require("lazy").load({ plugins = { "firenvim" }, wait = true })
		vim.fn["firenvim#install"](0)
	end,
	config = function()
		vim.api.nvim_create_autocmd({ "BufEnter" }, {
			pattern = { "gitlab.com_*.txt", "github.com_*.txt" },
			command = "set filetype=markdown",
		})

		vim.g.firenvim_config = {
			localSettings = {
				[".*"] = {
					takeover = "never",
				},
			},
		}
	end,
}
