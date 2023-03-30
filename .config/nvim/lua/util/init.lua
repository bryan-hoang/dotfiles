local M = {}

-- Returns a custom list of events that fire only when entering a buffer.
M.buf_enter_event_list = {
	"BufReadPre",
	"BufNewFile",
}

-- Creates auto commands to set file types based on filename patterns.
function M.set_file_associations(file_associations)
	for file_type, patterns in pairs(file_associations) do
		vim.api.nvim_create_autocmd({
			"BufRead",
			"BufNewFile",
		}, {
			command = "setfiletype " .. file_type,
			pattern = patterns,
		})
	end
end

M.is_os_unix = string.sub(package.config, 1, 1) == "/"

return M
