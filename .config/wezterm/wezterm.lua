local wezterm = require("wezterm")

local is_os_unix = package.config:sub(1, 1) == "/"
local tmux = { "tmux", "new-session", "-A", "-s", "wezterm" }
local zsh = { "zsh", "-i" }
local bash = { "bash", "-i" }
local sh = { "sh", "-i" }
local git_bash = { "C:\\Program Files\\Git\\bin\\bash.exe", "-l" }
local msys2 =
	{ "C:\\msys64\\msys2_shell.cmd", "-defterm", "-here", "-no-start", "-msys" }

return {
	color_scheme = "Dracula (Official)",
	font = wezterm.font(
		is_os_unix and "FiraCode Nerd Font Mono" or "FiraCode NFM"
	),
	default_cursor_style = "SteadyBlock",
	use_fancy_tab_bar = false,
	hide_tab_bar_if_only_one_tab = true,
	-- http://lua-users.org/wiki/TernaryOperator
	-- https://stackoverflow.com/a/14425862/8714233
	default_prog = is_os_unix and tmux or git_bash,
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
		{
			label = "MSYS / MSYS2",
			args = msys2,
		},
	},
	window_background_opacity = 0.75,
	text_background_opacity = 0.75,
	-- Default is 12.0.
	font_size = 14.0,
	window_close_confirmation = "NeverPrompt",
	initial_cols = 100,
	selection_word_boundary = " \t\n{}[]()\"'`",
	mouse_bindings = {
		{
			-- Ctrl-click will open the link under the mouse cursor.
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
}
