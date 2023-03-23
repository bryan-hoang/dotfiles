local wezterm = require("wezterm")

local is_os_unix = string.sub(package.config, 1, 1) == "/"
local zsh = { "zsh", "--interactive" }
local bash = { "bash", "-i" }
local git_bash = { "C:\\Program Files\\Git\\bin\\bash.exe", "--login" }

local mux = wezterm.mux
-- Max window on startup.
wezterm.on("gui-startup", function(cmd)
	---@diagnostic disable-next-line: unused-local
	local _tab, _pane, window = mux.spawn_window(cmd or {})
	window:gui_window():maximize()
end)

local config = wezterm.config_builder()

config:set_strict_mode(true)

config.color_scheme = "Dracula (Official)"
config.font =
	wezterm.font(is_os_unix and "FiraCode Nerd Font Mono" or "FiraCode NFM")
-- Default is 12.0.
config.font_size = 11.0
config.default_cursor_style = "SteadyBlock"
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
-- http://lua-users.org/wiki/TernaryOperator
-- https://stackoverflow.com/a/14425862/8714233
config.default_prog = is_os_unix and zsh or git_bash
config.window_background_opacity = 0.75
config.window_close_confirmation = "NeverPrompt"
config.initial_cols = 120
config.initial_rows = 32
config.selection_word_boundary = " \t\n{}[]()\"'`"
config.enable_kitty_keyboard = true
config.window_decorations = "RESIZE"

config.launch_menu = {
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
}

config.set_environment_variables = {
	SHLVL = "0",
}

config.keys = {
	-- Activate the Launcher Menu in the current tab.
	{ key = "l", mods = "ALT", action = wezterm.action.ShowLauncher },
	-- Override default key binding to disable confirmation of closing the tab.
	{
		key = "W",
		mods = "CTRL",
		action = wezterm.action.CloseCurrentTab({ confirm = false }),
	},
}

local act = wezterm.action
config.mouse_bindings = {
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
}

local wsl_domains = wezterm.default_wsl_domains()
for _index, domain in ipairs(wsl_domains) do
	-- Otherwise, its opened in the Windows user's home directory.
	domain.default_cwd = "~"
end
config.wsl_domains = wsl_domains

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
config.ssh_domains = ssh_domains

local x_padding = 8
config.window_padding = {
	left = x_padding,
	right = x_padding,
	top = 0,
	bottom = 0,
}

-- https://wezfurlong.org/wezterm/config/lua/config/hyperlink_rules.html?h=hyperlink
--
-- Use the defaults as a base
config.hyperlink_rules = wezterm.default_hyperlink_rules()
-- Make username/project paths clickable. this implies paths like the following
-- are for github. ( "nvim-treesitter/nvim-treesitter" | wbthomason/packer.nvim
-- | wez/wezterm | "wez/wezterm.git" ) as long as a full url hyperlink regex
-- exists above this it should not match a full url to github or gitlab /
-- bitbucket (i.e. https://gitlab.com/user/project.git is still a whole
-- clickable url)
table.insert(config.hyperlink_rules, {
	regex = [[["]?([\w\d]{1}[-\w\d]+)(/){1}([-\w\d\.]+)["]?]],
	format = "https://www.github.com/$1/$3",
})

return config
