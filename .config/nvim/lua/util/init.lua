local M = {}

-- Returns a custom list of events that fire only when entering a buffer.
M.buf_enter_event_list = {
	"BufReadPre",
	"BufNewFile",
}

local function set_file_associations(file_associations)
	for file_type, patterns in pairs(file_associations) do
		for _, pattern in ipairs(patterns) do
			vim.filetype.add({
				pattern = {
					[pattern] = file_type,
				},
			})
		end
	end
end

M.set_file_associations = set_file_associations

M.is_os_unix = string.sub(package.config, 1, 1) == "/"

return M
