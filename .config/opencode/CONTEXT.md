# Ubiquitous Language

## Agent Tool

An operation invoked directly by the agent via its built-in function-calling
interface (e.g., `bash`, `read`, `write`, `edit`, `fff_grep`, `fff_find_files`).
These execute outside the shell environment. Also known as "API Tools" or "MCP
Tools".

## Shell Command

An executable program or script run strictly _inside_ the payload of the `bash`
Agent Tool (e.g., `git`, `jaq`, `mise`, `pwsh`).

## Host Shell

The actual command-line interpreter executing behind the `bash` Agent Tool,
determined dynamically by the OS environment. On Windows (`win32`), the Host
Shell is `pwsh`. On Unix-like systems, it may be `bash` or `zsh`.

## Native Fallback

A Shell Command (like `findstr`, `Select-String`, `cat`, `New-Item`), an inline
language script (like `node -e`, `python -c`), or a .NET interop call (like
`[System.IO.File]`) that an agent attempts to use to perform a task (like file
searching or writing) when it should be using a dedicated Agent Tool instead.
These are explicitly banned for specific operations to prevent bypassing
constraints.

## Subshell Bypass

The act of invoking a new shell instance (e.g., `pwsh -c`, `pwsh -Command`,
`cmd.exe /c`, `sh -c`) within the `bash` Agent Tool to execute banned Native
Fallbacks, attempting to hide the violation from static rule checks. This is
strictly prohibited.

## Command Interceptor

A plugin (like `rtk` via the `tool.execute.before` hook) that silently
intercepts and rewrites an agent's `bash` payload _before_ execution in the Host
Shell (e.g., rewriting `npx prettier` to `rtk prettier`). Agents must be aware
that what they execute may be mutated in-flight.

## Searching

The act of scanning the file system (directories or file contents on disk) for
information. This MUST be done using the custom `fff` Agent Tools (like
`fff_grep`, `fff_find_files`) or built-in fallback tools. Using Shell Commands
for searching is prohibited.

## Structural XML Operation

An inspection that depends on XML semantics, such as selecting elements or
attributes, resolving namespaces, or validating document structure. It is
distinct from Searching for literal text that happens to appear in an XML file.

## Filtering

The act of narrowing down or structurally extracting the standard output
(`stdout`) of a legitimate Shell Command via a pipeline operator (`|`). Shell
Commands like `rg`, `jaq`, `yq`, and `htmlq` are permitted in this context. Filtering
is distinct from Searching.
