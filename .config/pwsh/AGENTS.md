# PowerShell Configuration

This directory contains the modular PowerShell profile setup for this
environment. The main entry point is `Microsoft.PowerShell_profile.ps1`, which
sequentially loads the `Initialize-*.ps1` scripts.

## High-Signal Context for Agents

- **Socket Firewall (SFW) Wrappers**: Major package managers (`npm`, `yarn`,
  `pnpm`, `pip`, `uv`, `cargo`, `go`, `mvn`, `gradle`, `dotnet`, `gem`,
  `bundle`) are wrapped as functions executing `sfw <tool>`
  (`Initialize-Functions.ps1`).
- **Stripped Default Aliases**: Default PowerShell aliases that shadow external
  binaries (like `curl` or `wget`) are intentionally removed in
  `Initialize-Aliases.ps1` to force the use of native commands. A strict
  allowlist preserves internal shell navigation (`cd`, `pushd`, etc.). `ls` is
  aliased to `lsd`.
- **XDG Base Directory Compliance**: The environment heavily overrides tool
  homes (AWS, Azure, Docker, Cargo, Kube, npm, Node, etc.) to use
  `$env:XDG_CONFIG_HOME`, `$env:XDG_DATA_HOME`, `$env:XDG_CACHE_HOME`, and
  `$env:XDG_STATE_HOME` (`Initialize-Environment.ps1`). Do not assume configs
  are in standard `~/.<tool>` paths.
- **Important Helper Functions** (`Initialize-Functions.ps1`):
  - `Test-CommandExists <command>`: Use to safely check for a tool's presence.
  - `Set-UserEnvVar <name> <value>`: Sets environment variables for the current
    session and permanently in the user's environment.
  - `Add-UserPath <path>`: Idempotently adds a directory to the user's `$PATH`.
- **Completions**: `Initialize-Completions.ps1` dynamically generates and caches
  completion scripts in `$env:XDG_DATA_HOME/powershell/completions`.
