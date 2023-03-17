local wezterm = require("wezterm")

local act = wezterm.action
local mux = wezterm.mux
local is_os_unix = string.sub(package.config, 1, 1) == "/"
local zsh = { "zsh", "--interactive" }
local bash = { "bash", "-i" }
local git_bash = { "C:\\Program Files\\Git\\bin\\bash.exe", "--login" }
local x_padding = 8

local wsl_domains = wezterm.default_wsl_domains()
for _index, domain in ipairs(wsl_domains) do
	-- Otherwise, its opened in the Windows user's home directory.
	domain.default_cwd = "~"
end

wezterm.on("gui-startup", function(cmd)
	---@diagnostic disable-next-line: unused-local
	local _tab, _pane, window = mux.spawn_window(cmd or {})
	window:gui_window():maximize()
end)

-- https://wezfurlong.org/wezterm/config/lua/wezterm/enumerate_ssh_hosts/
local ssh_domains = {}
for host, _config in pairs(wezterm.enumerate_ssh_hosts()) do
	table.insert(ssh_domains, {
		-- The name can be anything you want; we're just using the hostname
		name = host,
		-- Remote_address must be set to `host` for the ssh config to apply to it
		remote_address = host,
		-- If you don't have wezterm's mux server installed on the remote
		-- host, you may wish to set multiplexing = "None" to use a direct
		-- ssh connection that supports multiple panes/tabs which will close
		-- when the connection is dropped.
		multiplexing = "None",
		-- If you know that the remote host has a posix/unix environment,
		-- setting assume_shell = "Posix" will result in new panes respecting
		-- the remote current directory when multiplexing = "None".
		assume_shell = "Posix",
	})
end

return {
	color_scheme = "Dracula (Official)",
	font = wezterm.font(
		is_os_unix and "FiraCode Nerd Font Mono" or "FiraCode NFM"
	),
	-- Default is 12.0.
	font_size = 11.0,
	default_cursor_style = "SteadyBlock",
	use_fancy_tab_bar = false,
	hide_tab_bar_if_only_one_tab = true,
	-- http://lua-users.org/wiki/TernaryOperator
	-- https://stackoverflow.com/a/14425862/8714233
	default_prog = is_os_unix and zsh or git_bash,
	launch_menu = {
		{
			label = "Z shell (Zsh)",
			args = zsh,
		},
		{
			label = "bash",
			args = bash,
		},
		{
			label = "Git Bash",
			args = git_bash,
		},
		{
			label = "Powershell Core",
			args = { "pwsh" },
		},
	},
	wsl_domains = wsl_domains,
	ssh_domains = ssh_domains,
	window_background_opacity = 0.75,
	window_close_confirmation = "NeverPrompt",
	initial_cols = 120,
	initial_rows = 32,
	selection_word_boundary = " \t\n{}[]()\"'`",
	mouse_bindings = {
		-- Change the default click behavior so that it only selects
		-- text and doesn't open hyperlinks
		{
			event = { Up = { streak = 1, button = "Left" } },
			mods = "NONE",
			action = act.CompleteSelection("PrimarySelection"),
		},
		-- and make CTRL-Click open hyperlinks
		{
			event = { Up = { streak = 1, button = "Left" } },
			mods = "CTRL",
			action = act.OpenLinkAtMouseCursor,
		},
	},
	hyperlink_rules = {
		-- Linkify things that look like URLs and the host has a TLD name in
		-- punctionation (i.e., brackets). e.g.,
		-- (https://example.com)
		-- [https://example.com]
		-- <https://example.com>
		-- "https://example.com"
		--
		{
			regex = "[[:punct:]](\\w+://\\S+)[[:punct:]]",
			format = "$1",
		},
		-- Then handle URLs not wrapped in brackets
		-- and include terminating ), / or - characters, if any
		-- these seem to be the most common trailing characters that are part of URLs
		-- there may be additional common ones. e.g.,
		-- https://example.com/
		-- https://www.rfc-editor.org/rfc/rfc2606.html#section-1
		-- https://dcp.work/?bankAccount=foo
		{
			regex = "\\b\\w+://\\S+[)/a-zA-Z0-9-]+",
			format = "$0",
		},
		-- Linkify email addresses (e.g., bryan@bryanhoang.dev)
		-- Compiled-in default. Used if you don't specify any hyperlink_rules.
		{
			regex = [[\b\w+@[\w-]+(\.[\w-]+)+\b]],
			format = "mailto:$0",
		},
		-- file:// URI
		-- Compiled-in default. Used if you don't specify any hyperlink_rules.
		{
			regex = [[\bfile://\S*\b]],
			format = "$0",
		},
		-- Linkify things that look like URLs with numeric addresses as hosts.
		-- E.g. http://127.0.0.1:8000/ for a local development server,
		-- or http://192.168.1.1/ for the web interface of many routers.
		{
			regex = [[\b\w+://(?:[\d]{1,3}\.){3}[\d]{1,3}\S*\b/?]],
			format = "$0",
		},
		-- Linkify URLs like http://[::1]:5000/ for local development. e.g., from
		-- `dufs`.
		{
			regex = [[\b\w+://\[::\d\]\S*\b/?]],
			format = "$0",
		},
		-- Match http://localhost:1337/.
		{
			regex = [[http://localhost:[0-9]+\S*\b/?]],
			format = "$0",
		},
		-- Make username/project paths clickable. This implies paths like the following are for GitHub.
		-- ( "nvim-treesitter/nvim-treesitter" | wbthomason/packer.nvim | wez/wezterm | "wez/wezterm.git" )
		-- As long as a full URL hyperlink regex exists above this it should not match a full URL to
		-- GitHub or GitLab / BitBucket (i.e. https://gitlab.com/user/project.git is still a whole clickable URL)
		{
			regex = [[["]?([\w\d]{1}[-\w\d]+)(/){1}([-\w\d\.]+)["]?]],
			format = "https://www.github.com/$1/$3",
		},
	},
	enable_kitty_keyboard = true,
	keys = {
		-- Activate the Launcher Menu in the current tab.
		{ key = "l", mods = "ALT", action = wezterm.action.ShowLauncher },
		-- Override default key binding to disable confirmation of closing the tab.
		{
			key = "W",
			mods = "CTRL",
			action = wezterm.action.CloseCurrentTab({ confirm = false }),
		},
	},
	window_padding = {
		left = x_padding,
		right = x_padding,
		top = 0,
		bottom = 0,
	},
	window_decorations = "RESIZE",
}
