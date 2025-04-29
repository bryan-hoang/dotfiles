return {
	{
		"nvim-neotest/neotest",
		optional = true,
		dependencies = {
			"marilari88/neotest-vitest",
		},
		opts = {
			adapters = {
				["neotest-vitest"] = {
					-- Filter directories when searching for test files. Useful in large projects (see Filter directories notes).
					filter_dir = function(name, _rel_path, _root)
						return name ~= "node_modules"
					end,
					---Custom criteria for a file path to determine if it is a vitest test file.
					---@async
					---@param file_path string Path of the potential vitest test file
					---@return boolean
					is_test_file = function(file_path)
						return string.match(file_path, "test")
					end,
				},
			},
		},
	},
}
