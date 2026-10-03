# Legacy Path and Dependency Inventory

Research date: 2026-09-17\
Repository snapshot: `dca1b12e99e7632c6911be647248762d75514d1e`

## Result

The current `main` tree has 421 legacy entries: 352 regular files, of which 17
are executable, 57 symlinks, and 12 `gitlinks`. The workspace is a normal clone
with `core.bare=false`, `core.filemode=false`, and `core.symlinks=true`; it is
not the live home-root checkout. All 57 symlink entries are native Windows
symbolic links in this clone, while all 12 submodules are uninitialized. [`S1`]
[`S2`]

The tree is not safe to enroll wholesale. The decision-relevant findings are:

- One entry is definitively malformed: `.config/nvim/stylua.toml` has Git mode
  `120000`, but its blob is the two-line TOML content also stored as the regular
  file `.config/stylua/stylua.toml`. It is a dangling link whose target contains
  a newline, not a usable configuration file.
- Twenty-five links are not self-contained: 9 depend on uninitialized declared
  `gitlinks`, 9 point into undeclared external repositories, 6 depend on
  installed/generated host files, and 1 is malformed. The other 32 resolve to
  tracked internal targets in the current tree.
- Eighteen `AppData` entries are redirects to canonical `.config` paths. They
  are single-source only while the links remain intact. Three of those redirect
  paths diverged on the work machine, so their type and content must be
  reconciled before adoption.
- The named live exception `~/.config/mise/config.toml` is an 80-byte regular,
  non-executable, non-link file. It is active global mise configuration and
  declares the portable Cargo wrapper `cargo -> mbx`. It is eligible for
  enrollment under the portable `config/config.toml` stream.
- The legacy Git clean-filter rules are not an enrollment boundary. `mise`
  history reads live paths independently of the legacy index and attributes.
  Seven tracked paths are actually filter-associated and one GnuPG rule names
  the wrong legacy path. Those files require explicit split/exclude decisions.
- The tree mixes Windows, Git Bash, WSL, Linux X11, Linux Wayland, and systemd
  profiles, with residual macOS branches. Windows and Linux/WSL cannot be one
  undifferentiated enrollment profile.
- Several entries encode the old home-root checkout and should be replaced,
  notably `.local/bin/install-dotfiles`, `.config/git/dotfiles.*`, the `dot`
  aliases, and the README installation instructions.

`Enroll` below means eligible for the later reviewed allowlist, not approval to
track a directory wholesale. The migration map still requires exact-path review
and the separate sensitive-history gate.[`S3`] [`S8`]

## Disposition Legend

| Disposition     | Meaning for conversion                                                                                                                                     |
| --------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Enroll          | Preserve as live configuration, with an OS/profile selector where shown. Enroll exact files or tightly reviewed directories.                               |
| Replace         | Do not enroll the legacy bytes/link as-is. Produce a portable template, managed link, service/repository declaration, corrected mode, or sanitized source. |
| Repository-only | Retain as setup-repository documentation, maintenance, bootstrap source, or historical asset, but do not restore it under `HOME`.                          |
| Exclude         | Do not put the live path in setup history. This includes credential stores, unsafe generated state, and valueless placeholders.                            |

## Git Object and Mode Inventory

Git's documented mode meanings are `100644` for a normal file, `100755` for an
executable normal file, `120000` for a symlink whose blob is the target, and
`160000` for a `gitlink` to another repository commit.[`S4`]

| Git mode | Kind                         | Count | Migration consequence                                                                                          |
| -------- | ---------------------------- | ----: | -------------------------------------------------------------------------------------------------------------- |
| `100644` | Regular, non-executable file |   335 | Default candidate type; content and ownership still require review.                                            |
| `100755` | Regular, executable file     |    17 | Preserve execute permission for Unix/Linux targets even though the Windows worktree has `core.filemode=false`. |
| `120000` | Symlink                      |    57 | Tracking saves the link itself; its target must be enrolled or provisioned separately.[`S8`]                   |
| `160000` | `Gitlink`                    |    12 | A commit reference, not vendored file content. A clone/bootstrap decision is required.                         |

### Executable Files

| Group                          | All `100755` paths                                                                                                                                                                                                                                                                                                                            | Profile and dependency                                            |
| ------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------- |
| Graphical session entry points | `.config/X11/xinitrc`, `.config/X11/xserverrc`, `.config/X11/xsession`, `.config/bspwm/bspwmrc`                                                                                                                                                                                                                                               | `Linux/X11`; POSIX shell plus Xorg/window-manager commands.       |
| Logout hooks                   | `.config/shell/logout.sh`, `.config/zsh/.zlogout`                                                                                                                                                                                                                                                                                             | Unix shell; the latter is sourced despite its executable mode.    |
| User commands                  | `.local/bin/browser-wsl.sh`, `.local/bin/check-git-remote`, `.local/bin/git-submodules-sync`, `.local/bin/git-worktree-prune`, `.local/bin/i3lock-color`, `.local/bin/install-dotfiles`, `.local/bin/print-git-email-symbol`, `.local/bin/run-as-cron`, `.local/bin/ssnz`, `.local/bin/update-alternatives-clang`, `.local/bin/update-golang` | Mixed Unix, Linux, and WSL. See the path ledger for dispositions. |

Twenty-one additional tracked files begin with a shebang but have mode `100644`.
Most are intentionally sourced shell or PowerShell fragments. The one mode
requiring confirmation is `.config/vscode/server-env-setup`: it looks like a
directly invoked VS Code Remote hook but is non-executable. Repair its mode if
the consumer executes it rather than sources it. The PowerShell files do not
need a Unix execute bit on Windows.

## Active Reference Graph

| Entry point          | Active chain                                                                                                                                                                                                                 | External or machine-local edge                                                                                                                                                                   |
| -------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Bash login           | `.bash_profile` -> `.config/bash/.bash_profile` -> `~/.profile` and `~/.bashrc`; those links reach `.config/shell/.profile` and `.config/bash/.bashrc`; the profile loads `shell/env.sh`, and Bash loads `shell/common.sh`.  | Optional untracked `.config/shell/extra.sh`; generated `$XDG_DATA_HOME/blesh/ble.sh`; `starship`, `mise`, and `atuin` when installed.                                                            |
| Zsh login            | `.config/zsh/.zprofile` -> `~/.profile`; `.zshrc` loads Sheldon output and `shell/common.sh`.                                                                                                                                | Sheldon-managed repositories and an undeclared `tj/git-extras` checkout.                                                                                                                         |
| PowerShell           | `.config/pwsh/Microsoft.PowerShell_profile.ps1` sources `Initialize-Functions`, `Environment`, `Preferences`, `Completions`, `Aliases`, `Machine`, and `Integrations` when each exists.                                      | `Initialize-Machine.ps1` is deliberately untracked; completions are generated under `.local/share`; integrations invoke `tv`, `atuin`, `starship`, `mise`, and `zoxide`.                         |
| Git                  | `.config/git/config` includes local fragments plus declared external Dracula and Catppuccin theme paths; its Windows conditional loads `windows.gitconfig`; the old home-root conditional loads `dotfiles.gitconfig`.        | Missing/host-local `machine.gitconfig`; declared `gitlinks` for themes; command dependencies including `delta`, `difft`, `gitsign`, `mise`, `hk`, `git-lfs`, `sed`, `jaq`, and `git_diff_image`. |
| mise                 | The live `config.toml` and tracked `.config/mise/conf.d/*.toml` are merged global sources. Official precedence places `config.toml` above `conf.d`; `config.local.toml` and platform-local files remain machine-local.[`S5`] | `fnox-env` plugin repository and all tools declared in `00-tools.toml`; tool installation is outside this inventory.                                                                             |
| Neovim               | `.config/nvim/init.lua` -> `lua/config/lazy.lua` -> LazyVim and local plugin modules.                                                                                                                                        | Lazy-managed plugin repositories plus tools split between mise and Mason. The malformed local `stylua.toml` currently breaks local formatting configuration.                                     |
| WezTerm              | `.config/wezterm/wezterm.lua`; it has Windows and Unix branches.                                                                                                                                                             | Optional untracked `machine.lua`, local SSH configuration, WSL domains, and the `wezterm` executable.                                                                                            |
| Windows applications | Native application paths under `AppData` redirect to `.config` sources.                                                                                                                                                      | Developer Mode/link privilege, package-specific application paths, and applications that may replace links when saving settings.                                                                 |
| Linux services       | Regular units under `.config/systemd/user` plus six activation links under `*.target.wants`.                                                                                                                                 | systemd user manager and each service executable; two units contain a literal user home path.                                                                                                    |

The live mise exception is not a duplicate declaration of any existing key, but
it is a second writable global source outside the legacy index. Because mise
write commands may select a loaded global file, either enroll it explicitly or
merge its wrapper into one reviewed canonical global source. Do not silently
drop it during conversion.[`S5`]

## Complete Legacy Path Ledger

This ledger covers all 421 tracked entries. For the compact `.config` table,
every name is relative to `.config/`; a directory name covers every tracked
entry below that directory. Prefixes with mixed treatment are expanded in the
following table.

### Repository Root and Top-Level Trees

| Paths                                                                                                                                                                                         | Count | Class                                                              | Disposition                                                                                                                                                                              |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----: | ------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `.bash_logout`, `.bash_profile`, `.bashrc`, `.hushlogin`, `.profile`                                                                                                                          |     5 | Active compatibility symlinks to canonical tracked files           | Enroll the links and their targets together.                                                                                                                                             |
| `.editorconfig`, `.gitmodules`, `.lycheeignore`, `.oxfmtrc.jsonc`, `README.md`, `docs/adr/0001-preserve-sccache-for-registry-installs.md`, `package.json`, `pnpm-lock.yaml`, `renovate.json5` |     9 | Repository maintenance/support                                     | Repository-only. Confirm loss of the current home-wide effects from `.editorconfig`, formatter configuration, and package root. No tracked source imports the five package dependencies. |
| `.ssh/config`                                                                                                                                                                                 |     1 | Sensitive host/access metadata; content deliberately not inspected | Exclude from the public setup enrollment unless a later approved sanitized source replaces it.                                                                                           |
| `.config/**`                                                                                                                                                                                  |   341 | Mixed live configuration and legacy state                          | Fully expanded below.                                                                                                                                                                    |
| `.local/**`                                                                                                                                                                                   |    32 | User commands, data, links, and assets                             | Fully expanded below.                                                                                                                                                                    |
| `AppData/**`                                                                                                                                                                                  |    21 | Windows redirects plus three regular files                         | Fully expanded below.                                                                                                                                                                    |
| `src/github.com/**`                                                                                                                                                                           |    12 | `Gitlinks`                                                         | Repository-only records; provision approved dependencies explicitly.                                                                                                                     |

The root `GLOSSARY.md`, `AGENTS.md`, `docs/agents/**`, and
`docs/mise-migration/**` planning files are project-local instructions/research,
not legacy paths and not part of the 421. They were added after the audited tip,
so the audit gate clears them.

### Uniform `.config` Prefixes

| Disposition     | Profile                                   | Entry count | Complete prefix set                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| --------------- | ----------------------------------------- | ----------: | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Enroll          | Shared/cross-platform                     |         105 | `.actrc`, `.bunfig.toml`, `.curlrc`, `atuin`, `aube`, `bat`, `biome`, `black`, `bob`, `bottom`, `broot`, `bundle`, `clang-format`, `clangd`, `conventional-changelog`, `deno`, `direnv`, `doom`, `espanso`, `gem`, `gh`, `git-cliff`, `gitlogue`, `gitui`, `grit`, `hadolint.yaml`, `harper-ls`, `herdr`, `hk`, `hn-tui.toml`, `hunk`, `irb`, `jupytext.toml`, `latexindent`, `latexmk`, `litecli`, `luacheck`, `markdownlint`, `mise`, `mycli`, `mysql`, `opencode`, `pgcli`, `pip`, `pitchfork`, `pnpm`, `prettier`, `pypoetry`, `python`, `readline`, `ripgrep`, `rtk`, `rubocop`, `screen`, `sheldon`, `shell`, `shellcheckrc`, `shellfirm`, `silicon`, `solargraph`, `sqlfluff`, `starship`, `stylelint`, `stylua`, `tailspin`, `taplo`, `tealdeer`, `television`, `tokei.toml`, `tombi`, `topgrade`, `uv`, `vale`, `warp-terminal`, `wezterm`, `wiki-tui`, `youtube-dl`, `yt-dlp`, `zed`. |
| Enroll          | Unix/Linux                                |          32 | `autorandr`, `bash`, `blesh`, `brewfile`, `bspwm`, `feh`, `gtk-3.0`, `gtk-4.0`, `i3`, `kitty`, `login`, `nix`, `pam-gnupg`, `picom`, `pulse`, `redshift.conf`, `rust-motd`, `soar`, `sxhkd`, `texlive.profile`, `user-dirs.dirs`, `user-dirs.locale`, `vim`, `xbindkeys`, `xdg-desktop-portal`, `zsh`. `user-dirs.*` are app-written but portable declarative settings, not volatile contents.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| Enroll          | Windows                                   |          16 | `glazewm`, `komorebi`, `mintty`, `pwsh`, `vesktop`, `whkd`. The `vesktop/package.json` here is the intentional `CommonJS` marker, not the generated `AppData` package file.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| Repository-only | Manual deployment/export assets           |           6 | `arkenfox`, `monkeytype`, `vial`, `vimium`. These are not proven native live paths; preserve them as reviewed import/bootstrap sources rather than applying them automatically.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| Replace         | Obsolete, malformed, or machine-bound     |           9 | `asdf`, `emacs`, `emscripten`, `hk.pkl`, `nu`, `oh-my-bash`, `rofi`, `vscode`, `wget`. Details: `asdf`, `hk.pkl`, and the Oh My Bash path are legacy duplicates; `emacs` and `rofi` are external links; `emscripten` and `wget` contain literal home paths; `nu` encodes the old checkout and an untracked source; `vscode/server-env-setup` needs an executable-mode decision.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| Replace/split   | Sensitive or machine-specific mixed files |          13 | `bigquery`, `clipcat`, `docker`, `himalaya`, `i3status-rust`, `macchina`, `meli`, `ncspot`, `npm`, `spotify-tui`, `spotifyd`. Preserve only reviewed public settings; move credentials, identifiers, runtime sockets, and machine values to excluded local inputs or templates.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| Exclude         | Empty, behavior-free placeholders         |           2 | `pry`, `yarn`. Both tracked files are zero-byte placeholders.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |

The application named by each prefix is the default functional dependency. The
dependency tables below call out every non-obvious filesystem, service, plugin,
or machine-local dependency; a general package inventory is intentionally out of
scope.

### Mixed `.config` Prefixes

| Prefix and count    | Exact classification and disposition                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| ------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `X11` (6)           | Enroll Linux: `xinitrc`, `xserverrc`, `xsession`. Replace: `xresources`, whose active include contains a literal user home and declared Catppuccin `gitlink` path. Repository-only bootstrap sources: `xorg.conf.d/40-libinput.conf`, `xsession.desktop`, which target system directories.                                                                                                                                                                                                               |
| `alacritty` (3)     | Enroll `alacritty.common.toml` and Unix `alacritty.toml`; the common file requires the undeclared Catppuccin `Alacritty` checkout. Replace/template `alacritty.windows.toml`, which contains two literal `~-equivalent` absolute profile paths.                                                                                                                                                                                                                                                          |
| `autostart` (6)     | Enroll Linux `thunderbird.desktop`. Replace five links for Brave, `Geoclue`, `ProtonVPN`, Redshift, and WezTerm with reviewed `autostart` declarations that depend on installed desktop files.                                                                                                                                                                                                                                                                                                           |
| `default-pkgs` (11) | Enroll as support configuration if `install_default_pkgs` and `MISE_RUBY_DEFAULT_PACKAGES_FILE` are retained. Nine are regular package lists; `pip3.list -> pip.list` and `pipx.list -> uv.list` are valid internal links. Executing broad package bootstrap remains out of scope.                                                                                                                                                                                                                       |
| `dunst` (2)         | Enroll Linux `dunstrc`; replace/provision the `dunstrc.d/mocha.conf` link into the declared Catppuccin `Dunst` `gitlink`.                                                                                                                                                                                                                                                                                                                                                                                |
| `git` (14)          | Enroll shared active files `COMMIT_EDITMSG`, `alias.gitconfig`, `diff.gitconfig`, `hook.gitconfig`, `ignore`, `order`, and Windows-profile `windows.gitconfig`. Replace/split `attributes`, `config`, `filter.gitconfig`, `dotfiles.gitconfig`, and `dotfiles.gitignore`. Keep a legacy work-identity fragment, which is not referenced, repository-only unless a caller is restored. Exclude `credentials`; it is zero bytes at this tip, but its name and reachable history remain security-sensitive. |
| `helix` (4)         | Enroll `config.toml` and both local themes. Replace/template `languages.toml`, whose active debugger path is literal `/home/bryan/...`.                                                                                                                                                                                                                                                                                                                                                                  |
| `lsd` (2)           | Enroll `config.yaml`; replace/provision `colors.yaml`, which links into the declared Catppuccin LSD `gitlink`.                                                                                                                                                                                                                                                                                                                                                                                           |
| `mpv` (5)           | Enroll `input.conf` and `mpv.conf`; replace/provision the three links to undeclared `po5/thumbfast` and `tomasklaen/uosc` checkouts.                                                                                                                                                                                                                                                                                                                                                                     |
| `nvim` (58)         | Enroll the 57 regular files as one reviewed configuration family. Replace `.config/nvim/stylua.toml`: correct it to a real link to `../stylua/stylua.toml` or make it a regular per-Neovim configuration. `snippets/package.json` is generated metadata but belongs with the snippet files if that feature is kept.                                                                                                                                                                                      |
| `rio` (2)           | Enroll cross-platform `config.toml`; replace/provision the Catppuccin theme link, which targets the declared Rio `gitlink`.                                                                                                                                                                                                                                                                                                                                                                              |
| `sway` (3)          | Enroll Linux `config` as a valid internal link to `../i3/config` and enroll `config.d/sway.conf`; keep `sway-via-bash.desktop` repository-only as a system-session installation source.                                                                                                                                                                                                                                                                                                                  |
| `systemd` (19)      | Enroll 11 portable Linux user units. Replace/template `emacs.service` and `spotifyd.service`, which contain literal `/home/bryan` paths. Replace the six `default.target.wants`/`sockets.target.wants` links with explicit service activation/bootstrap rather than assuming copied links start services.                                                                                                                                                                                                |
| `tmux` (2)          | Enroll `tmux.conf.local`; replace/provision `tmux.conf`, which links into the declared `gpakosz` `gitlink`. `TPM-managed` plugin repositories are separate generated dependencies.                                                                                                                                                                                                                                                                                                                       |
| `windows` (9)       | Enroll Windows `hidden-launcher.vbs`, `wind-term-settings.json`, and `winget-settings.json`. Replace the three Task Scheduler XML exports; they contain old host `identity/SID` metadata and fixed executable/user paths. Keep `.editorconfig`, `winget-pkgs.json`, and `wsl.conf` repository-only; the package export is bootstrap data and `wsl.conf` targets `/etc`.                                                                                                                                  |
| `zebar` (9)         | Enroll Windows `settings.json` and all seven `custom/**` pack files. Exclude `.marketplace/glzr-io.starter.json`, which is installed-state metadata containing an installation timestamp.                                                                                                                                                                                                                                                                                                                |
| `zellij` (3)        | Enroll `config.kdl` and `layouts/default.kdl`; replace/provision the theme link to undeclared `catppuccin/zellij`.                                                                                                                                                                                                                                                                                                                                                                                       |

### `.local` Tree

| Paths                                                                                                                                                                                                       | Class                                              | Disposition and dependency                                                                                                                                                                                       |
| ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `.local/bin/browser-wsl.sh`, `check-git-remote`, `git-worktree-prune`, `i3lock-color`, `print-git-email-symbol`, `ssnz`                                                                                     | Authored executable utilities                      | Enroll under WSL/Linux/shared profiles as applicable. `browser-wsl.sh` needs WSL plus Windows PowerShell; `i3lock-color` needs `gpg-connect-agent`, `dunstctl`, and `i3lock`; `ssnz` needs tmux and/or `zellij`. |
| `.local/bin/install-dotfiles`                                                                                                                                                                               | Obsolete home-root installer                       | Replace. README already calls it old; it checks a nonexistent `~/submodules` marker and sources nonexistent `.config/shell/functions` rather than `functions.sh`.                                                |
| `.local/bin/git-submodules-sync`, `update-alternatives-clang`, `update-golang`                                                                                                                              | Repository/general bootstrap maintenance           | Repository-only. The first mutates `gitlinks`; the latter two are general machine bootstrap, outside this migration.                                                                                             |
| `.local/bin/run-as-cron`                                                                                                                                                                                    | Machine-bound executable                           | Replace/template: it requires literal `/home/bryan/.cron.env`; the environment file is an excluded machine input.                                                                                                |
| `.local/bin/docuum`, `git_diff_image`, `xdg-ninja`                                                                                                                                                          | Symlinks to generated or undeclared sources        | `Replace/provision.` Targets are respectively Cargo install output, `ewanmellor/git-diff-image`, and `b3nj5m1n/xdg-ninja`.                                                                                       |
| `.local/share/applications/neovide.desktop`, `.local/share/icons/hicolor/128x128/apps/neovide.png`                                                                                                          | Linux desktop file and vendored runtime icon       | Enroll together; require `Neovide` and desktop integration.                                                                                                                                                      |
| `.local/share/cargo/config.toml`                                                                                                                                                                            | Active Cargo configuration                         | Enroll shared. Do not enroll adjacent Cargo registry/cache/bin state.                                                                                                                                            |
| `.local/share/gnupg/gpg-agent.conf`, `gpg.conf`                                                                                                                                                             | Active configuration inside a sensitive state root | Replace/split and enroll exact reviewed files only. Never enroll the parent GnuPG directory, keys, sockets, or trust databases.                                                                                  |
| `.local/share/rye/config.toml`                                                                                                                                                                              | Legacy package-manager configuration               | Repository-only unless Rye remains an approved dependency; current shared tooling uses `uv/mise.`                                                                                                                |
| `.local/share/texmf/tex/latex/**` (4)                                                                                                                                                                       | Authored TeX classes/style                         | Enroll Linux/Unix as portable user data; requires TeX and `TEXMFHOME`.                                                                                                                                           |
| `.local/share/vale/styles/config/vocabularies/**` (3)                                                                                                                                                       | Authored Vale vocabulary/configuration             | Enroll with `.config/vale/.vale.ini`.                                                                                                                                                                            |
| `.local/share/icons/Dracula-cursors`, `.local/share/icons/Dracula-dark`, `.local/share/themes/Dracula-dark`, `.local/share/vale/styles/MediaWiki`, `.local/share/zsh/completions/git-extras-completion.zsh` | Five links to declared or undeclared repositories  | Replace/provision; see dependency tables.                                                                                                                                                                        |

### `AppData` Tree and Redirects

Eighteen of 21 `AppData` paths are Git symlinks. They should not be enrolled as
independent writable copies. Use one canonical source and a tested Windows
destination/link representation. The mise managed symlink mode can fall back to
copying when Windows link privilege is unavailable, and directory links use
junctions; that fallback would create a second writable copy and must be tested
before rollout.[`S6`]

| Redirect path(s)                                                                                    | Canonical target                                      | Disposition                                                                                                          |
| --------------------------------------------------------------------------------------------------- | ----------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `AppData/Local/Packages/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe/LocalState/settings.json`       | `.config/windows/winget-settings.json`                | Replace with Windows destination deployment; do not track both.                                                      |
| `AppData/Local/Packages/Microsoft.WindowsTerminal{,Preview}_8wekyb3d8bbwe/LocalState/settings.json` | Both target `.config/windows/wind-term-settings.json` | Replace with stable/preview destination variants or reviewed dual deployment. Two applications can write one source. |
| `AppData/Local/rio`                                                                                 | `.config/rio`                                         | Replace with Windows directory destination; test junction/copy behavior.                                             |
| `AppData/Roaming/{bat,espanso,helix,lsd,mintty,mpv,ncspot,rtk}`                                     | Matching `.config/<app>` directories                  | Replace with per-app Windows destinations; do not duplicate-enroll.                                                  |
| `AppData/Roaming/alacritty/alacritty.toml`                                                          | `.config/alacritty/alacritty.windows.toml`            | Replace with the Windows `Alacritty` destination after templating its literal home path.                             |
| `AppData/Roaming/dystroy/broot/config/conf.hjson`                                                   | `.config/broot/conf.hjson`                            | Replace with a Windows destination.                                                                                  |
| `AppData/Roaming/harper-ls/dictionary.txt`                                                          | `.config/harper-ls/dictionary.txt`                    | Replace with a Windows destination and reconcile the work-machine divergence.                                        |
| `AppData/Roaming/nushell/nu/config/config.toml`                                                     | `.config/nu/config.toml`                              | Replace only after the obsolete Nu configuration is repaired.                                                        |
| `AppData/Roaming/silicon/config`                                                                    | `.config/silicon/config`                              | Replace with a Windows destination.                                                                                  |
| `AppData/Roaming/topgrade.toml`                                                                     | `.config/topgrade/topgrade.toml`                      | Replace with a Windows destination and reconcile the work-machine divergence.                                        |

The three regular `AppData` files are:

| Path                                                                                   | Classification                                                                                           | Disposition                                                                           |
| -------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| `AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/start-atuin-daemon.vbs` | Active startup launcher, duplicating the tracked `Atuin` scheduled-task export                           | Replace with one reviewed Windows service mechanism; do not retain both launch paths. |
| `AppData/Roaming/streamlink/config`                                                    | Active app configuration with a legacy secret-stripping clean filter                                     | Replace/split; enroll only a public source and keep credentials excluded.             |
| `AppData/Roaming/vesktop/package.json`                                                 | Generated `npm init`-style package metadata, distinct from the `CommonJS` marker under `.config/vesktop` | Exclude.                                                                              |

## Symlink Inventory

The following partition accounts for all 57 symlink-mode entries.

| Link class                                      | Count | Current status                                                                                                                                                                            |
| ----------------------------------------------- | ----: | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Internal tracked targets                        |    32 | Structurally resolve in the current tree. This includes 5 root shell/login links, 2 default-package aliases, 1 `Sway-to-i3` link, 6 systemd activation links, and 18 `AppData` redirects. |
| Targets inside declared `gitlinks`              |     9 | Not self-contained. All submodules are uninitialized; root `gitlink` directories may exist as placeholders, but required files are absent.                                                |
| Targets inside undeclared external repositories |     9 | Dangling in the workspace and lacking `.gitmodules` metadata.                                                                                                                             |
| Installed/generated host targets                |     6 | Five `autostart` desktop links plus the Cargo-installed `docuum` binary; all are absent from this workspace clone.                                                                        |
| Malformed                                       |     1 | `.config/nvim/stylua.toml`.                                                                                                                                                               |

### Internal Link Targets

| Link path(s)                                                                        | Stored target                                                                                                                                     |
| ----------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| `.bash_logout`, `.bash_profile`, `.bashrc`                                          | Matching `.config/bash/.bash_logout`, `.config/bash/.bash_profile`, `.config/bash/.bashrc`                                                        |
| `.hushlogin`                                                                        | `.config/login/.hushlogin`                                                                                                                        |
| `.profile`                                                                          | `.config/shell/.profile`                                                                                                                          |
| `.config/default-pkgs/pip3.list`                                                    | `pip.list`                                                                                                                                        |
| `.config/default-pkgs/pipx.list`                                                    | `uv.list`                                                                                                                                         |
| `.config/sway/config`                                                               | `../i3/config`                                                                                                                                    |
| `.config/systemd/user/default.target.wants/{atuin,ssh-agent}.service`               | `../<same-basename>`                                                                                                                              |
| `.config/systemd/user/sockets.target.wants/gpg-agent{,-browser,-extra,-ssh}.socket` | `../<same-basename>`                                                                                                                              |
| All 18 `AppData` redirects                                                          | The normalized canonical targets are listed in the `AppData` table above; each stored target is relative and remains inside the legacy home tree. |

### `Declared-Gitlink` Link Targets

| Link path(s)                                                          | Stored target                                                             | Target repository and disposition                                                                  |
| --------------------------------------------------------------------- | ------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| `.config/dunst/dunstrc.d/mocha.conf`                                  | `../../../src/github.com/catppuccin/dunst/themes/mocha.conf`              | `catppuccin/dunst`; provision dependency or vendor the one approved asset.                         |
| `.config/lsd/colors.yaml`                                             | `../../src/github.com/catppuccin/lsd/themes/catppuccin-mocha/colors.yaml` | `catppuccin/lsd`; provision dependency or vendor the one approved asset.                           |
| `.config/oh-my-bash`                                                  | `../src/github.com/ohmybash/oh-my-bash`                                   | `ohmybash/oh-my-bash`; replace/remove unless the currently inactive legacy Bash stack is retained. |
| `.config/rio/themes/catppuccin-mocha.toml`                            | `../../../src/github.com/catppuccin/rio/themes/catppuccin-mocha.toml`     | `catppuccin/rio`; provision dependency or vendor the one approved asset.                           |
| `.config/rofi/config.rasi`                                            | `../../src/github.com/dracula/rofi/theme/config1.rasi`                    | `dracula/rofi`; provision dependency or vendor the one approved asset.                             |
| `.config/tmux/tmux.conf`                                              | `../../src/github.com/gpakosz/.tmux/.tmux.conf`                           | `gpakosz/.tmux`; provision dependency before applying the local override.                          |
| `.local/share/icons/Dracula-cursors`                                  | `../../../src/github.com/dracula/gtk/kde/cursors/Dracula-cursors`         | `dracula/gtk`; provision the theme repository or package.                                          |
| `.local/share/icons/Dracula-dark`, `.local/share/themes/Dracula-dark` | `../../../src/github.com/dracula/gtk`                                     | `dracula/gtk`; provision the theme repository or package.                                          |

### Undeclared External Link Targets

| Link path(s)                                             | Stored target                                                            | Required external checkout and disposition                                                                     |
| -------------------------------------------------------- | ------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------- |
| `.config/emacs`                                          | `../src/github.com/doomemacs/doomemacs`                                  | `doomemacs/doomemacs`; declare a repository/bootstrap dependency or use the supported Doom installation flow.  |
| `.config/mpv/script-opts/thumbfast.conf`                 | `../../../src/github.com/po5/thumbfast/thumbfast.conf`                   | `po5/thumbfast`; declare or vendor reviewed file.                                                              |
| `.config/mpv/scripts/thumbfast.lua`                      | `../../../src/github.com/po5/thumbfast/thumbfast.lua`                    | `po5/thumbfast`; declare or vendor reviewed file.                                                              |
| `.config/mpv/script-opts/uosc.conf`                      | `../../../src/github.com/tomasklaen/uosc/src/uosc.conf`                  | `tomasklaen/uosc`; declare or vendor reviewed file.                                                            |
| `.config/zellij/themes/catppuccin.kdl`                   | `../../../src/github.com/catppuccin/zellij/catppuccin.kdl`               | `catppuccin/zellij`; declare or vendor reviewed theme.                                                         |
| `.local/bin/git_diff_image`                              | `../../src/github.com/ewanmellor/git-diff-image/git_diff_image`          | `ewanmellor/git-diff-image`; declare repository because Git's image diff driver actively invokes this command. |
| `.local/bin/xdg-ninja`                                   | `../../src/github.com/b3nj5m1n/xdg-ninja/xdg-ninja.sh`                   | `b3nj5m1n/xdg-ninja`; declare repository or install a packaged command.                                        |
| `.local/share/vale/styles/MediaWiki`                     | `../../../../src/github.com/errata-ai/MediaWiki/MediaWiki`               | `errata-ai/MediaWiki`; declare/package if the style remains enabled.                                           |
| `.local/share/zsh/completions/git-extras-completion.zsh` | `../../../../src/github.com/tj/git-extras/etc/git-extras-completion.zsh` | `tj/git-extras`; declare/package; `.zshrc` also directly sources the checkout.                                 |

### Installed and Generated Link Targets

| Link path(s)                                   | Stored target                                                       | Host dependency                                  |
| ---------------------------------------------- | ------------------------------------------------------------------- | ------------------------------------------------ |
| `.config/autostart/brave-browser.desktop`      | `../../.local/share/applications/brave-browser.desktop`             | Home-local Brave desktop file, currently absent. |
| `.config/autostart/geoclue-demo-agent.desktop` | `../../../../usr/share/applications/geoclue-demo-agent.desktop`     | Installed `Geoclue` desktop file.                |
| `.config/autostart/protonvpn-app.desktop`      | `../../../../usr/share/applications/protonvpn-app.desktop`          | Installed `ProtonVPN` desktop file.              |
| `.config/autostart/redshift-gtk.desktop`       | `../../../../usr/share/applications/redshift-gtk.desktop`           | Installed Redshift desktop file.                 |
| `.config/autostart/wezterm.desktop`            | `../../../../usr/share/applications/org.wezfurlong.wezterm.desktop` | Installed WezTerm desktop file.                  |
| `.local/bin/docuum`                            | `../../.local/share/cargo/bin/docuum`                               | Cargo-installed binary, currently absent.        |

The deep `autostart` relative paths only mean `/usr/share/...` when materialized
at the intended home depth; they resolve incorrectly inside this deeper
workspace clone. Treat installed desktop files as host dependencies, not
enrollment content. The malformed `Stylua` link's literal target is
`column_width = 80<LF>indent_width = 2`.

## `Gitlinks` And Vendored Assets

All 12 `gitlinks` are recorded in `.gitmodules`, and all show `-` from
`git submodule status`, meaning uninitialized in this clone.[`S2`]

| `Gitlink`                              | Declared URL                                   | Recorded commit | Active consumer and classification                                                                                                                             |
| -------------------------------------- | ---------------------------------------------- | --------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `src/github.com/gpakosz/.tmux`         | `https://github.com/gpakosz/.tmux.git`         | `af33f07`       | `.config/tmux/tmux.conf`; required if Oh My Tmux remains approved.                                                                                             |
| `src/github.com/akinomyoga/ble.sh`     | `https://github.com/akinomyoga/ble.sh.git`     | `b99cadb`       | No direct tracked path; Bash instead probes generated `$XDG_DATA_HOME/blesh/ble.sh`. Repository-only/removal candidate unless a provisioning edge is restored. |
| `src/github.com/ohmybash/oh-my-bash`   | `https://github.com/ohmybash/oh-my-bash.git`   | `ae44713`       | `.config/oh-my-bash`; Bash Sheldon activation is commented out. Legacy repository-only/removal candidate.                                                      |
| `src/github.com/amix/vimrc`            | `https://github.com/amix/vimrc.git`            | `46294d5`       | `.config/vim/vimrc` sources four files; required for the Vim profile.                                                                                          |
| `src/github.com/catppuccin/lsd`        | `https://github.com/catppuccin/lsd.git`        | `7085155`       | LSD colors link; required asset source.                                                                                                                        |
| `src/github.com/catppuccin/xresources` | `https://github.com/catppuccin/xresources.git` | `41afcd7`       | Active `Xresources` include; required for X11 after path repair.                                                                                               |
| `src/github.com/catppuccin/dunst`      | `https://github.com/catppuccin/dunst.git`      | `5955cf0`       | `Dunst` theme link; required asset source.                                                                                                                     |
| `src/github.com/catppuccin/delta`      | `https://github.com/catppuccin/delta.git`      | `74b47a3`       | Git configuration include; required for the configured Delta feature set.                                                                                      |
| `src/github.com/catppuccin/rio`        | `https://github.com/catppuccin/rio.git`        | `6c7e7f9`       | Rio theme link; required asset source.                                                                                                                         |
| `src/github.com/dracula/gtk`           | `https://github.com/dracula/gtk.git`           | `2618a03`       | Three icon/theme links and `GTK_THEME`; required Linux desktop theme source.                                                                                   |
| `src/github.com/dracula/git`           | `https://github.com/dracula/git`               | `924d5fc`       | Git configuration include; required for Git color configuration.                                                                                               |
| `src/github.com/dracula/rofi`          | `https://github.com/dracula/rofi.git`          | `459eee3`       | `Rofi` configuration link; required asset source.                                                                                                              |

The `gitlinks` themselves should remain repository-only during conversion. If a
consumer is approved, use an explicit bootstrap repository/package or vendor the
minimal immutable asset; do not assume a `gitlink` in the setup repository will
clone into `~/src`.[`S8`]

Regular vendored/deployment assets are limited and identifiable: the `Neovide`
PNG is a runtime icon, the `Zebar` custom pack includes a preview PNG, and the
`Arkenfox`, `Monkeytype`, Vial, and `Vimium` files are manual import sources.
The four TeX files and local Vale vocabularies are user-authored data rather
than third-party `gitlinks`.

## Other Required External Dependencies

| Dependency class                     | Consumers                                                                                                                                | Required action if consumer is enrolled                                                                                                                                            |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Undeclared path checkouts            | `catppuccin/alacritty`, `dracula/kitty`, `microsoft/vscode-node-debug2`                                                                  | Declare/package or replace literal checkout paths. The first is imported by `Alacritty`, the second by Kitty, and the third is an active Helix debugger path.                      |
| Install-only helper checkouts        | `matejak/argbash`, `Intersec/pyvenv-activate`                                                                                            | These appear in legacy installation/helper flows, not required startup paths. Keep repository-only unless those helpers remain approved.                                           |
| Manager-resolved shell repositories  | Sheldon Bash/Zsh plugin lists, generated `ble.sh`                                                                                        | Enroll declarations only; bootstrap/fetch generated repositories outside history. The Oh My Bash `gitlink` and Sheldon declaration are duplicate ways to acquire the same project. |
| Manager-resolved tmux repositories   | `TPM` plugins `tmux-resurrect`, `tmux-continuum`, `tmux-sensible`, `dracula/tmux`, `fcsonline/tmux-thumbs`                               | Enroll local tmux configuration; bootstrap `TPM/plugin` data separately and exclude generated plugin trees.                                                                        |
| Manager-resolved editor/plugins      | `LazyVim/lazy.nvim` plugins, Mason tools, OpenCode `@dietrichgebert/ponytail`, `hk` Pkl packages, `fnox` mise plugin                     | Enroll declarations; network installation is a reviewed bootstrap dependency, not dotfile content.                                                                                 |
| Git command dependencies             | Delta and Dracula theme `gitlinks`; `delta`, `difft`, `gitsign`, `hk`, `mise`, `git-lfs`, `sed`, `jaq`, `git_diff_image`, `diff-pdf`     | Preserve only commands reached by approved Git configuration. Remove legacy clean filters after their sensitive data is split.                                                     |
| Linux service/runtime dependencies   | systemd user manager, GnuPG agent, SSH agent, `Atuin`, `Docuum`, Emacs, Lemonade, `Spotifyd`, tmux, desktop portal                       | Enroll portable unit sources only; use bootstrap service enabling and packages. Do not enroll sockets, caches, sessions, or service state.                                         |
| Windows service/runtime dependencies | Task Scheduler, `WScript`, `Atuin`, `GlazeWM`, Lemonade, Windows Terminal stable/preview, `WinGet`, Rio, and redirected applications     | Generate tasks/destinations for the current account and installed package channel. Do not reuse exported `SIDs/host` identities.                                                   |
| Optional machine overlays            | `.config/shell/extra.sh`, `.config/git/machine.gitconfig`, `.config/pwsh/Initialize-Machine.ps1`, `.config/wezterm/machine.lua`, `~/.nu` | Keep excluded and machine-local. The first, PowerShell, and WezTerm references are guarded; the Nu source is unguarded and should be removed or made optional.                     |
| Sensitive/runtime inputs             | `.cron.env`, application credentials, SSH keys/known-host state, cloud/Kubernetes/database credential paths, GnuPG key material          | Required only on relevant machines and never enrollment candidates under the public-origin policy. Values were not inspected.                                                      |

One active dependency mismatch is independent of links: OpenCode configuration
invokes `taplo format`, while current mise tools declare `Tombi` but not
`Taplo`. Either retain/provision `Taplo` or change that formatter in a later,
explicit modernization; otherwise enrolled OpenCode configuration has a missing
command.

## Duplicate Writable Sources and Generated State

| Paths                                                                     | Finding                                                                                                                                  | Required disposition                                                                                        |
| ------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| `.config/nvim/stylua.toml` and `.config/stylua/stylua.toml`               | Same blob bytes under symlink and regular modes; the former interprets TOML as a link target.                                            | Repair to one canonical regular source plus a valid link, or retain two intentional regular configurations. |
| Eighteen `AppData` links and their `.config` targets                      | One source while links survive; possible duplicate writable copies if an app replaces a link or a Windows deployment falls back to copy. | Canonical source plus tested destination; never enroll both as content streams.                             |
| Stable and Preview Windows Terminal redirect paths                        | Both point to one `wind-term-settings.json`; both applications may write it.                                                             | Use explicit stable/preview variants or accept one reviewed shared source.                                  |
| `.config/hk.pkl` and `.config/hk/config.pkl`                              | Two global `hk` layouts pinned to different major generations; project instructions name the latter as source of truth.                  | Replace/remove `.config/hk.pkl`; enroll `hk/config.pkl`.                                                    |
| `.config/mise/config.toml` live exception and tracked `conf.d/*.toml`     | Supported layered sources, but the wrapper lives outside the old index and can become a separate write target.                           | Enroll or deliberately consolidate the wrapper; retain local overrides outside history.                     |
| `.config/vesktop/package.json` and `AppData/Roaming/vesktop/package.json` | Same `basename`, different roles. The first is a deliberate module-type marker; the second is generated package metadata.                | Enroll the first Windows configuration; exclude the second.                                                 |
| `.config/nvim/after/ftplugin/help.lua` and `man.lua`                      | Intentional identical regular blobs for two filetypes.                                                                                   | Enroll both; not a writable-source conflict.                                                                |
| `.config/user-dirs.*`                                                     | Generated by `xdg-user-dirs-update`, but declarative and user-editable.                                                                  | Enroll only in Linux profile if these standard mappings are desired.                                        |
| `.config/nvim/snippets/package.json`                                      | Tool-generated manifest for authored snippets.                                                                                           | Keep with the exact snippet family or regenerate; never enroll a broader generated plugin tree.             |
| `.config/zebar/.marketplace/glzr-io.starter.json`                         | Installed-state record with timestamp.                                                                                                   | Exclude.                                                                                                    |
| `.config/windows/{atuin-daemon,glazewm,lemonade-server}.xml`              | Task exports contain machine account metadata and fixed paths.                                                                           | Replace with portable task/service declarations.                                                            |
| `.config/windows/winget-pkgs.json`                                        | Exported package inventory; general package bootstrap is outside scope.                                                                  | Repository-only.                                                                                            |
| `.config/emscripten/config`                                               | Generated/machine configuration with a literal mise install path.                                                                        | Exclude live version; regenerate or template if later approved.                                             |
| Root `package.json` and `pnpm-lock.yaml`                                  | Repository package/lock state; no tracked source imports the declared libraries. `prepare` invokes externally provisioned `hk`.          | Repository-only; generated `node_modules` remains excluded.                                                 |

The shell and PowerShell profiles already redirect histories, caches,
completions, installs, and most runtime state to `.cache`, `.local/state`, and
`.local/share`. Do not broaden an enrollment to those roots. In particular,
exclude mise state/history, Cargo bins/registries, `Sheldon/TPM/Lazy/Mason`
repositories, shell histories, application databases, sockets, logs, and session
data.[`S5`] [`S8`]

## Sensitive Path Classification

No secret values were read for this inventory. Sensitive paths were classified
from names, Git metadata, filter declarations, and active references only.

| Path or group                                                                                                                                                                                                         | Evidence                                                                                   | Disposition                                                                                                                          |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------ |
| `.config/git/credentials`                                                                                                                                                                                             | Credential-store name; regular `100644`, zero-byte blob at current tip                     | Exclude and retain the separate reachable-history audit gate.                                                                        |
| `.ssh/config`                                                                                                                                                                                                         | SSH host/access metadata; regular `100644`                                                 | Exclude from public enrollment pending an approved sanitized replacement.                                                            |
| `.config/npm/npmrc`, `.config/spotify-tui/client.yml`, `AppData/Roaming/streamlink/config`, `.config/i3status-rust/config.toml`, `.config/git/config`, `.config/macchina/macchina.toml`, `.config/docker/config.json` | Existing Git clean filters remove secret or machine fields                                 | Replace/split. Direct `mise` tracking does not apply these legacy filters.[`S8`]                                                     |
| `.local/share/gnupg/gpg-agent.conf`                                                                                                                                                                                   | Intended filter rule is `.gnupg/gpg-agent.conf`, which does not match the tracked XDG path | Replace/split exact configuration; never enroll the containing GnuPG state tree.                                                     |
| `.config/{himalaya,meli,ncspot,spotifyd}/**`, `.config/bigquery/bigqueryrc`                                                                                                                                           | Account-capable or machine/project configuration by path and application role              | Treat as sensitive review items; enroll only public settings after split.                                                            |
| `.config/gh/config.yml`                                                                                                                                                                                               | Account preference file, not the usual token store                                         | Eligible only after the content audit confirms no reusable credential. Do not infer safety from filename alone.                      |
| `*.local.toml`, machine overlays, credential paths referenced by environment setup                                                                                                                                    | Deliberately local configuration/input                                                     | Exclude. `mise` also hard-excludes local TOML from history, but the migration policy is stricter than the built-in exclusions.[`S8`] |

Do not rely on the public legacy tip being sanitized. Git clean filters can
leave a safe blob while the live writable file contains omitted fields, and the
work machine's modified `npmrc` has not been inspected here.

## Hard-Coded Machine and Checkout Paths

| Path(s)                                                                                                                    | Coupling                                                                                         | Disposition                                                                                       |
| -------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------- |
| `.config/alacritty/alacritty.windows.toml`                                                                                 | Literal current Windows home in import and working directory                                     | Template or use home-relative/configuration-root resolution.                                      |
| `.config/clipcat/*.toml`                                                                                                   | Literal Linux home and `UID` `1000` runtime paths                                                | Template from `home/runtime` directory.                                                           |
| `.config/emscripten/config`                                                                                                | Literal `/home/bryan` plus mise `latest` install path                                            | Regenerate per machine; do not enroll live file.                                                  |
| `.config/helix/languages.toml`                                                                                             | Literal `/home/bryan/src/...` debugger checkout                                                  | Template or provision a discoverable `command/path.`                                              |
| `.config/X11/xresources`                                                                                                   | Literal `/home/bryan/src/...` theme include                                                      | Template or vendor theme.                                                                         |
| `.config/systemd/user/emacs.service`, `spotifyd.service`                                                                   | Literal `/home/bryan`; other units use `/home/%u`, which still assumes a conventional Linux home | Template with the actual home or use executable discovery where supported.                        |
| `.config/wget/wgetrc`                                                                                                      | Literal `/home/bryan` cache path                                                                 | Replace with a portable cache path or template.                                                   |
| `.local/bin/run-as-cron`                                                                                                   | Literal `/home/bryan/.cron.env`                                                                  | Template; keep environment input local.                                                           |
| Three Windows task XML files                                                                                               | Exported host/account identity, `SID` metadata, and fixed command locations                      | Regenerate for each host; values are intentionally not repeated here.                             |
| `.config/nu/config.toml`, `.config/shell/aliases.sh`, `.config/git/dotfiles.*`, `.local/bin/install-dotfiles`, `README.md` | Old home-root Git worktree (`~/.git` or an inconsistent `~/config` Git directory)                | Replace with mise setup-history commands or keep repository-only documentation.                   |
| `.config/git/config`, `.config/kitty/kitty.conf`, `.config/alacritty/alacritty.common.toml`, several symlinks              | Fixed `~/src/github.com/...` dependency layout                                                   | Provision exact repositories at that layout or replace with packaged/vendored sources.            |
| `.config/shell/env.sh`, `.config/herdr/config.toml`, `.local/bin/ssnz`                                                     | Home-relative `~/src/localhost` project layout                                                   | Profile-specific but portable within a home; keep only on machines using that project convention. |

## Work-Machine Delta Reconciliation

The handoff captured the work machine at `a705e60`, while current `main` is
`dca1b12`; the only committed tree change between them is
`.config/hk/config.pkl`. The work machine also had four uncommitted paths.[`S7`]

| Work-machine path                                                                                | Current tree role                                            | Required pre-adoption action                                                                                                                          |
| ------------------------------------------------------------------------------------------------ | ------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| `.config/npm/npmrc`                                                                              | Regular canonical configuration with a legacy clean filter   | Inspect securely, split any local/auth fields, and merge only reviewed public settings. Do not overwrite it.                                          |
| `AppData/Local/Packages/Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe/LocalState/settings.json` | Tracked symlink to `.config/windows/wind-term-settings.json` | Recheck whether the app replaced the link. Compare its bytes with the canonical source and stable channel, then choose the approved `source/variant.` |
| `AppData/Roaming/harper-ls/dictionary.txt`                                                       | Tracked symlink to `.config/harper-ls/dictionary.txt`        | Recheck type and merge dictionary additions into the canonical source without discarding either side.                                                 |
| `AppData/Roaming/topgrade.toml`                                                                  | Tracked symlink to `.config/topgrade/topgrade.toml`          | Recheck type and merge reviewed settings into the canonical source.                                                                                   |

A modified index entry at a symlink path proves that the redirect entry itself
diverged; normal writes through an intact link would modify the tracked target
instead. The handoff did not capture enough metadata to assert whether each was
replaced by a regular file or pointed elsewhere, so type must be rechecked.

The work machine's `.config/mise/config.local.toml` and
`config.windows.local.toml`, partial mise history repository, caches, and
watcher/service state are machine state, not legacy enrollment candidates.
Preserve them for reconciliation/diagnosis but keep them out of setup history.

## Platform Profile

| Profile         | Tree evidence                                                                                                                                                                                                          | Recommended enrollment boundary                                                                        |
| --------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| Shared          | CLI/editor/tool configurations, shell common files, mise declarations                                                                                                                                                  | Exact portable files, with app-specific sensitive exclusions.                                          |
| Windows x64     | PowerShell, `GlazeWM`, Komorebi, `whkd`, `Zebar`, Windows `Terminal/WinGet` sources, `AppData` redirects, Task Scheduler exports; this inspection host is Windows and the handoff records mise `2026.9.10 windows-x64` | `os = windows` plus optional `home/work` profile; generate destinations and tasks per account.         |
| Git `Bash/MSYS` | Shell branches, native-symlink environment setting, `Mintty`, Windows clipboard aliases                                                                                                                                | Windows profile with a separate Git Bash capability/profile where behavior differs from PowerShell.    |
| WSL/Linux       | `browser-wsl.sh`, `wsl.conf`, `/mnt/c` aliases, Linux shell configurations                                                                                                                                             | `os = linux` plus a `wsl` profile; WSL is not a separate mise OS selector.                             |
| Linux X11       | X11, `i3`, `bspwm`, `sxhkd`, `picom`, `redshift`, `xbindkeys`, `autostart`                                                                                                                                             | Linux graphical profile; external `/usr/share` and `/etc` deployment through bootstrap.                |
| Linux Wayland   | Sway and `xdg-desktop-portal`                                                                                                                                                                                          | Linux graphical profile; do not assume X11 service/link set.                                           |
| Linux systemd   | Nineteen user unit/link entries                                                                                                                                                                                        | Linux/systemd profile with explicit service `apply/enable.`                                            |
| macOS residual  | Darwin branches and commands in shared shell files plus Homebrew settings; no dedicated macOS path tree                                                                                                                | Keep guarded shared branches, but do not infer a complete supported macOS profile from this inventory. |

The minimum practical split is shared + Windows + Linux, with WSL and graphical
session/service profiles layered where needed. Work-specific settings remain
local or use a later approved profile, never an implicit copy from the home
machine.

## Migration Gates Produced by This Inventory

1. Repair the malformed `Stylua` mode before generating any enrollment manifest.
2. Approve exact regular-file families from the ledger; do not track `.config`,
   `.local`, `AppData`, or `HOME` broadly.
3. Resolve every `Replace/split` and sensitive row before first checkpoint;
   legacy clean filters are not a fallback.
4. Choose one representation for each link class and Windows destination, then
   prototype Windows link/junction/copy behavior.
5. Replace literal home, `UID`, `SID`, and old-checkout paths with profile-aware
   templates or bootstrap declarations.
6. Declare every approved external repository/service edge; leave generated
   clones, installs, caches, and state not enrolled.
7. Reconcile the four work-machine modifications and its one-commit baseline lag
   before adoption.
8. Enroll the named live mise `config.toml` or deliberately consolidate its
   wrapper declaration; do not lose the only active copy.

## Sources and Method

- [`S1`] Read-only workspace inspection at `dca1b12`: `git status`,
  `git config --show-origin`, and PowerShell filesystem metadata for every
  symlink plus the named live exception.
- [`S2`] Read-only `git ls-files -s`, `git ls-tree -r HEAD`,
  `git submodule status`, and [`.gitmodules`](../../../.gitmodules). Mode and
  count totals were reconciled to 421; duplicate blob IDs were grouped to
  identify the malformed `Stylua` entry.
- [`S3`] [Migration map](https://github.com/bryan-hoang/dotfiles/issues/345),
  [research ticket](https://github.com/bryan-hoang/dotfiles/issues/349), and
  ignored project-local [`GLOSSARY.md`](../../../GLOSSARY.md).
- [`S4`] Git,
  [file modes in `git fast-import`](https://git-scm.com/docs/git-fast-import#Documentation/git-fast-import.txt-Inlinedataformat).
- [`S5`] mise,
  [configuration hierarchy](https://mise.jdx.dev/configuration.html), plus the
  tracked [mise instructions](../../../.config/mise/AGENTS.md) and
  [`conf.d`](../../../.config/mise/conf.d/).
- [`S6`] mise,
  [dotfile modes, platform destinations, tracking symlinks, and Windows behavior](https://mise.jdx.dev/dotfiles.html).
- [`S7`] A private work-machine handoff note, read without inspecting any secret
  value.
- [`S8`] Sibling primary-source report,
  [mise `v2026.9.10` enrollment, encryption, and path semantics](02-enrollment-encryption-and-path-semantics.md),
  and
  [setup conversion constraints](01-setup-conversion-and-adoption-constraints.md).

Content searches were limited to tracked configuration and scripts needed to
trace references. `.config/git/credentials`, `.ssh/config`, and secret-capable
machine inputs were classified by path and metadata rather than content. No
state-changing Git, mise, service, submodule, or inventory command was run; the
only write was this report.
