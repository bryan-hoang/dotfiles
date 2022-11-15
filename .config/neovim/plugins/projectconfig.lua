return {
	config = function()
		require("nvim-projectconfig").setup({
			-- Set the project directory to the custom path to use personal
			-- utilities.
			project_dir = vim.env.XDG_CONFIG_HOME .. "/neovim/projects/",

			-- Display message after load config file.
			silent = false,

			-- Change directory inside neovim and load project config.
			autocmd = true,
		})
	end,
}
