return {
	{
		"glacambre/firenvim",
		-- Lazy load `firenvim`. Explanation:
		-- https://github.com/folke/lazy.nvim/discussions/463#discussioncomment-4819297
		cond = not not vim.g.started_by_firenvim,
		lazy = false,
		build = function()
			require("lazy").load({ plugins = { "firenvim" }, wait = true })
			vim.fn["firenvim#install"](0)
		end,
		config = function()
			vim.api.nvim_create_autocmd("BufEnter", {
				pattern = { "gitlab.com_*.txt", "github.com_*.txt" },
				callback = function()
					vim.bo.filetype = "markdown"
				end,
			})

			vim.g.firenvim_config = {
				localSettings = {
					[".*"] = {
						takeover = "never",
					},
				},
			}
		end,
	},
	{
		"subnut/nvim-ghost.nvim",
		cmd = "GhostTextStart",
		init = function()
			vim.g.nvim_ghost_autostart = 0
			vim.api.nvim_create_augroup("nvim_ghost_user_autocommands", {})

			local pattern = {
				"learn.svelte.dev",
			}

			vim.api.nvim_create_autocmd("User", {
				group = "nvim_ghost_user_autocommands",
				pattern = pattern,
				callback = function(event)
					-- Avoid `nofile` value to enable LSP attaching.
					vim.bo.buftype = "nowrite"

					if event.match:match(pattern[1]) then
						vim.bo.filetype = "svelte"
					end
				end,
			})
		end,
		config = function() end,
	},
}
