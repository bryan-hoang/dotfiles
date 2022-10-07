local wezterm = require("wezterm")
local dracula = require("dracula")
local tmux = { "tmux", "new-session", "-A", "-s", "wezterm" }
local zsh = { "zsh", "-i" }
local git_bash = { "C:\\Program Files\\Git\\bin\\bash.exe", "-l" }
local bash = { "bash", "-i" }
local sh = { "sh", "-i" }

return {
	colors = dracula,
	font = wezterm.font("FiraCode Nerd Font Mono"),
	default_cursor_style = "SteadyBlock",
	-- https://wezfurlong.org/wezterm/config/lua/config/use_fancy_tab_bar
	use_fancy_tab_bar = false,
	-- https://wezfurlong.org/wezterm/config/lua/config/default_prog
	-- http://lua-users.org/wiki/TernaryOperator
	-- https://stackoverflow.com/a/14425862/8714233
	default_prog = package.config:sub(1, 1) == "/" and tmux or git_bash,
	-- https://wezfurlong.org/wezterm/config/lua/config/launch_menu
	launch_menu = {
		{
			label = "tmux",
			args = tmux,
		},
		{
			label = "Zsh",
			args = zsh,
		},
		{
			label = "bash",
			args = bash,
		},
		{
			label = "sh",
			args = sh,
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
	-- https://wezfurlong.org/wezterm/config/appearance#window-background-opacity
	window_background_opacity = 0.75,
	-- Default is 12.0.
	-- https://wezfurlong.org/wezterm/config/lua/config/font_size
	font_size = 14.0,
	-- https://wezfurlong.org/wezterm/config/lua/config/window_close_confirmation
	window_close_confirmation = "NeverPrompt",
	enable_scroll_bar = true,
	initial_cols = 100,
	selection_word_boundary = " \t\n{}[]()\"'`",
	-- Ctrl-click will open the link under the mouse cursor.
	mouse_bindings = {
		{
			event = {
				Up = {
					streak = 1,
					button = "Left",
				},
			},
			mods = "CTRL",
			action = "OpenLinkAtMouseCursor",
		},
	},
	enable_kitty_keyboard = true,
}
