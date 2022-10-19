local M = {}

M.disabled = {
	n = {
		["<C-s>"] = "",
		["<leader>b"] = "",
		["<TAB>"] = "",
		["<S-Tab>"] = "",
	},
}

M.tabufline = {
	plugin = true,

	n = {
		-- cycle through buffers
		["<C-K>"] = {
			function()
				require("nvchad_ui.tabufline").tabuflineNext()
			end,
			"goto next buffer",
		},

		["<C-J>"] = {
			function()
				require("nvchad_ui.tabufline").tabuflinePrev()
			end,
			"goto prev buffer",
		},

		-- pick buffers via numbers
		["<Bslash>"] = { "<cmd> TbufPick <CR>", "Pick buffer" },

		-- close buffer + hide terminal buffer
		["<leader>x"] = {
			function()
				require("nvchad_ui.tabufline").close_buffer()
			end,
			"close buffer",
		},
	},
}

local markdown_preview = {
	["<C-p>"] = {
		"<Plug>MarkdownPreviewToggle",
		"Toggle Markdown preview",
	},
}

-- Custom plugins.

M.markdown_preview = {
	n = markdown_preview,
	i = markdown_preview,
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

M.git_conflict = {
	n = {
		["]x"] = { "<Plug>(git-conflict-next-conflict)" },
		["[x"] = { "<Plug>(git-conflict-prev-conflict)" },
	},
}

return M
