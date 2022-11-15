return {
	run = function()
		vim.fn["mkdp#util#install"]()
	end,
	-- Preview markdown over SSH.
	config = function()
		-- https://github.com/iamcco/markdown-preview.nvim/pull/9
		-- $HOSTNAME would usually be defined per remote machine.
		-- e.g., in ~/.config/shell/extra.
		if os.getenv("SSH_CONNECTION") ~= "" then
			vim.cmd([[
			let g:mkdp_open_to_the_world = 1
			let g:mkdp_open_ip = $HOSTNAME
			let g:mkdp_port = 8080
			function! g:Open_browser(url)
				silent exe "!lemonade open "a:url
			endfunction
			let g:mkdp_browserfunc = "g:Open_browser"
		]])
		end
	end,
}
