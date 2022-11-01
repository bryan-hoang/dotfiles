return {
	run = function()
		vim.fn["firenvim#install"](0)
	end,
	config = function()
		-- Make editing comments on GitHub/GitLab easier.
		vim.api.nvim_create_autocmd({ "BufEnter" }, {
			pattern = { "gitlab.com_*.txt", "github.com_*.txt" },
			command = "set filetype=markdown",
		})

		vim.g.firenvim_config = {
			globalSettings = {
				takeover = "never",
			},
			localSettings = {
				[".*"] = {
					takeover = "never",
				},
				["https://git(hub|lab).com/"] = {
					takeover = "always",
				},
			},
		}
	end,
}
