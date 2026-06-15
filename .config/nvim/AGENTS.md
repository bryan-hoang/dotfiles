# Neovim Config (`~/.config/nvim`) Context

This directory contains the user's Neovim configuration, which is part of a
larger dotfiles repository.

## Architecture & Conventions

- **LazyVim Based**: This setup is built on
  [LazyVim](https://lazyvim.github.io). Do not write monolithic `init.lua`
  configurations.
- **Entrypoints**:
  - `init.lua` and `lua/config/lazy.lua`: Core bootstrapping.
  - `lazyvim.json`: Defines enabled LazyVim extras.
- **Plugin Management**: Custom plugins and overrides belong in
  `lua/plugins/*.lua` or `lua/plugins/extras/`.
- **Core Options**: Neovim built-in options, keymaps, and autocmds are separated
  into `lua/config/options.lua`, `lua/config/keymaps.lua`, and
  `lua/config/autocmds.lua`.

## Linting & Formatting

- **Lua Code**: Use `stylua` for formatting (reads `stylua.toml`) and `selene`
  for linting (reads `selene.toml`). Do NOT use `luacheck`.
- **Plugin Configurations**:
  - **Formatting**: Managed by `conform.nvim` (`lua/plugins/formatting.lua`).
  - **Linting**: Managed by `nvim-lint` (`lua/plugins/linting.lua`).
  - When adding new languages, check these files to register the appropriate
    tools instead of installing standalone plugins where `conform` or
    `nvim-lint` would suffice.

## Tooling & Environment Requirements

- **Global Dotfiles Rules Apply**: You are operating in the user's root dotfiles
  repository. Follow the global rules (e.g., use `mise` for tool installation,
  `uv` for Python CLI tools, `aube` instead of `npm`).
- **Language Servers (LSP) & Mason**:
  - `mason.nvim` should be disabled (`mason = false` in `lspconfig.lua`) for
    tools that are already managed globally by `mise`, `uv`, or `aube` (e.g.,
    Python tools like `pyright` and `ruff`, Rust tools, system utilities).
    - When adding new tools, always ask the user how they would like the tool to
      be managed (e.g., globally via `mise` or locally via `mason.nvim`).
  - Leave `mason` enabled (by omitting `mason = false`) for web/node-based
    tooling (except those provided by `vscode-langservers-extracted` like
    `jsonls`, `html`, `cssls`, `eslint` which are managed via `mise` due to
    Windows Node shim issues) or tools that don't have a clean global install
    path.
  - `basedpyright` is explicitly set as the preferred Python LSP via a global
    variable in `options.lua`.
