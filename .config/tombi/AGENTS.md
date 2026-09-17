# Tombi

Tombi is a TOML toolkit with a formatter, linter, and Language Server Protocol
(LSP) server. It provides formatting, diagnostics, schema validation, and editor
completion for TOML files.

Use the [official Tombi documentation](https://tombi-toml.github.io/tombi/docs)
as the source of truth. Read the
[configuration](https://tombi-toml.github.io/tombi/docs/configuration),
[CLI](https://tombi-toml.github.io/tombi/docs/cli),
[JSON Schema](https://tombi-toml.github.io/tombi/docs/json-schema), and
[language-server](https://tombi-toml.github.io/tombi/docs/language-server)
pages.

## Configuration scope

This directory contains the user configuration in [config.toml](./config.toml).
Tombi also supports project-level `.tombi.toml`, `tombi.toml`,
`.config/tombi.toml`, and `[tool.tombi]` in `pyproject.toml`. A project
configuration takes precedence over this user-level fallback. This directory is
the documented `~/.config/tombi` location; on Windows, Tombi also documents
`%APPDATA%\tombi\config.toml`.

Configuration lookup starts from the CLI working directory or, for LSP use, the
directory of the opened file, then walks toward the filesystem root. Keep
project configuration at the project root; multiple configuration files in one
project can produce different CLI and editor results.

## Current configuration

The file defines one root JSON Schema:

- `path` is `https://example.com/schema.json`. Verify that it points to a
  reachable JSON Schema before relying on it.
- `include = ["*.toml"]` applies the schema to matching TOML files. This
  single-level pattern does not target nested project files; use a recursive
  pattern when a user-level schema must cover a project tree.
- `format.rules.array-values-order.enabled = true` enables array ordering
  supplied by the matched schema.
- `format.rules.table-keys-order.enabled = true` enables table-key ordering
  supplied by the matched schema.
- The override targets `""` (the document root) and `"tool.*"` (any key directly
  below `tool`). Both ordering rules use explicit `version-sort` for those
  targets.

Schema-enabled ordering only has an effect when the schema supplies ordering
metadata. The explicit overrides force `version-sort` for their matching
targets.

## Editing rules

- Read the effective project configuration before changing TOML or this file.
- Preserve schema-driven ordering; use Tombi's formatter instead of manually
  reordering entries.
- When changing a schema URL, include the reason and verify that the URL
  resolves to valid JSON Schema.
- After a change, run Tombi's formatter and linter on the affected files. Use
  the current [CLI reference](https://tombi-toml.github.io/tombi/docs/cli) for
  command syntax, then inspect the diff.
- Surface formatter, linter, schema-fetch, and schema-parse failures. State when
  validation could not run.
