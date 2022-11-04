-- https://nvchad.com/config/nvchad_ui#override-statusline-modules
local st_modules = require("nvchad_ui.statusline.modules")

return {
	-- Overrides the fileInfo section of the statusline to signal whether the
	-- `&eol` option is set or not for the currently open file. For some reason,
	-- stock Neovim doesn't send a message about the lack of a final newline like
	-- vim does.
	fileInfo = function()
		return (vim.opt.eol:get() and "" or "[noeol]") .. st_modules.fileInfo()
	end,
}
