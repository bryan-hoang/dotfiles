local M = {}

-- Returns a custom list of events that fire only when entering a buffer.
M.buf_enter_event_list = {
	"BufReadPre",
	"BufNewFile",
}

M.is_os_unix = string.sub(package.config, 1, 1) == "/"

return M
