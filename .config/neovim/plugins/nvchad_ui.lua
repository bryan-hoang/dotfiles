-- https://nvchad.com/config/nvchad_ui#override-statusline-modules

local fn = vim.fn
local sep_style = vim.g.statusline_sep_style
local separators = (type(sep_style) == "table" and sep_style)
	or require("nvchad_ui.icons").statusline_separators[sep_style]
local sep_r = separators["right"]

return {
	-- Overrides the fileInfo section of the statusline to signal whether the
	-- `&eol` option is set or not for the currently open file. For some reason,
	-- stock Neovim doesn't send a message about the lack of a final newline like
	-- vim does.
	--
	-- Also displays the relative file path rather than just the base filename.
	fileInfo = function()
		local icon = "  "
		local eol_indocator = (vim.opt.eol:get() and "" or "[noeol]")
		local filename = fn.expand("%")

		if filename ~= "Empty " then
			local devicons_present, devicons = pcall(require, "nvim-web-devicons")

			if devicons_present then
				local ft_icon = devicons.get_icon(filename)
				icon = (ft_icon ~= nil and " " .. ft_icon) or ""
			end

			filename = " " .. filename .. " "
		end

		return eol_indocator
			.. "%#St_file_info#"
			.. icon
			.. filename
			.. "%#St_file_sep#"
			.. sep_r
	end,
}
