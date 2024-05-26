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

-- config.color_scheme = "Dracula (Official)"
config.color_scheme = "Catppuccin Mocha"
config.font = wezterm.font("BerkeleyMono Nerd Font Mono")
-- Default is 12.0.
config.font_size = 12.0
config.default_cursor_style = "SteadyBlock"
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
-- http://lua-users.org/wiki/TernaryOperator
-- https://stackoverflow.com/a/14425862/8714233
config.default_prog = is_os_unix and zsh or git_bash
config.window_close_confirmation = "NeverPrompt"

-- Background
config.window_background_opacity = 0.75

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
	-- https://wezfurlong.org/wezterm/config/lua/keyassignment/QuickSelectArgs.html
	{
		key = "O",
		mods = "CTRL",
		action = wezterm.action.QuickSelectArgs({
			label = "Open url",
			-- e.g., http://localhost:9323.
			patterns = {
				[[https?://\S+\b]],
			},
			action = wezterm.action_callback(function(window, pane)
				local url = window:get_selection_text_for_pane(pane)
				wezterm.log_info("Opening: " .. url)
				wezterm.open_with(url)
			end),
		}),
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

-- (https://wezfurlong.org/wezterm/config/lua/config/hyperlink_rules.html?h=hyperlink)
-- [https://wezfurlong.org/wezterm/config/lua/config/hyperlink_rules.html?h=hyperlink]
-- {https://wezfurlong.org/wezterm/config/lua/config/hyperlink_rules.html?h=hyperlink}
-- <https://wezfurlong.org/wezterm/config/lua/config/hyperlink_rules.html?h=hyperlink>
--
-- Use the defaults as a base
local hyperlink_rules = {
	-- Matches: a URL in parens: (URL)
	{
		regex = "\\((\\w+://\\S+)\\)",
		format = "$1",
		highlight = 1,
	},
	-- Matches: a URL in brackets: [URL]
	{
		regex = "\\[(\\w+://\\S+)\\]",
		format = "$1",
		highlight = 1,
	},
	-- Matches: a URL in curly braces: {URL}
	{
		regex = "\\{(\\w+://\\S+)\\}",
		format = "$1",
		highlight = 1,
	},
	-- Matches: a URL in angle brackets: <URL>
	{
		regex = "<(\\w+://\\S+)>",
		format = "$1",
		highlight = 1,
	},
	-- Then handle URLs not wrapped in brackets.
	--
	-- NOTE: Remove `)` in matched character class unexpectedly in certain
	-- situations.
	{
		regex = "\\b\\w+://\\S+[/a-zA-Z0-9-]+",
		format = "$0",
	},
	-- Implicit mailto link. e.g., john@example.com
	{
		regex = "\\b\\w+@[\\w-]+(\\.[\\w-]+)+\\b",
		format = "mailto:$0",
	},
}

-- FIXME: Default rules lead to odd hyperlinking behaviours.
-- for _index, value in ipairs(wezterm.default_hyperlink_rules()) do
-- 	table.insert(hyperlink_rules, value)
-- end

-- Go module/pkg identifiers. e.g.,
-- gitlab.com/gitlab-org/cli/cmd/glab@latest
-- github.com/lemonade-command/lemonade@latest
table.insert(hyperlink_rules, {
	regex = [[(git(?:hub|lab)\.com(?:/[)a-zA-Z0-9-]+){2})\S*@?]],
	format = "https://$1",
	highlight = 1,
})
-- Make username/project paths clickable. this implies paths like the following
-- are for github. ( "nvim-treesitter/nvim-treesitter" | wbthomason/packer.nvim
-- | wez/wezterm | "wez/wezterm.git" ) as long as a full url hyperlink regex
-- exists above this it should not match a full url to github or gitlab /
-- bitbucket (i.e. https://gitlab.com/user/project.git is still a whole
-- clickable url)
table.insert(hyperlink_rules, {
	regex = [[((?:[\w\d]{1}[-\w\d]+)/{1}(?:[-\w\d\.]+))]],
	format = "https://github.com/$1",
	highlight = 1,
})

config.hyperlink_rules = hyperlink_rules

return config
