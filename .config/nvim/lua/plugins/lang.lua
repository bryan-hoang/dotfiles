return {
	{
		"lervag/vimtex",
		ft = "tex",
	},
	{
		"simrat39/rust-tools.nvim",
		dependencies = {
			"neovim/nvim-lspconfig",
			"nvim-lua/plenary.nvim",
			"mfussenegger/nvim-dap",
		},
		ft = "rust",
		opts = function()
			-- https://github.com/simrat39/rust-tools.nvim/wiki/Debugging#codelldb-a-better-debugging-experience
			local extension_path = os.getenv("XDG_DATA_HOME") .. "/codelldb/"
			local codelldb_path = extension_path .. "adapter/codelldb"
			-- MacOS: This may be .dylib
			local liblldb_path = extension_path .. "lldb/lib/liblldb.so"

			local opts = {
				dap = {
					adapter = require("rust-tools.dap").get_codelldb_adapter(
						codelldb_path,
						liblldb_path
					),
				},
			}

			return opts
		end,
	},
	{
		-- Vim Just Syntax.
		"NoahTheDuke/vim-just",
		ft = "just",
	},
}
