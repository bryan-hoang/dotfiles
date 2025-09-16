-- FIXME: https://github.com/seblyng/roslyn.nvim/issues/236#issuecomment-3195101051
return {
	handlers = {
		["workspace/_roslyn_projectNeedsRestore"] = function(_, result, ctx)
			return vim.NIL
		end,
	},
}
