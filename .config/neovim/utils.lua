local module = {}

module.set_file_associations = function(file_associations)
	for file_type, patterns in pairs(file_associations) do
		vim.api.nvim_create_autocmd(
			{ "BufRead", "BufNewFile" },
			{ pattern = patterns, command = "setfiletype " .. file_type }
		)
	end
end

return module
