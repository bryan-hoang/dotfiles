# Windows and `AppData` Enrollment Matrix

Decision date: 2026-09-17

This matrix is the confirmed answer to
[Review Windows and `AppData` enrollment](https://github.com/bryan-hoang/dotfiles/issues/353).
It applies the
[sensitive-data policy](https://github.com/bryan-hoang/dotfiles/issues/350),
[link and dependency policy](https://github.com/bryan-hoang/dotfiles/issues/351),
and [core matrix](07-core-and-repository-root-enrollment.md) to the Windows
portion of the
[legacy inventory](../research/04-legacy-path-and-dependency-inventory.md).

The coverage manifest at the end accounts for all 57 tracked Windows-specific
and `AppData` entries. Shared canonical sources remain owned by the core matrix;
this matrix owns their Windows destinations. Unix, Linux, WSL, desktop, and
external-asset decisions are resolved by the
[Unix and desktop matrix](09-unix-and-desktop-enrollment.md). Cross-references
below preserve this matrix's Windows coverage ownership.

## Reading the Matrix

- `Enroll` means mise history records an exact reviewed public plaintext
  canonical source. Encryption is off everywhere.
- `Managed` means the Windows application module derives a not-enrolled live
  destination from one canonical source.
- `Local` means content remains excluded and is provisioned per machine.
- `Repository-only` means the legacy path remains inert at the setup-repository
  root and cannot be a deployment source.
- `Remove` means the converted tip omits the entry. Append-only ancestry still
  retains its prior versions.
- `Windows` is the only public Windows profile. There are no public home, work,
  or application capability profiles.
- Optional application flags are absent or false by default under
  `vars.windows_applications` in excluded
  `~/.config/mise/config.windows.local.toml`.
- `On` and `off` in save-policy cells mean `autosave = true` and
  `autosave = false`, respectively.

Every public text source uses `LF`. Mise records raw bytes and performs no
line-ending normalization. Generated local Task Scheduler data may use its
native encoding, but no generated task export enters enrollment.

## Windows Application Module

The required base may use ordinary mise declarations. Optional Windows
destinations are owned by one tracked PowerShell module because the aggregate
mise dotfile phase has neither installed-application conditions nor the chosen
per-application continuation behavior.

| Path or state                  | Disposition                      | Canonical source                                                                      | Managed destination                                                                | Profile / local flag          | Autosave / review                                                            | Link requirement                                                                     | Failure unit / dependency                    | Rationale                                                                                                                |
| ------------------------------ | -------------------------------- | ------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- | ----------------------------- | ---------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ | -------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| New Windows application module | Enroll control source            | `~/.config/mise/dotfiles/.config/windows/WindowsApplications.psm1`                    | None; bootstrap invokes its `status`, `apply`, `unapply`, and `validate` interface | `Windows`; always available   | Exact / off; review module behavior and effective path map before every save | Module creates and inspects links; it is not itself deployed                         | Windows setup control; requires PowerShell 7 | One interface owns optional flags, preflight, apply, status, cleanup, and drift handling without public machine topology |
| Optional application flags     | Local input                      | Excluded `~/.config/mise/config.windows.local.toml` under `vars.windows_applications` | Selects application units only                                                     | Local booleans, default false | Excluded; values are never copied to planning artifacts                      | None                                                                                 | Matching application unit                    | Machines can select installed applications without public `home/work` variants                                           |
| Application-unit state         | Local generated state            | Module implementation                                                                 | `~/.local/state/mise/windows-applications/`                                        | Machine                       | Hard-excluded                                                                | Records expected links without replacing filesystem ownership evidence               | Matching application unit                    | State is diagnostic, not portable configuration                                                                          |
| Drift quarantine               | Local generated state            | Divergent native path                                                                 | Timestamped path below `~/.local/state/mise/windows-applications/quarantine/`      | Machine                       | Hard-excluded; logs record paths and hashes, not values                      | Validator copies before any reconciliation; it does not overwrite the divergent path | Supported-workflow block                     | Potentially private divergent bytes never enter setup history                                                            |
| Drift sentinel                 | Local generated state            | Validator result                                                                      | `~/.local/state/mise/windows-applications/blocked`                                 | Machine                       | Hard-excluded                                                                | No filesystem link                                                                   | Supported-workflow block                     | Module commands fail while present; run books require a successful `validate` before manual save or sync                 |
| Built-in mise history watcher  | Keep after downstream validation | Shared mise service declaration owned by home validation                              | Platform-generated Windows user task                                               | Windows automatic sync        | Service state excluded                                                       | No pre-save application-link hook exists                                             | Downstream home-validation gate              | Link drift may continue through automatic sync until manual validation detects it                                        |

For each enabled optional application, `apply` first checks the application, all
sources and destinations, the required link capability, existing occupants, and
dependent assets. A preflight failure changes no path in that application unit
and does not stop unrelated optional units. Required-base failure stops
adoption. A false flag removes only verified module-owned destinations; changed
or replaced paths are quarantined and held for manual reconciliation. App-owned
startup settings are reported but never toggled by the module.

Manual `validate` detects link drift, quarantines the divergent path, writes the
sentinel, stops the built-in watcher, and blocks supported module and run book
operations. This is not an absolute command lock: a raw `mise dot save`,
`mise dot sync`, or other direct mise command can bypass it. Replacement itself
does not trigger an immediate pause, and automatic sync may continue until the
next manual validation.

## Required Windows Base

| Path or exact class                                                             | Disposition                                 | Canonical source                                                                                    | Managed destination                                                       | Profile / local flag         | Autosave / review                                                               | Link requirement                                              | Failure unit / dependency                                          | Work delta / rationale                                                                                                                                      |
| ------------------------------------------------------------------------------- | ------------------------------------------- | --------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------- | ---------------------------- | ------------------------------------------------------------------------------- | ------------------------------------------------------------- | ------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Ten current `.config/pwsh/**` entries                                           | Enroll exact current files after cleanup    | Native `~/.config/pwsh/**` paths                                                                    | Same paths                                                                | `Windows`; required          | Exact files / on; ordinary public PowerShell behavior                           | None for native sources                                       | Required Windows base; PowerShell 7                                | Preserve the modular profile; remove retired Komorebi and `whkd` environment assignments                                                                    |
| PowerShell current-user/current-host profile                                    | Managed required destination                | `~/.config/pwsh/Microsoft.PowerShell_profile.ps1`                                                   | Runtime value of `$PROFILE.CurrentUserCurrentHost`                        | `Windows`; required          | Source exact / on; destination not enrolled                                     | Real file symlink; no copy fallback                           | Required Windows base; Developer Mode or equivalent link privilege | Resolve `$PROFILE` at apply time so redirected Documents folders are not hard-coded                                                                         |
| `~/.config/pwsh/Initialize-Machine.ps1`                                         | Local guarded overlay                       | Machine-local native path                                                                           | Sourced when present                                                      | Machine                      | Excluded                                                                        | None                                                          | Required PowerShell may run without it                             | Work, private, and machine behavior never enters the public source                                                                                          |
| PowerShell completion cache and installed modules                               | Local generated state                       | PowerShell and module managers                                                                      | Native cache/module locations, including Local `AppData` completion state | Machine                      | Excluded                                                                        | None                                                          | PowerShell profile dependencies                                    | Generated code, caches, and package state are not configuration sources                                                                                     |
| `.bash_logout`, `.bash_profile`, `.bashrc`, `.hushlogin`, `.profile` on Windows | Managed required compatibility destinations | Matching core canonical sources under `~/.config/bash/`, `~/.config/login/`, and `~/.config/shell/` | Matching HOME-root paths                                                  | `Windows`; required Git Bash | Core source policies / destinations not enrolled                                | Real file symlinks; no copy fallback                          | Required Windows base; Git Bash and link privilege                 | Preserve the core login chain; Windows realizes the links without reopening Unix branches                                                                   |
| `.config/mintty/config`                                                         | Enroll                                      | Native live path                                                                                    | Same path and `AppData` junction below                                    | `Windows`; required Git Bash | Exact / on; ordinary public UI behavior                                         | Native source has no link                                     | Required Windows base; `Mintty` supplied with Git Bash             | Retain the selected Git Bash terminal behavior                                                                                                              |
| `Herdr` native configuration, no legacy Windows coverage entry                  | Managed required generated destination      | Core-owned `~/.config/mise/dotfiles/.config/herdr/config.toml.tmpl`                                 | `%APPDATA%\herdr\config.toml`                                             | `Windows`; required `Herdr`  | Template exact / on; generated configuration and `Herdr` runtime state excluded | Generated read-only file; changed occupant blocks replacement | Required Windows base; mise-provisioned `Herdr`                    | Unix matrix makes `Herdr` the sole multiplexer, selects PowerShell, gates Kitty graphics through excluded local capability, and starts the server on demand |

The ten PowerShell entries are `AGENTS.md`, `CONTEXT.md`, the six current
`Initialize-*.ps1` files, `Microsoft.PowerShell_profile.ps1`, and
`PSScriptAnalyzerSettings.psd1`. A new `Initialize-Machine.ps1` is never part of
that enrolled family.

## Windows Canonical Sources

| Legacy path or exact class                                                                                         | Disposition                                                           | Canonical source                                                                                                   | Managed destination                                   | Profile / local flag                                             | Autosave / review                                                                    | Link requirement                                                    | Failure unit / dependency                                                                   | Work delta / rationale                                                                                                          |
| ------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------- | ---------------------------------------------------------------- | ------------------------------------------------------------------------------------ | ------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| `.config/alacritty/alacritty.windows.toml`                                                                         | Replace with portable template source                                 | `~/.config/mise/dotfiles/AppData/Roaming/alacritty/alacritty.toml`                                                 | Native `Alacritty` path listed in the `AppData` table | `Windows`; `alacritty`                                           | Exact template source / on; rendered values reviewed                                 | Generated regular read-only destination; no writable-copy semantics | `alacritty`; Git Bash plus full `catppuccin/alacritty` checkout approved by the Unix matrix | Remove literal user paths; render HOME and use the required Git Bash command                                                    |
| `.config/git/windows.gitconfig`                                                                                    | Repository-only inert legacy                                          | Existing setup-root path                                                                                           | None; generated Git configuration drops its include   | None                                                             | Not enrolled                                                                         | None                                                                | None                                                                                        | The file contains no active behavior; `LF` remains the shared Git policy                                                        |
| `.config/glazewm/config.yaml`                                                                                      | Enroll after removing retired-stack assumptions                       | Native live path                                                                                                   | Same path through `GLAZEWM_CONFIG_PATH`               | `Windows`; `glazewm_zebar`                                       | Exact / on; ordinary public behavior                                                 | None                                                                | `glazewm_zebar`; `GlazeWM` and `Zebar`                                                      | The official `GlazeWM` machine-local startup toggle is reported, not changed; its startup command launches `Zebar`              |
| `.config/komorebi/komorebi.json`, `.config/komorebi/komorebi.bar.json`                                             | Repository-only inert legacy                                          | Existing setup-root paths                                                                                          | None                                                  | None                                                             | Not enrolled                                                                         | None                                                                | None                                                                                        | `GlazeWM` and `Zebar` replace the retired Komorebi stack                                                                        |
| `.config/mintty/config`                                                                                            | See required-base row                                                 | Native live path                                                                                                   | `AppData` junction below                              | `Windows`; required                                              | Exact / on                                                                           | Junction for native `AppData` path                                  | Required Windows base                                                                       | One canonical `Mintty` directory                                                                                                |
| `.config/pwsh/**`                                                                                                  | See required-base rows                                                | Native live paths                                                                                                  | PowerShell profile link where required                | `Windows`; required                                              | Exact / on, except local overlay excluded                                            | Profile destination is a real file symlink                          | Required Windows base                                                                       | One shared public profile with local machine overlay                                                                            |
| `.config/vesktop/package.json`                                                                                     | Repository-only inert legacy                                          | Existing setup-root path                                                                                           | None                                                  | None                                                             | Not enrolled                                                                         | None                                                                | None                                                                                        | Preserve the intentional `CommonJS` marker as a record; no active `Vesktop` consumer was approved                               |
| `.config/whkd/whkdrc`                                                                                              | Repository-only inert legacy                                          | Existing setup-root path                                                                                           | None                                                  | None                                                             | Not enrolled                                                                         | None                                                                | None                                                                                        | `GlazeWM` owns key bindings; `whkd` is retired                                                                                  |
| `.config/windows/.editorconfig`                                                                                    | Repository-only maintenance                                           | Existing setup-root path                                                                                           | None                                                  | Setup repository                                                 | Not enrolled                                                                         | None                                                                | None                                                                                        | It is not live Windows application configuration                                                                                |
| `.config/windows/atuin-daemon.xml`, `.config/windows/glazewm.xml`, `.config/windows/lemonade-server.xml`           | Remove                                                                | Existing ancestry only                                                                                             | No XML export is restored                             | None                                                             | Not enrolled                                                                         | None                                                                | `Atuin` or `GlazeWM` unit where retained; none for Lemonade                                 | Exports contain machine/account metadata and fixed paths; Lemonade has no replacement service                                   |
| `.config/windows/hidden-launcher.vbs`                                                                              | Repository-only inert legacy                                          | Existing setup-root path                                                                                           | None                                                  | None                                                             | Not enrolled                                                                         | None                                                                | None                                                                                        | `Atuin` uses its dedicated Startup `VBS`, `GlazeWM` uses app-owned startup, and Lemonade retires without a replacement service  |
| `.config/windows/wind-term-settings.json`                                                                          | Enroll canonical common-intent settings                               | Native live path                                                                                                   | Stable and Preview settings paths below               | `Windows`; source always present, destinations use channel flags | Exact / off; field allowlist and value-suppressing review before every explicit save | Both channel destinations require real file symlinks                | `terminal_stable` and `terminal_preview`; matching installed packages                       | Preserve and review the work Preview delta; retain the generic public `wsl` profile approved by the Unix matrix                 |
| `.config/windows/winget-pkgs.json`                                                                                 | Repository-only export                                                | Existing setup-root path                                                                                           | None                                                  | Setup repository                                                 | Not enrolled                                                                         | None                                                                | None                                                                                        | General package bootstrap is outside scope                                                                                      |
| `.config/windows/winget-settings.json`                                                                             | Repository-only behavior-free source                                  | Existing setup-root path                                                                                           | None                                                  | None                                                             | Not enrolled                                                                         | None                                                                | None                                                                                        | No effective setting justifies a live `WinGet` redirect                                                                         |
| `.config/windows/wsl.conf`                                                                                         | Repository-only inert legacy; system decision resolved by Unix matrix | Existing setup-root path is never a deployment source; new source is `~/.config/mise/dotfiles/system/etc/wsl.conf` | Unix-owned privileged `/etc/wsl.conf` deployment      | Local opt-in WSL distribution                                    | Not enrolled here                                                                    | No Windows HOME destination                                         | [Unix matrix](09-unix-and-desktop-enrollment.md)                                            | Enables systemd and interop, disables Windows PATH appending, deploys root-owned mode `0644`, and requires a manual WSL restart |
| `.config/zebar/settings.json`                                                                                      | Enroll exact approved app-written source                              | Native live path                                                                                                   | Same path through `ZEBAR_CONFIG_DIR`                  | `Windows`; `glazewm_zebar`                                       | Exact / on; automatic UI and schema rewrites are accepted public publication         | None                                                                | `glazewm_zebar`; `Zebar`                                                                    | Deliberate autosave exception; only exact approved files are enrolled                                                           |
| `.config/zebar/custom/README.md`, `resources/preview-image-1.png`, `styles.css`, `with-glazewm.html`, `zpack.json` | Enroll active custom pack                                             | Native live paths                                                                                                  | Same paths                                            | `Windows`; `glazewm_zebar`                                       | Exact files / on; app and authored rewrites publish automatically                    | None                                                                | `glazewm_zebar`; `Zebar`                                                                    | Edit `zpack.json` to expose only `with-glazewm`; retain required documentation and preview assets                               |
| `.config/zebar/custom/vanilla.html`, `.config/zebar/custom/with-komorebi.html`                                     | Repository-only inert legacy                                          | Existing setup-root paths                                                                                          | None                                                  | None                                                             | Not enrolled                                                                         | None                                                                | None                                                                                        | Only `with-glazewm` remains active                                                                                              |
| `.config/zebar/.marketplace/glzr-io.starter.json`                                                                  | Remove generated state                                                | Existing ancestry only                                                                                             | None                                                  | None                                                             | Excluded                                                                             | None                                                                | None                                                                                        | Installed-pack metadata and timestamps are not configuration sources                                                            |

### Terminal Controls

The Terminal source keeps explicit PowerShell 7, Windows PowerShell, Command
Prompt, Git Bash, and generic `wsl` entries. The WSL entry names no distribution
or machine and launches the local default distribution. Only fields accepted by
the public allowlist may be saved; private paths, machine names, remote
endpoints, connection topology, and credentials are forbidden.

Stable and Preview are enabled independently, but both write through real links
to one source. The operational single-writer procedure closes the other channel
before editing settings, then validates every locally enabled channel before an
explicit save. Validation is deliberately local: a Stable-only machine may
publish settings that fail under Preview elsewhere. The source is therefore
common-intent configuration, not a guaranteed Stable/Preview intersection.
Automatic sync may apply an incompatible version before manual validation;
recovery uses history and manual reconciliation.

### Autosave Exceptions

Harper and `Zebar` are narrow, confirmed exceptions to the general
sensitive-capable manual-save rule:

- A global Harper add-to-dictionary action is immediate consent to publish that
  word. Workspace and file-local dictionaries are the required route for private
  terms. There is no technical classifier that can distinguish a public term
  from a private name.
- Every write to the exact approved `Zebar` files, including UI and schema
  rewrites, may enter public history automatically. New descendants are not
  enrolled, and marketplace state remains excluded.

Neither exception permits credentials, private endpoints, private access
topology, concrete machine identifiers, or other forbidden data.

## `AppData` Destinations

| Legacy `AppData` path                                                                            | Disposition                                                                       | Canonical source                                                                                               | Managed destination   | Profile / local flag          | Autosave / review                                                | Link requirement                                                                | Failure unit / dependency                                                                     | Work delta / rationale                                                                                                                                                    |
| ------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- | --------------------- | ----------------------------- | ---------------------------------------------------------------- | ------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `AppData/Local/Packages/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe/LocalState/settings.json`    | Remove redirect                                                                   | Repository-only `.config/windows/winget-settings.json` record                                                  | None                  | None                          | Not enrolled                                                     | Remove legacy link                                                              | None                                                                                          | `WinGet` source has no effective behavior                                                                                                                                 |
| `AppData/Local/Packages/Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe/LocalState/settings.json` | Managed writable destination                                                      | `~/.config/windows/wind-term-settings.json`                                                                    | Same native path      | `Windows`; `terminal_preview` | Source exact / off; destination not enrolled                     | Real file symlink; no copy fallback                                             | `terminal_preview`; installed Preview package                                                 | Recheck work path type, preserve divergent bytes, and merge approved common-intent changes before linking                                                                 |
| `AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json`        | Managed writable destination                                                      | `~/.config/windows/wind-term-settings.json`                                                                    | Same native path      | `Windows`; `terminal_stable`  | Source exact / off; destination not enrolled                     | Real file symlink; no copy fallback                                             | `terminal_stable`; installed Stable package                                                   | Independently enabled but shares the Preview source; local validation gives no cross-machine compatibility guarantee                                                      |
| `AppData/Local/rio`                                                                              | Managed writable directory destination                                            | Approved exact sources in `~/.config/rio/`                                                                     | Same native directory | `Windows`; `rio`              | Each source keeps its owner policy; destination not enrolled     | Verified directory junction; no copy fallback                                   | `rio`; full `catppuccin/rio` checkout from Unix matrix                                        | Whole junction applies only after the managed theme and every source pass preflight                                                                                       |
| `AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/start-atuin-daemon.vbs`           | Managed read-only startup launcher                                                | `~/.config/mise/dotfiles/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/start-atuin-daemon.vbs` | Same native path      | `Windows`; `atuin_daemon`     | Exact source / on; destination not enrolled                      | Managed copy is allowed; reapply after source changes                           | `atuin_daemon`; `Atuin` must resolve on persistent login PATH                                 | One Startup launcher replaces the removed task export; `Atuin` data and credentials remain local                                                                          |
| `AppData/Roaming/alacritty/alacritty.toml`                                                       | Managed generated destination                                                     | Portable template source under mise `dotfiles` shown above                                                     | Same native path      | `Windows`; `alacritty`        | Template source exact / on; rendered destination excluded        | Generated regular file; changed occupant is quarantined rather than overwritten | `alacritty`; `Alacritty`, Git Bash, and full `catppuccin/alacritty` checkout from Unix matrix | Replaces literal HOME and executable paths without a second writable source                                                                                               |
| `AppData/Roaming/bat`                                                                            | Managed writable directory destination                                            | Approved exact sources in `~/.config/bat/`                                                                     | Same native directory | `Windows`; `bat`              | Source exact files / on                                          | Verified directory junction; no copy fallback                                   | `bat`; Bat                                                                                    | One canonical directory; generated neighbors remain untracked                                                                                                             |
| `AppData/Roaming/dystroy/broot/config/conf.hjson`                                                | Remove redirect                                                                   | Core-owned `~/.config/broot/` remains available to other platforms                                             | None on Windows       | None                          | No Windows destination                                           | Remove legacy link                                                              | None                                                                                          | `Broot` was not approved as an active Windows application                                                                                                                 |
| `AppData/Roaming/espanso`                                                                        | Managed writable directory destination                                            | Approved exact sources in `~/.config/espanso/`                                                                 | Same native directory | `Windows`; `espanso`          | Source exact files / on                                          | Verified directory junction; no copy fallback                                   | `espanso`; `Espanso`                                                                          | Public explicit edits autosave; generated descendants remain untracked                                                                                                    |
| `AppData/Roaming/harper-ls/dictionary.txt`                                                       | Managed writable destination                                                      | `~/.config/harper-ls/dictionary.txt`                                                                           | Same native path      | `Windows`; `harper`           | Exact source / on; global additions are immediate public consent | Real file symlink; no copy fallback                                             | `harper`; Harper client                                                                       | Recheck work path type and privately review existing additions before the first baseline; future global additions publish automatically                                   |
| `AppData/Roaming/helix`                                                                          | Managed writable directory destination                                            | Approved exact sources in `~/.config/helix/`                                                                   | Same native directory | `Windows`; `helix`            | Each source keeps its owner policy                               | Verified directory junction; no copy fallback                                   | `helix`; debugger-free `languages.toml` approved by Unix matrix                               | Portable language behavior now completes the directory; both debugger dependencies retire                                                                                 |
| `AppData/Roaming/lsd`                                                                            | Managed writable directory destination                                            | Approved exact sources in `~/.config/lsd/`                                                                     | Same native directory | `Windows`; `lsd`              | Each source keeps its owner policy                               | Verified directory junction; no copy fallback                                   | `lsd`; full `catppuccin/lsd` checkout from Unix matrix                                        | Managed `colors.yaml` replaces the removed `gitlink` before the directory is exposed                                                                                      |
| `AppData/Roaming/mintty`                                                                         | Managed required directory destination                                            | `~/.config/mintty/`                                                                                            | Same native directory | `Windows`; required Git Bash  | Exact source / on                                                | Verified directory junction; no copy fallback                                   | Required Windows base; `Mintty`                                                               | Required Git Bash behavior, not an optional application unit                                                                                                              |
| `AppData/Roaming/mpv`                                                                            | Managed writable directory destination                                            | Approved exact sources in `~/.config/mpv/`                                                                     | Same native directory | `Windows`; `mpv`              | Each source keeps its owner policy                               | Verified directory junction; no copy fallback                                   | `mpv`; full `po5/thumbfast` and `tomasklaen/uosc` checkouts from Unix matrix                  | Apply only after clean dependency preflight and complete staged `uosc` payload deployment                                                                                 |
| `AppData/Roaming/ncspot`                                                                         | Managed local-only directory destination                                          | Excluded local `~/.config/ncspot/` authority                                                                   | Same native directory | `Windows`; `ncspot`           | Source and destination excluded                                  | Verified directory junction; no copy fallback                                   | `ncspot`; `ncspot` and required local source                                                  | Preserve one local authority without publishing account-capable configuration                                                                                             |
| `AppData/Roaming/nushell/nu/config/config.toml`                                                  | Remove obsolete redirect                                                          | Inert repository-only `.config/nu/config.toml`                                                                 | None                  | None                          | Not enrolled                                                     | Remove legacy link                                                              | None                                                                                          | Core review retired the obsolete Nu configuration; WSL Nu remains outside this matrix                                                                                     |
| `AppData/Roaming/rtk`                                                                            | Managed writable directory destination                                            | Approved exact sources in `~/.config/rtk/`                                                                     | Same native directory | `Windows`; `rtk`              | Source exact files / on                                          | Verified directory junction; no copy fallback                                   | `rtk`; `RTK`                                                                                  | Configuration is shared; tracking output and runtime state remain local                                                                                                   |
| `AppData/Roaming/silicon/config`                                                                 | Remove redirect                                                                   | Core-owned `~/.config/silicon/config` remains available to other platforms                                     | None on Windows       | None                          | No Windows destination                                           | Remove legacy link                                                              | None                                                                                          | Silicon was not approved as an active Windows application                                                                                                                 |
| `AppData/Roaming/streamlink/config`                                                              | Local whole-file application configuration; repository legacy sanitized and inert | Native local `AppData` file                                                                                    | Same local path       | Machine                       | Excluded                                                         | None                                                                            | `Streamlink`; out-of-band local provisioning                                                  | Legacy clean filters are not a privacy boundary; credentials and account data remain local                                                                                |
| `AppData/Roaming/topgrade.toml`                                                                  | Managed read-only destination                                                     | `~/.config/topgrade/topgrade.toml` plus excluded `~/.config/topgrade/topgrade.local.toml` include              | Same native path      | `Windows`; `topgrade`         | Public source exact / on; local include excluded                 | Verified file symlink preferred; replaceable copy fallback allowed              | `topgrade`; Topgrade                                                                          | Recheck work path type; merge portable settings into the public source and machine-only settings into the local include; remove the old HOME Git-repository update target |
| `AppData/Roaming/vesktop/package.json`                                                           | Remove generated package state                                                    | None                                                                                                           | None                  | None                          | Excluded                                                         | None                                                                            | None                                                                                          | Generated package metadata is unrelated to the inert `.config` `CommonJS` marker                                                                                          |

Directory junctions may expose local generated neighbors in the canonical
directory, but mise enrolls only the exact approved files. New descendants do
not enter history automatically. Required themes, plugins, and scripts follow
the clean HTTPS checkout rules in the confirmed Unix matrix. `Alacritty`, Rio,
LSD, Helix, and `MPV` now have complete dependency decisions before their
corresponding directory units can apply. No `gitlink` is retained.

## Services and Startup

| Application          | Decision                            | Public source                             | Local realization                                                 | Failure and dependency policy                                                                                           |
| -------------------- | ----------------------------------- | ----------------------------------------- | ----------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| `Atuin` daemon       | Keep optional Startup launcher      | Mirrored `VBS` source listed above        | Managed Startup-folder copy                                       | `atuin_daemon` fails before writes when `Atuin` or persistent PATH is unavailable; no task is generated                 |
| `GlazeWM`            | Keep app-owned startup              | Enrolled `GlazeWM` configuration          | User enables the official `GlazeWM` machine-local startup setting | `glazewm_zebar` reports but never toggles startup; `Zebar` starts from `GlazeWM` configuration                          |
| `Zebar`              | Start only through `GlazeWM`        | Enrolled settings and `with-glazewm` pack | No separate startup entry                                         | Same `glazewm_zebar` unit; marketplace state stays local                                                                |
| Lemonade server      | Retire                              | None; legacy XML remains removed          | No Windows service/task                                           | Direct WSL PowerShell interop and `OSC` 52 replace Lemonade; no unauthenticated TCP listener or `lemonade` flag remains |
| Mise history watcher | Keep built-in after home validation | Shared mise declaration owned downstream  | Platform-generated user task                                      | No pre-save link validator; manual drift detection stops it through the supported-workflow block                        |

## Work-Machine Reconciliation

No work-machine value enters this matrix. Adoption rechecks every path because
the downloaded handoff records an earlier point in time.

| Path                                    | Required handling before work adoption                                                                                                                                       | Ongoing policy                                                                                                         |
| --------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| `.config/npm/npmrc`                     | Securely compare the live file, split local/auth fields, and merge only allowlist-approved public behavior into the core mirrored source                                     | Core sensitive-capable source remains autosave off; native generated destination and local fields remain excluded      |
| Terminal Preview native `settings.json` | Recheck file type and target, preserve divergent bytes, compare with the public source and any locally enabled Stable channel, then merge only approved common-intent fields | Source autosave off; validate only locally enabled channels and accept the documented cross-machine compatibility risk |
| Harper native `dictionary.txt`          | Recheck file type and target; privately review and merge each existing addition before the first baseline                                                                    | Future global additions autosave as explicit public publication; workspace/file-local words remain excluded            |
| Topgrade native `topgrade.toml`         | Recheck file type and target; merge portable settings publicly and machine-specific settings into the excluded local include                                                 | Public source autosaves; destination is read-only and must be reapplied after a copy fallback                          |

No source automatically wins a work conflict. Original bytes are preserved until
the user approves the merged public source or local disposition.

## Accepted Risk Boundaries

1. Link replacement does not immediately pause automatic history. Automatic save
   and sync may continue until the next manual `validate` detects drift.
2. The supported-workflow sentinel stops the watcher and managed workflows after
   detection, but raw mise commands can bypass it.
3. Shared Terminal settings are validated only against locally enabled channels.
   Cross-machine Stable/Preview compatibility is not guaranteed.
4. Harper global additions and writes to exact approved `Zebar` files publish
   automatically. These user-approved exceptions have no pre-publication
   private-term or unknown-field gate.
5. `GlazeWM` startup is app-owned local state. The module reports it but does
   not make it reproducible or change it.

## Excluded and Generated State

Never enroll application credentials, cookies, sessions, private endpoints,
private topology, concrete account or machine identifiers, or task exports.
Never enroll Terminal state other than the exact canonical settings source.
Never enroll PowerShell modules or completion caches, `Atuin` history/data,
`ncspot` or `Streamlink` content, `Zebar` marketplace state, `Vesktop` package
metadata, or `RTK` tracking output. The same applies to any other `AppData`
cache, log, database, install, or session tree.

Repository-only paths remain at the legacy setup-root namespace, contain no
forbidden data, and are rejected as sources by the anchored legacy-path guard.
Removed files remain only in append-only ancestry.

## Coverage Manifest

This exact list is compared with Git's `Windows/AppData` candidate inventory.

<!-- windows-coverage:start -->

```text
.config/alacritty/alacritty.windows.toml
.config/git/windows.gitconfig
.config/glazewm/config.yaml
.config/komorebi/komorebi.bar.json
.config/komorebi/komorebi.json
.config/mintty/config
.config/pwsh/AGENTS.md
.config/pwsh/CONTEXT.md
.config/pwsh/Initialize-Aliases.ps1
.config/pwsh/Initialize-Completions.ps1
.config/pwsh/Initialize-Environment.ps1
.config/pwsh/Initialize-Functions.ps1
.config/pwsh/Initialize-Integrations.ps1
.config/pwsh/Initialize-Preferences.ps1
.config/pwsh/Microsoft.PowerShell_profile.ps1
.config/pwsh/PSScriptAnalyzerSettings.psd1
.config/vesktop/package.json
.config/whkd/whkdrc
.config/windows/.editorconfig
.config/windows/atuin-daemon.xml
.config/windows/glazewm.xml
.config/windows/hidden-launcher.vbs
.config/windows/lemonade-server.xml
.config/windows/wind-term-settings.json
.config/windows/winget-pkgs.json
.config/windows/winget-settings.json
.config/windows/wsl.conf
.config/zebar/.marketplace/glzr-io.starter.json
.config/zebar/custom/README.md
.config/zebar/custom/resources/preview-image-1.png
.config/zebar/custom/styles.css
.config/zebar/custom/vanilla.html
.config/zebar/custom/with-glazewm.html
.config/zebar/custom/with-komorebi.html
.config/zebar/custom/zpack.json
.config/zebar/settings.json
AppData/Local/Packages/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe/LocalState/settings.json
AppData/Local/Packages/Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe/LocalState/settings.json
AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json
AppData/Local/rio
AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/start-atuin-daemon.vbs
AppData/Roaming/alacritty/alacritty.toml
AppData/Roaming/bat
AppData/Roaming/dystroy/broot/config/conf.hjson
AppData/Roaming/espanso
AppData/Roaming/harper-ls/dictionary.txt
AppData/Roaming/helix
AppData/Roaming/lsd
AppData/Roaming/mintty
AppData/Roaming/mpv
AppData/Roaming/ncspot
AppData/Roaming/nushell/nu/config/config.toml
AppData/Roaming/rtk
AppData/Roaming/silicon/config
AppData/Roaming/streamlink/config
AppData/Roaming/topgrade.toml
AppData/Roaming/vesktop/package.json
```

<!-- windows-coverage:end -->

This 57-path manifest remains the Windows coverage owner, including the legacy
`.config/windows/wsl.conf` record whose system deployment decision lives in the
Unix matrix. The Unix manifest owns 101 disjoint paths; the core matrix owns the
remaining 263. The [complete approval](10-approved-enrollment-inventory.md)
checks the named live mise exception and narrows the active inventory to 176
roots with zero X11 deployment before metadata generation.
