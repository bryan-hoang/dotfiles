local M = {}

M.disabled = {
	n = {
		["<C-s>"] = "",
		["<leader>b"] = "",
		["<TAB>"] = "",
		["<S-Tab>"] = "",
		["<leader>fw"] = "",
	},
}

-- Disable jumping to keyword definition to avoid conflicting with opening
-- hyperlinks in Wezterm.
vim.api.nvim_set_keymap("", "<C-LeftMouse>", "", {})
-- Disable with 'bypass_mouse_reporting_modifiers' key from Wezterm, not sure
-- why the undocumented behaviour occurs.
vim.api.nvim_set_keymap("", "<C-S-LeftMouse>", "", {})

M.tabufline = {
	n = {
		-- cycle through buffers
		["<Leader><Tab>"] = {
			function()
				require("nvchad_ui.tabufline").tabuflineNext()
			end,
			"goto next buffer",
		},
		["<Leader><S-Tab>"] = {
			function()
				require("nvchad_ui.tabufline").tabuflinePrev()
			end,
			"goto prev buffer",
		},
	},
}

M.lspconfig = {
	n = {
		-- Overriding the default keybinding to change the diagnostic hover text.
		["<leader>f"] = {
			function()
				vim.diagnostic.open_float({
					source = true,
					format = function(diagnostic)
						local message = diagnostic.message
						if diagnostic.code ~= nil then
							message = message .. " (" .. diagnostic.code .. ")"
						end

						return message
					end,
				})
			end,
			"Custom floating diagnostic.",
		},
	},
}

-- Custom plugins.

M.markdown_preview = {
	n = {
		["<C-p>"] = {
			"<Plug>MarkdownPreviewToggle",
			"Toggle Markdown preview",
		},
	},
}

M.dap = {
	n = {
		["<leader>b"] = {
			"<Cmd>DapToggleBreakpoint<CR>",
			"dap toggle breakpoint",
		},
		["<leader>B"] = {
			"<Cmd>lua require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>",
			"dap set conditional breakpoint",
		},
		["<leader>lb"] = {
			"<Cmd>lua require('dap').set_breakpoint(nil, nil, vim.fn.input('Log point message: '))<CR>",
			"dap set log point",
		},
		["<F5>"] = { "<Cmd>DapContinue<CR>", "dap continue" },
		["<F10>"] = { "<Cmd>DapStepOver<CR>", "dap step over" },
		["<F11>"] = { "<Cmd>DapStepInto<CR>", "dap step into" },
		["<F12>"] = { "<Cmd>DapStepOut<CR>", "dap step out" },
		["<leader>dr"] = { "<Cmd>DapToggleRepl<CR>", "dap toggle repl" },
	},
}

M.lsp_format_modifications = {
	n = {
		["<Leader>fc"] = { "<Cmd>FormatModifications<CR>", "Format Changed lines." },
	},
}

M.symbols_outline = {
	n = {
		["<Leader>so"] = { "<Cmd>SymbolsOutline<CR>", "Toggle symboles outline." },
	},
}

M.telescope = {
	n = {
		["<Leader>fg"] = {
			"<Cmd>Telescope live_grep_args<CR>",
			"Live grep",
		},
	},
}

M.gitsigns = {
	n = {
		["<Leader>hs"] = {
			"<Cmd>Gitsigns stage_hunk<CR>",
			"Stage hunk.",
		},
		["<Leader>hu"] = {
			"<Cmd>Gitsigns undo_stage_hunk<CR>",
			"Undo stage hunk.",
		},
	},
}

return M
