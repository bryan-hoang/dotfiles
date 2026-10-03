# Unix and Desktop Enrollment Matrix

Decision date: 2026-09-18

This matrix is the confirmed answer to
[Review Unix and desktop enrollment](https://github.com/bryan-hoang/dotfiles/issues/354).
It applies the
[sensitive-data policy](https://github.com/bryan-hoang/dotfiles/issues/350),
[link and dependency policy](https://github.com/bryan-hoang/dotfiles/issues/351),
[core matrix](07-core-and-repository-root-enrollment.md), and
[Windows matrix](08-windows-and-appdata-enrollment.md) to the Unix, WSL,
native-Linux, X11, service, shell, theme, and external-asset portion of the
[legacy inventory](../research/04-legacy-path-and-dependency-inventory.md).

## Reading the Matrix

- `Enroll` records an exact reviewed public plaintext canonical source in mise
  history. Encryption is off everywhere.
- `Managed` derives a not-enrolled destination from one canonical source or
  dependency. Writable destinations require verified links and never fall back
  to copies. Read-only destinations may use replaceable copies.
- `Local` remains excluded and is provisioned or selected on each machine.
- `Repository-only` keeps a sanitized, inert legacy record at the setup-root
  namespace. It is not a deployment source.
- `Remove` omits the path from the converted tip. Append-only ancestry retains
  its old object.
- `On` and `off` mean `autosave = true` and `autosave = false`.
- A local capability is an excluded opt-in. Public capability names contain no
  machine, distribution, account, endpoint, or private topology value.

The [complete enrollment approval](10-approved-enrollment-inventory.md) uses
coarse history streams: shared sources are `unvariant`, Windows sources use one
OS-only stream, and Linux sources use one OS-only stream. Composable `wsl`,
`native-linux`, `systemd`, and application capabilities gate deployment rather
than creating competing history streams.

Native Linux CLI and systemd support remains active. Native Linux X11 is
planning context only: its exact package, path, and display-session adapters
require a separate distro-specific approval, so this migration has zero active
X11 enrollment roots or deployment units. A later adapter may use the single
`linux/x86_64` plus `x11` profile selector for X11-only sources. `WSLg` desktop
management, Wayland, macOS, BSD, and other architectures are not supported. Git
Bash remains owned by the Windows and core matrices.

## Controlling Policies

| Class                             | Enrollment and review                                                                                    | Destination and mode                                                                       | Dependency and failure rule                                                                              |
| --------------------------------- | -------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------- |
| Ordinary public file              | Exact / on                                                                                               | Native mode `0644` unless noted                                                            | Matching application or capability only                                                                  |
| Sensitive-capable template        | Exact mirrored source / off; field allowlist and value-suppressing review before baseline and every save | Generated destination excluded; mode `0644`                                                | Unknown fields or missing local inputs block only its application unit                                   |
| Directly invoked script           | Exact mirrored regular source / on                                                                       | Bootstrap deploys mode `0755`; source and repository-only legacy record are non-executable | Missing interpreter or command blocks the matching capability before writes                              |
| System source                     | Exact public source / on unless it is a control template                                                 | Privileged bootstrap owns destination, root ownership, and explicit mode                   | Wrong owner, mode, distro path, or unavailable elevation blocks before writes                            |
| Full repository dependency        | Not enrolled                                                                                             | Clean checkout under `~/src/github.com/<owner>/<repo>`; HTTPS origin; no `ref`             | Missing, dirty, or wrong-origin checkout blocks its capability; updates are explicit clean fast-forwards |
| Managed dependency asset          | Not enrolled independently                                                                               | Verified link preferred; read-only copy fallback allowed and reapplied after updates       | Consumer applies only after the complete dependency passes preflight                                     |
| Local input or state              | Excluded                                                                                                 | Application-local path or generated state                                                  | Never copied to planning artifacts or public history                                                     |
| Repository-only executable legacy | Not enrolled                                                                                             | No live destination; normalized non-executable                                             | Anchored legacy-source guard forbids deployment references                                               |

Broad enrollment of `.config`, `.local`, `HOME`, or mise `dotfiles` remains
forbidden. Generated application directories, caches, sockets, logs, histories,
plugin stores, service state, `Herdr` sessions, and package-manager state remain
excluded.

## Supported Environment Handoffs

These rows settle platform behavior in paths whose coverage owner remains the
core or Windows matrix. They are cross-references, not duplicate ownership.

| Owning matrix path or class                                              | Settled Unix/desktop result                                                                                                                                                                               | Capability and activation                                                                                                                                   | Rationale                                                                                                                                        |
| ------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| Core-owned `.config/shell/**`, `.config/bash/**`, and root shell aliases | Keep the shared Bash/POSIX sources; remove dead macOS, home-checkout, tmux, `Zellij`, `ssnz`, Lemonade, Doom, Vim, Soar, and custom `MOTD` behavior; retain guarded WSL behavior and dormant X11 branches | Shared, `wsl`, `native-linux`; X11 inactive                                                                                                                 | Source ownership and autosave remain in the core matrix; no X11 branch may activate in this migration                                            |
| Core-owned `.config/wezterm/**`                                          | Retain shared sources for Windows; the planned native-Linux terminal use is deferred                                                                                                                      | Windows owner unchanged; native X11 inactive                                                                                                                | `Alacritty` and Rio remain Windows-only optional applications; Kitty retires; a future distro adapter may reactivate the reviewed WezTerm plan   |
| Core-owned `.config/herdr/config.toml`                                   | Replace with canonical `~/.config/mise/dotfiles/.config/herdr/config.toml.tmpl`                                                                                                                           | Generate `%APPDATA%/herdr/config.toml` on Windows and `~/.config/herdr/config.toml` on WSL/native Linux; source exact/on, outputs excluded/read-only `0644` | One template selects PowerShell on Windows, Zsh on Linux, shared `~/src/localhost/herdr-worktrees`, and excluded local Kitty-graphics capability |
| Core-owned `.config/doom/**`                                             | Repository-only inert legacy                                                                                                                                                                              | No runtime or service                                                                                                                                       | `Herdr/Neovim` workflow retires Doom Emacs and its external runtime                                                                              |
| Windows-owned `.config/windows/wsl.conf`                                 | Repository-only inert legacy; new canonical source at `~/.config/mise/dotfiles/system/etc/wsl.conf`                                                                                                       | `wsl`; privileged copy to `/etc/wsl.conf`, root-owned `0644`; manual WSL restart                                                                            | Enables systemd and interop while disabling Windows PATH appending without using the legacy path as a source                                     |
| Windows-owned `.config/windows/wind-term-settings.json`                  | Keep the generic public WSL profile entry                                                                                                                                                                 | Existing `Windows`; Terminal channel destinations remain exactly as matrix 08 defines                                                                       | `commandline = "wsl"` exposes no distribution identity and launches the local default distribution                                               |
| Windows Lemonade service handoff                                         | Do not generate a service; remove the legacy XML as matrix 08 already requires                                                                                                                            | None                                                                                                                                                        | Direct WSL interop and `OSC` 52 replace unauthenticated, unencrypted Lemonade TCP transport                                                      |
| Core-owned `.config/mpv/{input.conf,mpv.conf}`                           | Keep; external plugin payload is defined below for Windows                                                                                                                                                | Windows `mpv`; never WSL; native X11 inactive                                                                                                               | One shared behavior source with an atomic Windows plugin realization; the reviewed X11 use remains deferred context                              |
| Core-owned `.config/lsd/config.yaml` and `.config/rio/config.toml`       | Keep; managed themes are defined below                                                                                                                                                                    | LSD matching consumer; Rio Windows-only                                                                                                                     | The deferred native-Linux plan uses WezTerm, so Rio has no Linux application unit                                                                |

## WSL, Shells, and CLI Configuration

| Legacy path or exact class                                                                        | Disposition                                                 | Canonical source                                            | Managed destination                                                                                        | Capability                           | Autosave / review | Mode                              | Dependency, activation, and rationale                                                                                                    |
| ------------------------------------------------------------------------------------------------- | ----------------------------------------------------------- | ----------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- | ------------------------------------ | ----------------- | --------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| `.config/zsh/.zprofile`, `.zshrc`, `.zshenv`                                                      | Enroll canonical files                                      | Native live paths                                           | Verified `~/.zshenv` compatibility link with no copy fallback selects `ZDOTDIR`; other files remain native | `wsl` or `native-linux`; Zsh         | Exact / on        | `0644`                            | Distro-provisioned Zsh and mise-provisioned Sheldon; Zsh is the Unix default                                                             |
| `.config/zsh/.zlogout`                                                                            | Enroll sourced file                                         | Native live path                                            | Same path                                                                                                  | Zsh                                  | Exact / on        | Normalize legacy `0755` to `0644` | Sourced through Zsh; no execute bit                                                                                                      |
| `.config/sheldon/zsh/plugins.toml`                                                                | Enroll declaration                                          | Native live path                                            | Same path                                                                                                  | Zsh                                  | Exact / on        | `0644`                            | `sheldon` uses the official mise registry; Sheldon owns generated plugin repositories outside history                                    |
| `.local/share/zsh/completions/git-extras-completion.zsh`                                          | Replace legacy link with dependency destination             | `~/src/github.com/tj/git-extras`                            | Same completion path                                                                                       | Zsh + `git-extras`                   | Not enrolled      | `0644`                            | Full clean HTTPS checkout; verified link or read-only copy; explicit repo updates require reapply                                        |
| `.config/blesh/init.sh`                                                                           | Enroll                                                      | Native live path                                            | Same path                                                                                                  | Linux Bash                           | Exact / on        | `0644`                            | Full `akinomyoga/ble.sh` HTTPS checkout builds and installs generated output into `$XDG_DATA_HOME/blesh`; rebuild after explicit updates |
| `.local/bin/browser-wsl.sh`                                                                       | Replace with safe regular source; deploy executable         | `~/.config/mise/dotfiles/.local/bin/browser-wsl.sh`         | `~/.local/bin/browser-wsl.sh`                                                                              | `wsl`                                | Exact / on        | Source `0644`; destination `0755` | Validate WSL and Windows PowerShell; pass arguments without shell interpolation; no Lemonade dependency                                  |
| `.config/nix/nix.conf`                                                                            | Enroll                                                      | Native live path                                            | Same path                                                                                                  | `wsl` or `native-linux`; Nix         | Exact / on        | `0644`                            | Nix application is an opt-in dependency; cache and profile state stay local                                                              |
| `.config/vscode/server-env-setup`                                                                 | Replace with cleaned read-only source                       | `~/.config/mise/dotfiles/.config/vscode/server-env-setup`   | `~/.vscode-server/server-env-setup` and `~/.vscode-server-insiders/server-env-setup`                       | `wsl` or native Linux VS Code Remote | Exact / on        | `0644`                            | Remove diagnostic shell/PATH output; VS Code processes the POSIX shell script and does not require execute mode                          |
| `.local/bin/docuum`                                                                               | Remove legacy installed-binary link                         | Existing ancestry only                                      | None; the mise shim supplies the command                                                                   | Native Linux `docuum`                | Not enrolled      | None                              | Official x86-64 release replaces the Cargo-bin link                                                                                      |
| `.local/bin/xdg-ninja`                                                                            | Replace legacy link with dependency destination             | `~/src/github.com/b3nj5m1n/xdg-ninja`                       | `~/.local/bin/xdg-ninja`                                                                                   | Linux `xdg-ninja`                    | Not enrolled      | Destination `0755`                | Full clean HTTPS checkout; verified link preferred, executable copy fallback gets mode `0755` and must be reapplied after updates        |
| `.config/brewfile/Brewfile`                                                                       | Repository-only inert                                       | Existing setup-root path                                    | None                                                                                                       | None                                 | Not enrolled      | `0644`                            | Behavior-free residual Homebrew file; no macOS profile                                                                                   |
| `.config/emscripten/config`                                                                       | Repository-only sanitized legacy; live file local/generated | Existing setup-root path with literal machine paths removed | Application-generated native path if Emscripten is locally installed                                       | Local                                | Excluded          | `0644`                            | Generated toolchain path state is not portable                                                                                           |
| `.config/texlive.profile`                                                                         | Repository-only installer snapshot                          | Existing setup-root path                                    | None                                                                                                       | None                                 | Not enrolled      | `0644`                            | Fixed architecture/system install snapshot; TeX installation remains outside the retained user-authored TeX data decision                |
| `.config/vim/vimrc`                                                                               | Repository-only inert                                       | Existing setup-root path                                    | None                                                                                                       | None                                 | Not enrolled      | `0644`                            | Neovim replaces Vim; do not bootstrap `amix/vimrc`                                                                                       |
| `.config/emacs`                                                                                   | Remove legacy link                                          | Existing ancestry only                                      | None                                                                                                       | None                                 | Not enrolled      | None                              | Doom runtime retires; core-owned Doom configuration becomes inert                                                                        |
| `.config/rust-motd/config.toml`, `.config/macchina/macchina.toml`                                 | Repository-only sanitized legacy                            | Existing setup-root paths with identity fields removed      | None                                                                                                       | None                                 | Not enrolled      | `0644`                            | Custom SSH `MOTD` and machine disclosure retire                                                                                          |
| `.config/soar/config.toml`                                                                        | Repository-only inert                                       | Existing setup-root path                                    | None                                                                                                       | None                                 | Not enrolled      | `0644`                            | Soar and its architecture-specific package indexes are not supported                                                                     |
| `.local/bin/run-as-cron`                                                                          | Repository-only sanitized inert legacy                      | Existing setup-root path with literal HOME removed          | None                                                                                                       | None                                 | Not enrolled      | Normalize to `0644`               | No caller; secret-capable `cron` environment remains local                                                                               |
| `.local/bin/update-alternatives-clang`, `.local/bin/update-golang`                                | Repository-only inert maintenance                           | Existing setup-root paths                                   | None                                                                                                       | None                                 | Not enrolled      | Normalize to `0644`               | Privileged general package bootstrap is outside this migration                                                                           |
| `.local/bin/ssnz`                                                                                 | Repository-only inert legacy                                | Existing setup-root path                                    | None                                                                                                       | None                                 | Not enrolled      | Normalize to `0644`               | `Herdr` workspaces replace `tmux/Zellij` session selection                                                                               |
| `.config/tmux/tmux.conf.local`, `.config/zellij/config.kdl`, `.config/zellij/layouts/default.kdl` | Repository-only inert legacy                                | Existing setup-root paths                                   | None                                                                                                       | None                                 | Not enrolled      | `0644`                            | `Herdr` replaces both multiplexers; plugin and remote-WASM state is not restored                                                         |
| `.config/tmux/tmux.conf`, `.config/zellij/themes/catppuccin.kdl`                                  | Remove legacy links                                         | Existing ancestry only                                      | None                                                                                                       | None                                 | Not enrolled      | None                              | No `tmux/Zellij` dependency checkout remains                                                                                             |

## Shared Application Descendants and External Assets

| Legacy path or exact class                                                    | Disposition                                     | Canonical source                   | Managed destination                                                                            | Capability                  | Autosave / review                        | Mode                                                          | Dependency, activation, and rationale                                                                                                       |
| ----------------------------------------------------------------------------- | ----------------------------------------------- | ---------------------------------- | ---------------------------------------------------------------------------------------------- | --------------------------- | ---------------------------------------- | ------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| `.config/alacritty/alacritty.common.toml`                                     | Enroll after portable imports                   | Native live path                   | Same path, consumed by the Windows template                                                    | Windows `alacritty`         | Exact / on                               | `0644`                                                        | Full `catppuccin/alacritty` checkout supplies the theme; no native-Linux `Alacritty` unit                                                   |
| `.config/alacritty/alacritty.toml`                                            | Repository-only inert Unix variant              | Existing setup-root path           | None                                                                                           | None                        | Not enrolled                             | `0644`                                                        | The reviewed but inactive native-X11 plan uses WezTerm rather than `Alacritty`                                                              |
| `.config/helix/languages.toml`                                                | Enroll after removing both debugger blocks      | Native live path                   | Same path and Windows Helix directory destination owned by matrix 08                           | Shared Helix                | Exact / on                               | `0644`                                                        | Keeps portable Rust/JavaScript language behavior without `codelldb` or node-debug checkout                                                  |
| `.config/lsd/colors.yaml`                                                     | Replace legacy link with dependency destination | `~/src/github.com/catppuccin/lsd`  | Same path                                                                                      | Matching LSD application    | Not enrolled                             | `0644`                                                        | Full clean HTTPS checkout; verified link or read-only copy                                                                                  |
| `.config/rio/themes/catppuccin-mocha.toml`                                    | Replace legacy link with dependency destination | `~/src/github.com/catppuccin/rio`  | Same path                                                                                      | Windows `rio`               | Not enrolled                             | `0644`                                                        | Full clean HTTPS checkout; completes the matrix-08 Rio junction                                                                             |
| `.config/mpv/script-opts/thumbfast.conf`, `.config/mpv/scripts/thumbfast.lua` | Replace links with dependency destinations      | `~/src/github.com/po5/thumbfast`   | Same paths                                                                                     | Windows or native-X11 `mpv` | Not enrolled                             | `0644`                                                        | Full clean HTTPS checkout; configuration and interpreted plugin code deploy together                                                        |
| `.config/mpv/script-opts/uosc.conf`                                           | Replace link and deploy full `uosc` payload     | `~/src/github.com/tomasklaen/uosc` | Same path plus generated `scripts/uosc*` and required fonts below the `MPV` configuration root | Windows or native-X11 `mpv` | Not enrolled; generated staging excluded | Files `0644`; active x86-64 helper executable `0755` on Linux | Build only the active x86-64 target into excluded staging without dirtying the checkout; atomic `MPV` preflight covers the complete payload |

The `Alacritty`, LSD, Rio, `Dunst`, `Xresources`, `Rofi`, and GTK theme
decisions use full repositories by explicit choice. They are not applications of
the static vendoring exception.

## Systemd and User Services

| Legacy path or exact class                                                                                                                                          | Disposition                            | Canonical source                                                          | Managed destination                                | Capability                                       | Autosave / review    | Mode         | Dependency, activation, and rationale                                                                                                                |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------- | ------------------------------------------------------------------------- | -------------------------------------------------- | ------------------------------------------------ | -------------------- | ------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| Built-in mise history watcher                                                                                                                                       | Keep declaration; activation deferred  | Core-owned mise control                                                   | mise-generated Linux user service                  | `systemd`; later automatic-sync gate             | Control source / off | Tool-managed | Ticket 13 decides when validation permits enabling it                                                                                                |
| `.config/systemd/user/docuum.service`                                                                                                                               | Replace with portable enrolled unit    | Native live path after replacing executable path                          | Same path                                          | `native-linux` + `systemd` + optional `docuum`   | Exact / on           | `0644`       | Official x86-64 `Docuum` release through mise GitHub backend; Docker daemon preflight; bootstrap daemon-reloads and enables only this unit           |
| `.config/systemd/user/spotifyd.service`                                                                                                                             | Replace with portable enrolled unit    | Native live path after replacing HOME and invalid user-target assumptions | Same path                                          | `native-linux` + `systemd` + optional `spotifyd` | Exact / on           | `0644`       | Official x86-64 full `Spotifyd` release through mise with `MPRIS/audio` support; account configuration stays local; bootstrap enables only this unit |
| `.config/systemd/user/ssh-agent.service`                                                                                                                            | Replace with portable enrolled unit    | Native live path                                                          | Same path                                          | (`wsl` or `native-linux`) + `systemd`            | Exact / on           | `0644`       | System `OpenSSH` client; `%t/ssh-agent.socket`; remove fixed `DISPLAY`; bootstrap enabling replaces legacy activation link                           |
| `.config/systemd/user/atuin.service`                                                                                                                                | Repository-only inert legacy           | Existing setup-root path                                                  | None                                               | None                                             | Not enrolled         | `0644`       | Enrolled `Atuin` configuration owns daemon `autostart`                                                                                               |
| `.config/systemd/user/emacs.service`, `.config/systemd/user/lemonade.service`, `.config/systemd/user/tmux.service`                                                  | Repository-only sanitized inert legacy | Existing setup-root paths with literal HOME removed                       | None                                               | None                                             | Not enrolled         | `0644`       | Corresponding runtimes or service models retire                                                                                                      |
| `.config/systemd/user/gpg-agent.service`, `gpg-agent.socket`, `gpg-agent-browser.socket`, `gpg-agent-extra.socket`, `gpg-agent-ssh.socket`                          | Repository-only sanitized inert legacy | Existing setup-root paths with generated socket components removed        | None                                               | None                                             | Not enrolled         | `0644`       | Distribution-provided GPG Agent startup and sockets replace custom units; GPG does not act as SSH Agent                                              |
| `.config/systemd/user/xdg-desktop-portal.service.d/override.conf`                                                                                                   | Repository-only inert legacy           | Existing setup-root path                                                  | None                                               | None                                             | Not enrolled         | `0644`       | Real `i3` identity replaces the false GNOME override                                                                                                 |
| `.config/systemd/user/default.target.wants/atuin.service`, `default.target.wants/ssh-agent.service`, `sockets.target.wants/gpg-agent{,-browser,-extra,-ssh}.socket` | Remove all six activation links        | Existing ancestry only                                                    | Explicit bootstrap service enabling where retained | Matching unit                                    | Not enrolled         | None         | Copying links is not service activation; only SSH Agent remains from this link set                                                                   |

Service runtime state, sockets, logs, Spotify credentials, `Atuin` history, GPG
keys/trust, and SSH keys remain local. `Herdr` starts on demand and has no login
service.

## Deferred Native Linux X11 Context

Every row in this section records the reviewed disposition for a future
distro-adapter effort. None is an active enrollment, package, repository,
system-file, destination, or activation declaration in this migration. The
[approved inventory](10-approved-enrollment-inventory.md) keeps the 22 regular
source candidates sanitized and inert at the repository-only legacy namespace
and omits the 10 legacy symlinks from the converted tip.

| Legacy path or exact class                                                                                  | Disposition                                               | Canonical source                                                 | Managed or system destination                                                                | Capability                                                | Autosave / review                                   | Mode                                                       | Dependency, activation, and rationale                                                                                                                                                                                      |
| ----------------------------------------------------------------------------------------------------------- | --------------------------------------------------------- | ---------------------------------------------------------------- | -------------------------------------------------------------------------------------------- | --------------------------------------------------------- | --------------------------------------------------- | ---------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `.config/X11/xinitrc`, `xserverrc`, `xsession`                                                              | Replace with regular mirrored sources; deploy executables | `~/.config/mise/dotfiles/<same HOME-relative-path>`              | Matching native paths                                                                        | `native-linux` + `x11`                                    | Exact files / on                                    | Sources `0644`; destinations `0755`                        | `Xorg/startx`; use `i3`; `xserverrc` uses `-nolisten tcp`; import only allowlist-approved display/session values into systemd                                                                                              |
| `.config/X11/xsession.desktop`                                                                              | Enroll system deployment source                           | Native live path                                                 | Preflighted distro session directory such as `/usr/share/xsessions/xsession.desktop`         | `native-linux` + `x11` + local display-manager capability | Exact / on                                          | Source and destination `0644`, root-owned destination      | Supports display-manager login in addition to `startx`; distro path mismatch blocks only display-manager installation                                                                                                      |
| `.config/X11/xorg.conf.d/40-libinput.conf`                                                                  | Enroll system deployment source                           | Native live path                                                 | `/etc/X11/xorg.conf.d/40-libinput.conf`                                                      | `native-linux` + `x11` + local touchpad capability        | Exact / on                                          | Source `0644`; root-owned destination `0644`               | Hardware preflight is mandatory; privileged deployment is atomic                                                                                                                                                           |
| `.config/X11/xresources`                                                                                    | Enroll after replacing absolute include                   | Native live path                                                 | Same path; managed relative theme and local DPI includes below `~/.config/X11/xresources.d/` | `native-linux` + `x11`                                    | Exact / on; DPI local/excluded                      | `0644`                                                     | Full `catppuccin/xresources` checkout; `xrdb` activation in `xinitrc`; no HOME literal                                                                                                                                     |
| `.config/i3/config`, `.config/i3/config.d/i3.conf`                                                          | Enroll focused `i3` configuration                         | Native live paths                                                | Same paths                                                                                   | `native-linux` + `x11`                                    | Exact files / on                                    | `0644`                                                     | Keep workspaces, WezTerm, `Rofi`, status, locking, notifications, compositor, hardware helpers, and one wallpaper action; remove stale rules, `Ringboard`, examples, `gsd-xsettings`, and duplicate idle/wallpaper actions |
| `.config/i3status-rust/config.toml`                                                                         | Replace with sanitized template                           | `~/.config/mise/dotfiles/.config/i3status-rust/config.toml.tmpl` | Generated native configuration                                                               | `native-linux` + `x11`                                    | Exact / off; allowlist and value-suppressing review | `0644`; destination excluded                               | Generic focused-window, disk, memory, CPU, load, sound, uptime, and time blocks; Docker, battery, music, and Bluetooth are local capabilities; device identifiers never enter the source                                   |
| `.local/bin/i3lock-color`                                                                                   | Replace with corrected regular source; deploy executable  | `~/.config/mise/dotfiles/.local/bin/i3lock-color`                | `~/.local/bin/i3lock-color`                                                                  | `native-linux` + `x11`                                    | Exact / on                                          | Source `0644`; destination `0755`                          | `xss-lock` and compatible `i3lock-color` package; remove `GPG/PAM` behavior and use a trap that always restores `Dunst`                                                                                                    |
| `.config/rofi/config.rasi`                                                                                  | Replace legacy link with dependency destination           | `~/src/github.com/dracula/rofi`                                  | Same path                                                                                    | `native-linux` + `x11`                                    | Not enrolled                                        | `0644`                                                     | Full clean HTTPS checkout; `Rofi` is the retained launcher                                                                                                                                                                 |
| `.config/dunst/dunstrc`                                                                                     | Enroll                                                    | Native live path                                                 | Same path                                                                                    | `native-linux` + `x11`                                    | Exact / on                                          | `0644`                                                     | `Dunst` package; `i3` starts it once                                                                                                                                                                                       |
| `.config/dunst/dunstrc.d/mocha.conf`                                                                        | Replace legacy link with dependency destination           | `~/src/github.com/catppuccin/dunst`                              | Same path                                                                                    | `native-linux` + `x11`                                    | Not enrolled                                        | `0644`                                                     | Full clean HTTPS checkout; verified link or read-only copy                                                                                                                                                                 |
| `.config/picom/picom.conf`                                                                                  | Enroll                                                    | Native live path                                                 | Same path                                                                                    | `native-linux` + `x11`                                    | Exact / on                                          | `0644`                                                     | `Picom` build must support `GLX` `dual_kawase`; failed graphics preflight blocks compositor deployment                                                                                                                     |
| `.config/feh/themes`                                                                                        | Enroll                                                    | Native live path                                                 | Same path                                                                                    | `native-linux` + `x11`                                    | Exact / on                                          | `0644`                                                     | One `Feh` invocation uses an excluded local wallpaper when present and a public solid-color fallback otherwise                                                                                                             |
| `.config/redshift.conf`                                                                                     | Enroll after removing coordinates                         | Native live path                                                 | Same path                                                                                    | `native-linux` + `x11` + optional `redshift`              | Exact / on                                          | `0644`                                                     | `GeoClue` provider only; `dex` launches preflighted distro `Redshift/GeoClue` desktop entries; no `/etc/geoclue` edits                                                                                                     |
| `.config/gtk-3.0/settings.ini`, `.config/gtk-4.0/settings.ini`                                              | Enroll                                                    | Native live paths                                                | Same paths                                                                                   | `native-linux` + `x11`                                    | Exact files / on                                    | `0644`                                                     | Full `dracula/gtk` dependency; Berkeley Mono remains an excluded local font prerequisite                                                                                                                                   |
| `.local/share/icons/Dracula-cursors`, `.local/share/icons/Dracula-dark`, `.local/share/themes/Dracula-dark` | Replace legacy links with dependency destinations         | `~/src/github.com/dracula/gtk`                                   | Same paths                                                                                   | `native-linux` + `x11`                                    | Not enrolled                                        | Directory/link modes from checkout; no independent history | Full clean HTTPS checkout; verified links preferred, read-only copy fallback allowed and reapplied after updates                                                                                                           |
| `.config/xdg-desktop-portal/portals.conf`                                                                   | Enroll after selecting GTK portal                         | Native live path                                                 | Same path                                                                                    | `native-linux` + `x11`                                    | Exact / on                                          | `0644`                                                     | `xdg-desktop-portal` and GTK backend; preserve real `i3` desktop identity                                                                                                                                                  |
| `.config/user-dirs.dirs`, `.config/user-dirs.locale`                                                        | Enroll declarative mappings                               | Native live paths                                                | Same paths                                                                                   | `native-linux` + `x11`                                    | Exact files / on                                    | `0644`                                                     | Standard HOME-relative user directories; only exact files, never directory contents                                                                                                                                        |
| `.local/share/applications/neovide.desktop`, `.local/share/icons/hicolor/128x128/apps/neovide.png`          | Enroll together                                           | Native live paths                                                | Same paths                                                                                   | `native-linux` + `x11` + `Neovide`                        | Exact files / on                                    | `0644`                                                     | `Neovide` and retained Neovim configuration; PNG is a reviewed runtime icon                                                                                                                                                |

Any future X11 capability requires verified distro-specific mise
`[bootstrap.packages]` entries for each retained command. The window and session
commands are `Xorg/startx`, `i3`, WezTerm, `Rofi`, `i3status-rust`, `xss-lock`,
and the compatible `i3lock` implementation. The desktop services are `Dunst`,
`Picom` with `GLX` blur support, `Feh`, Redshift, `GeoClue`, `dex`, the GTK
portal, `NetworkManager` tray, audio/media controls, brightness controls, and
`Flameshot`. Entries use `latest`; installation and upgrades remain explicit. A
manager or package not verified for the target distro fails preflight. In
particular, `i3status-rust` has no mise/Aqua registry entry or upstream release
binary and does not support Cargo installation; verified native package entries
such as `pacman:i3status-rust` are the supported mise route.

The Berkeley Mono Nerd Font and wallpaper image are excluded local assets.
Missing font blocks the X11 base. Missing wallpaper selects the public solid
fallback and does not block `i3`.

## Deferred XDG `autostart` Application Units

| Legacy path                                                                              | Disposition                                            | Canonical source or host input                            | Managed destination | Capability                                            | Autosave / review | Mode   | Dependency, activation, and rationale                                                     |
| ---------------------------------------------------------------------------------------- | ------------------------------------------------------ | --------------------------------------------------------- | ------------------- | ----------------------------------------------------- | ----------------- | ------ | ----------------------------------------------------------------------------------------- |
| `.config/autostart/brave-browser.desktop`                                                | Replace installed-file link with managed declaration   | Preflighted distro Brave desktop entry                    | Same path           | `native-linux` + `x11` + optional `brave`             | Not enrolled      | `0644` | `dex` activation; missing app blocks only Brave unit                                      |
| `.config/autostart/geoclue-demo-agent.desktop`, `.config/autostart/redshift-gtk.desktop` | Replace installed-file links with managed declarations | Preflighted distro `GeoClue` and Redshift desktop entries | Same paths          | `native-linux` + `x11` + optional `redshift`          | Not enrolled      | `0644` | One atomic Redshift unit; no system policy edits or coordinate fallback                   |
| `.config/autostart/protonvpn-app.desktop`                                                | Replace installed-file link with managed declaration   | Preflighted distro `ProtonVPN` desktop entry              | Same path           | `native-linux` + `x11` + optional `protonvpn`         | Not enrolled      | `0644` | `dex` activation; missing app blocks only `ProtonVPN` unit                                |
| `.config/autostart/thunderbird.desktop`                                                  | Enroll authored launcher                               | Native live path                                          | Same path           | `native-linux` + `x11` + optional `thunderbird`       | Exact / on        | `0644` | Thunderbird preflight; delayed login launch remains public behavior                       |
| `.config/autostart/wezterm.desktop`                                                      | Replace installed-file link with managed declaration   | Preflighted distro WezTerm desktop entry                  | Same path           | `native-linux` + `x11` + optional `wezterm-autostart` | Not enrolled      | `0644` | Independent from required terminal availability; missing app blocks only `autostart` unit |

No listed `autostart` unit is active in this migration. In a future approved
adapter, no optional unit may hold the `i3` base or another application's
destination. App-owned startup state outside these exact desktop entries stays
local.

## Retired Unix and Desktop Paths

| Legacy path or exact class                                              | Disposition                          | Destination | Mode / review                                    | Rationale                                                                                               |
| ----------------------------------------------------------------------- | ------------------------------------ | ----------- | ------------------------------------------------ | ------------------------------------------------------------------------------------------------------- |
| `.config/autorandr/settings.ini`                                        | Repository-only inert                | None        | `0644`; not enrolled                             | No retained `Autorandr` hook; Redshift no longer shares gamma handling with it                          |
| `.config/bspwm/bspwmrc`                                                 | Repository-only inert                | None        | Normalize to `0644`; sanitize stale asset paths  | `i3` is the only X11 window manager                                                                     |
| `.config/sxhkd/sxhkdrc`                                                 | Repository-only inert                | None        | `0644`; not enrolled                             | `bspwm` retires and `i3` owns key bindings                                                              |
| `.config/clipcat/**`                                                    | Repository-only sanitized inert      | None        | `0644`; remove literal `HOME/UID/runtime` values | Clipboard daemon and its absent activation retire                                                       |
| `.config/kitty/kitty.conf`                                              | Repository-only inert                | None        | `0644`; not enrolled                             | The reviewed native-X11 plan uses WezTerm; do not bootstrap `dracula/kitty` while that plan is inactive |
| `.config/pulse/daemon.conf`                                             | Repository-only inert                | None        | `0644`; not enrolled                             | Dated scheduler/audio tuning is not a portable `Pulse/PipeWire` baseline                                |
| `.config/pam-gnupg`                                                     | Repository-only sanitized inert      | None        | `0644`; remove key identifier                    | `PAM` GPG integration and privileged system setup retire                                                |
| `.config/xbindkeys/config`                                              | Repository-only behavior-free sample | None        | `0644`; not enrolled                             | No retained caller or meaningful custom binding                                                         |
| `.config/sway/config`                                                   | Remove legacy link                   | None        | Not enrolled                                     | Wayland is unsupported and the link incorrectly imports X11 `i3` behavior                               |
| `.config/sway/config.d/sway.conf`, `.config/sway/sway-via-bash.desktop` | Repository-only inert                | None        | `0644`; not enrolled                             | No Wayland profile or system session deployment                                                         |

## Full Repository Dependency Ledger

The active migration retains the non-X11 rows below. The four X11-only rows for
`catppuccin/xresources`, `catppuccin/dunst`, `dracula/gtk`, and `dracula/rofi`
are deferred context and produce no bootstrap declaration.

| Checkout                                 | Capability / consumer      | Managed output                                           | Update rule                                                            |
| ---------------------------------------- | -------------------------- | -------------------------------------------------------- | ---------------------------------------------------------------------- |
| `~/src/github.com/akinomyoga/ble.sh`     | Linux Bash                 | Generated `$XDG_DATA_HOME/blesh/**`                      | Clean HTTPS default branch; explicit fast-forward then rebuild         |
| `~/src/github.com/tj/git-extras`         | Zsh                        | `.local/share/zsh/completions/git-extras-completion.zsh` | Clean HTTPS default branch; explicit fast-forward then reapply         |
| `~/src/github.com/b3nj5m1n/xdg-ninja`    | Linux `xdg-ninja`          | Executable `.local/bin/xdg-ninja`                        | Clean HTTPS default branch; explicit fast-forward then reapply         |
| `~/src/github.com/catppuccin/alacritty`  | Windows `Alacritty`        | `Alacritty` theme import                                 | Clean HTTPS default branch; explicit fast-forward then reapply         |
| `~/src/github.com/catppuccin/lsd`        | LSD                        | `.config/lsd/colors.yaml`                                | Clean HTTPS default branch; explicit fast-forward then reapply         |
| `~/src/github.com/catppuccin/rio`        | Windows Rio                | `.config/rio/themes/catppuccin-mocha.toml`               | Clean HTTPS default branch; explicit fast-forward then reapply         |
| `~/src/github.com/catppuccin/xresources` | Native X11                 | Relative `Xresources` theme include                      | Clean HTTPS default branch; explicit fast-forward then reapply         |
| `~/src/github.com/catppuccin/dunst`      | Native X11                 | `.config/dunst/dunstrc.d/mocha.conf`                     | Clean HTTPS default branch; explicit fast-forward then reapply         |
| `~/src/github.com/dracula/gtk`           | Native X11                 | GTK theme, icon, and cursor destinations                 | Clean HTTPS default branch; explicit fast-forward then reapply         |
| `~/src/github.com/dracula/rofi`          | Native X11                 | `.config/rofi/config.rasi`                               | Clean HTTPS default branch; explicit fast-forward then reapply         |
| `~/src/github.com/po5/thumbfast`         | `Windows/native-X11` `MPV` | `Thumbfast` configuration and Lua plugin                 | Clean HTTPS default branch; explicit fast-forward then reapply         |
| `~/src/github.com/tomasklaen/uosc`       | `Windows/native-X11` `MPV` | Full staged `uosc` payload                               | Clean HTTPS default branch; explicit fast-forward then rebuild/reapply |

Do not provision `gpakosz/.tmux`, `amix/vimrc`, `doomemacs/doomemacs`,
`catppuccin/zellij`, `dracula/kitty`, `ohmybash/oh-my-bash`, or any legacy
`gitlink` solely for a retired consumer. Plugin-manager state and build output
remain excluded.

## Coverage and Ownership

This matrix owns the following 101 tracked legacy paths. The list is exact and
is disjoint from the 57-path Windows coverage manifest. The core matrix owns the
remaining 263 tracked paths. Together they partition all 421 entries.

<!-- unix-coverage:start -->

```text
.config/X11/xinitrc
.config/X11/xorg.conf.d/40-libinput.conf
.config/X11/xresources
.config/X11/xserverrc
.config/X11/xsession
.config/X11/xsession.desktop
.config/alacritty/alacritty.common.toml
.config/alacritty/alacritty.toml
.config/autorandr/settings.ini
.config/autostart/brave-browser.desktop
.config/autostart/geoclue-demo-agent.desktop
.config/autostart/protonvpn-app.desktop
.config/autostart/redshift-gtk.desktop
.config/autostart/thunderbird.desktop
.config/autostart/wezterm.desktop
.config/blesh/init.sh
.config/brewfile/Brewfile
.config/bspwm/bspwmrc
.config/clipcat/clipcat-menu.toml
.config/clipcat/clipcatctl.toml
.config/clipcat/clipcatd.toml
.config/dunst/dunstrc
.config/dunst/dunstrc.d/mocha.conf
.config/emacs
.config/emscripten/config
.config/feh/themes
.config/gtk-3.0/settings.ini
.config/gtk-4.0/settings.ini
.config/helix/languages.toml
.config/i3/config
.config/i3/config.d/i3.conf
.config/i3status-rust/config.toml
.config/kitty/kitty.conf
.config/lsd/colors.yaml
.config/macchina/macchina.toml
.config/mpv/script-opts/thumbfast.conf
.config/mpv/script-opts/uosc.conf
.config/mpv/scripts/thumbfast.lua
.config/nix/nix.conf
.config/pam-gnupg
.config/picom/picom.conf
.config/pulse/daemon.conf
.config/redshift.conf
.config/rio/themes/catppuccin-mocha.toml
.config/rofi/config.rasi
.config/rust-motd/config.toml
.config/sheldon/zsh/plugins.toml
.config/soar/config.toml
.config/sway/config
.config/sway/config.d/sway.conf
.config/sway/sway-via-bash.desktop
.config/sxhkd/sxhkdrc
.config/systemd/user/atuin.service
.config/systemd/user/default.target.wants/atuin.service
.config/systemd/user/default.target.wants/ssh-agent.service
.config/systemd/user/docuum.service
.config/systemd/user/emacs.service
.config/systemd/user/gpg-agent-browser.socket
.config/systemd/user/gpg-agent-extra.socket
.config/systemd/user/gpg-agent-ssh.socket
.config/systemd/user/gpg-agent.service
.config/systemd/user/gpg-agent.socket
.config/systemd/user/lemonade.service
.config/systemd/user/sockets.target.wants/gpg-agent-browser.socket
.config/systemd/user/sockets.target.wants/gpg-agent-extra.socket
.config/systemd/user/sockets.target.wants/gpg-agent-ssh.socket
.config/systemd/user/sockets.target.wants/gpg-agent.socket
.config/systemd/user/spotifyd.service
.config/systemd/user/ssh-agent.service
.config/systemd/user/tmux.service
.config/systemd/user/xdg-desktop-portal.service.d/override.conf
.config/texlive.profile
.config/tmux/tmux.conf
.config/tmux/tmux.conf.local
.config/user-dirs.dirs
.config/user-dirs.locale
.config/vim/vimrc
.config/vscode/server-env-setup
.config/xbindkeys/config
.config/xdg-desktop-portal/portals.conf
.config/zellij/config.kdl
.config/zellij/layouts/default.kdl
.config/zellij/themes/catppuccin.kdl
.config/zsh/.zlogout
.config/zsh/.zprofile
.config/zsh/.zshenv
.config/zsh/.zshrc
.local/bin/browser-wsl.sh
.local/bin/docuum
.local/bin/i3lock-color
.local/bin/run-as-cron
.local/bin/ssnz
.local/bin/update-alternatives-clang
.local/bin/update-golang
.local/bin/xdg-ninja
.local/share/applications/neovide.desktop
.local/share/icons/Dracula-cursors
.local/share/icons/Dracula-dark
.local/share/icons/hicolor/128x128/apps/neovide.png
.local/share/themes/Dracula-dark
.local/share/zsh/completions/git-extras-completion.zsh
```

<!-- unix-coverage:end -->

Of these 101 paths, the following 32 are explicitly deferred from the active
migration. The first 22 are future enrollment-source candidates; the final 10
are future managed destinations whose current legacy entries are symlinks.

<!-- unix-x11-deferred:start -->

```text
.config/X11/xinitrc
.config/X11/xorg.conf.d/40-libinput.conf
.config/X11/xresources
.config/X11/xserverrc
.config/X11/xsession
.config/X11/xsession.desktop
.config/autostart/thunderbird.desktop
.config/dunst/dunstrc
.config/feh/themes
.config/gtk-3.0/settings.ini
.config/gtk-4.0/settings.ini
.config/i3/config
.config/i3/config.d/i3.conf
.config/i3status-rust/config.toml
.config/picom/picom.conf
.config/redshift.conf
.config/user-dirs.dirs
.config/user-dirs.locale
.config/xdg-desktop-portal/portals.conf
.local/bin/i3lock-color
.local/share/applications/neovide.desktop
.local/share/icons/hicolor/128x128/apps/neovide.png
.config/autostart/brave-browser.desktop
.config/autostart/geoclue-demo-agent.desktop
.config/autostart/protonvpn-app.desktop
.config/autostart/redshift-gtk.desktop
.config/autostart/wezterm.desktop
.config/dunst/dunstrc.d/mocha.conf
.config/rofi/config.rasi
.local/share/icons/Dracula-cursors
.local/share/icons/Dracula-dark
.local/share/themes/Dracula-dark
```

<!-- unix-x11-deferred:end -->

The active subset from this matrix contributes 13 Linux roots, one shared Helix
root, and one Windows `Alacritty` root. The complete approved inventory has 176
roots and 235 files: 139 shared, 24 Windows, 13 Linux, and zero X11.

Explicit cross-owner exceptions are not repeated above:

- Matrix 08 retains coverage ownership of `.config/windows/wsl.conf`, the
  Terminal source, exported Lemonade task, and all `Windows/AppData`
  destinations.
- Matrix 07 retains coverage ownership of shared `Bash/shell/WezTerm/Herdr/Doom`
  paths, `MPV` base files, LSD base configuration, Rio base configuration, and
  the named live mise exception.
- New mirrored sources, generated destinations, bootstrap repositories, system
  destinations, and live local inputs are migration outputs or dependencies, not
  legacy coverage entries.

The [complete enrollment approval](10-approved-enrollment-inventory.md) compares
both explicit coverage manifests and the core remainder against `git ls-files`,
rejects overlap, and separately includes the named live
`~/.config/mise/config.toml` exception.
