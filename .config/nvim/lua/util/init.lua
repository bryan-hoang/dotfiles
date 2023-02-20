local M = {}

-- Returns a custom list of events that fire only when entering a buffer.
function M.get_buf_enter_event_list()
	return {
		"BufReadPre",
		"BufNewFile",
	}
end

return M
