-- https://github.com/apple/pkl-neovim#lazynvim-setup
return {
	{
		"apple/pkl-neovim",
		ft = "pkl",
		dependencies = {
			{
				"nvim-treesitter/nvim-treesitter",
				build = function(_)
					vim.cmd("TSUpdate")
				end,
			},
			{
				"mason-org/mason.nvim",
				opts = {
					ensure_installed = {
						"pkl-lsp",
					},
				},
			},
		},
		build = function()
			require("pkl-neovim").init()

			-- Set up syntax highlighting.
			vim.cmd("TSInstall pkl")
		end,
		init = function()
			vim.g.pkl_neovim = {
				start_command = { "pkl-lsp" },
				pkl_cli_path = vim.fs.normalize(
					vim.trim(
						vim
							.system({ "mise", "which", "pkl" }, { text = true })
							:wait().stdout
					)
				),
			}

			local default_configuration_handler =
				vim.lsp.handlers["workspace/configuration"]
			vim.lsp.handlers["workspace/configuration"] = function(
				err,
				result,
				ctx,
				config
			)
				local response = default_configuration_handler(err, result, ctx, config)
				if not response then
					return response
				end

				local client = vim.lsp.get_client_by_id(ctx.client_id)
				if not client or client.name ~= "pkl" then
					return response
				end

				for index, item in ipairs(result.items or {}) do
					if item.section and response[index] == vim.NIL then
						-- Neovim splits sections, but Pkl keeps dotted settings flat.
						local setting = client.settings[item.section]
						if setting ~= nil then
							response[index] = setting
						end
					end
				end

				return response
			end
		end,
	},
}
