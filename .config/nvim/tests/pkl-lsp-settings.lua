local source_path = debug.getinfo(1, "S").source:sub(2)
local config_dir = vim.fs.dirname(vim.fs.dirname(vim.fs.normalize(source_path)))
local plugin_spec_path =
	vim.fs.joinpath(config_dir, "lua", "plugins", "extras", "lang", "pkl.lua")
local plugin_spec = dofile(plugin_spec_path)[1]
local default_handler = vim.lsp.handlers["workspace/configuration"]
local original_system = vim.system
local original_get_client_by_id = vim.lsp.get_client_by_id
local cli_path = vim.fs.normalize([[C:\fake\pkl.exe]])
local nested_cli_path = "nested-pkl-cli"

local function assert_equal(expected, actual, message)
	assert(
		actual == expected,
		("%s\nexpected: %s\nactual: %s"):format(
			message,
			vim.inspect(expected),
			vim.inspect(actual)
		)
	)
end

vim.system = function(command, options)
	assert(
		vim.deep_equal(command, { "mise", "which", "pkl" }),
		"expected mise to locate Pkl"
	)
	assert(options.text, "expected command output in text mode")

	return {
		wait = function()
			return { stdout = cli_path .. "\n" }
		end,
	}
end

plugin_spec.init()
vim.system = original_system
assert_equal(
	cli_path,
	vim.g.pkl_neovim.pkl_cli_path,
	"Pkl CLI path should be configured"
)

local clients = {
	[1] = {
		name = "pkl",
		settings = {
			["pkl.cli.path"] = vim.g.pkl_neovim.pkl_cli_path,
		},
	},
	[2] = {
		name = "other-server",
		settings = {
			pkl = {
				cli = {
					path = nested_cli_path,
				},
			},
		},
	},
}

vim.lsp.get_client_by_id = function(client_id)
	return clients[client_id]
end

local handler = vim.lsp.handlers["workspace/configuration"]
local request = { items = { { section = "pkl.cli.path" } } }
local pkl_response = handler(nil, request, {
	client_id = 1,
	method = "workspace/configuration",
})
assert_equal(
	cli_path,
	pkl_response[1],
	"Pkl should receive its flat dotted CLI setting"
)

local other_context = {
	client_id = 2,
	method = "workspace/configuration",
}
local other_response = handler(nil, request, other_context)
local original_other_response = default_handler(nil, request, other_context)
assert_equal(
	nested_cli_path,
	other_response[1],
	"Non-Pkl clients should retain nested settings behavior"
)
assert(
	vim.deep_equal(other_response, original_other_response),
	"Non-Pkl clients should use the original handler response"
)

vim.lsp.get_client_by_id = original_get_client_by_id
vim.lsp.handlers["workspace/configuration"] = default_handler
print("Pkl LSP settings regression: ok")
