# Mise Configuration Agent Rules

Guidance for managing the `mise` environment manager configuration in this
dotfiles repository.

## Documentation

- **High Trust Source:** Always use <https://mise.jdx.dev/> as the highest-trust
  source of truth for any `mise` configuration syntax, features, or behaviors
  not explicitly covered in this file.

## Configuration Structure

- **`conf.d/00-tools.toml`**: The primary declarative source of truth for
  universally installed CLI tools, language runtimes, and MCP servers. Edit this
  file to add or update global tools.
- **`config.local.toml`**: Machine-specific or untracked local tool overrides.
  Use this for tools that shouldn't sync across all hosts.
- **`conf.d/settings.toml`**: Core `mise` settings (e.g., `experimental = true`,
  `paranoid = true`, python `uv` integration).
- **`conf.d/fnox.toml`**: Specific configuration for the `fnox` environment
  plugin.

## Tool Definition Conventions

- Always prefer declarative additions to `conf.d/00-tools.toml` over running
  `mise use -g` when adding tools permanently to the dotfiles.
- **Tool sources:** Use prefixes to pull from different ecosystems:
  - `cargo:<package>` for Rust tools.
  - `go:<package>` for Go tools.
  - `npm:<package>` for Node packages. Notice the use of `aube_args` for some
    npm tools (e.g., `hunkdiff`), aligning with the repository rule to use
    `aube` instead of `npm`.
  - `github:<repo>` for direct GitHub release binaries.
  - `aqua:<package>` for Aqua registry tools.
- Specify `"latest"` for most tool versions unless stability requires pinning
  (e.g., `helm = "3"`) or a `minimum_release_age` is necessary to avoid broken
  edge releases.

## Formatting

- Use `taplo format` to format these `.toml` files after modifying them.
