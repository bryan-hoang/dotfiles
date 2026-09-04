# WezTerm Config

- This directory is `~/.config/wezterm` in the home-directory dotfiles
  repository. The Git root is `~`.
- `wezterm.lua` is the runtime entry point. `selene.toml` selects `wezterm.yml`
  as Selene's standard library. `wezterm.yml` is not a WezTerm configuration
  file.
- The shared Lua config has OS branches. UNIX starts `zsh` and maximizes the GUI
  window on startup; Windows starts `pwsh`. Keep both paths valid.
- `machine` is an optional module loaded with `pcall` for machine-specific
  overrides. Keep the shared config loadable when that module is absent.
- The config builds WSL domains from WezTerm defaults and SSH domains from the
  local SSH config. Changes to those sections depend on the local environment.
- Validate the Lua entry point with
  `wezterm --config-file wezterm.lua show-keys --lua`.
- Check this file with `mise x -- rumdl check AGENTS.md`. Use
  `mise x -- hk check` for repository hook checks; see `../hk/AGENTS.md` for the
  global hook setup.
- Git's dotfiles-specific ignore file (`~/.config/git/dotfiles.gitignore`)
  ignores this untracked `AGENTS.md`, so normal status and diffs omit it.
