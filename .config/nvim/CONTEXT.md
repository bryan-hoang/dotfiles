# Neovim Configuration

This context defines terminology used when configuring Neovim's editor
integrations.

## Language

**LSP server**: A process that implements the Language Server Protocol to
provide language-aware editor features.

**Filetype**: Neovim's classification of a buffer's content, used to select
language-specific behavior.

**LSP formatter**: A formatter exposed by an LSP server through
`textDocument/formatting` or `textDocument/rangeFormatting`.

**CLI formatter**: A formatter invoked as an external command by Conform instead
of through an LSP server.

**PSES formatter**: The PowerShell Editor Services LSP formatter, which uses
PSScriptAnalyzer settings supplied through the LSP `powershell.codeFormatting`
configuration.
