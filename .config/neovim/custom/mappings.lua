local M = {}

M.disabled = {
	n = {
		["<C-s>"] = "",
		["<leader>b"] = "",
	},
}

local markdown_preview = {
	["<C-p>"] = {
		"<Plug>MarkdownPreviewToggle",
		"Toggle Markdown preview",
	},
}

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

return M
