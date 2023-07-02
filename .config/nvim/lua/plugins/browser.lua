return {
	{
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
	},
	{
		"raghur/vim-ghost",
		lazy = false,
		build = function()
			vim.cmd([[GhostInstall]])
		end,
		config = function()
			vim.cmd([[
				function! s:SetupGhostBuffer()
					if match(expand("%:a"), '\v/ghost-(github|gitlab|reddit)\.com-')
						set ft=markdown
					endif
					if match(expand("%:a"), '\v/ghost-learn\.svelte\.dev-')
						set ft=svelte
					endif
				endfunction

				augroup vim-ghost
					au!
					au User vim-ghost#connected call s:SetupGhostBuffer()
				augroup END
			]])
		end,
	},
}
