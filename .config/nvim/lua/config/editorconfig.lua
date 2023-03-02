-- https://github.com/neovim/neovim/blob/master/runtime/lua/editorconfig.lua#L76
require("editorconfig").properties.max_line_length = function(bufnr, val)
	local filename = vim.api.nvim_buf_get_name(bufnr)

	-- Don't set `textwidth` for certain filesto maintains `gw` wrapping.
	if string.match(filename, "COMMIT_EDITMSG") then
		return
	end

	local n = tonumber(val)

	if n then
		vim.bo[bufnr].textwidth = n
	else
		assert(val == "off", 'max_line_length must be a number or "off"')
		vim.bo[bufnr].textwidth = 0
	end
end
-- https://github.com/neovim/neovim/blob/master/runtime/lua/editorconfig.lua#L111
require("editorconfig").properties.insert_final_newline = function(bufnr, val)
	assert(
		val == "true" or val == "false",
		'insert_final_newline must be either "true" or "false"'
	)
	-- Don't fix to by default to make it easier to signal in lualine..
	vim.bo[bufnr].fixendofline = false
	-- vim.bo[bufnr].endofline = val == "true"
end
