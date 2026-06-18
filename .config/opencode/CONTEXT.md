# Ubiquitous Language

## Agent Tool

An operation invoked directly by the agent via its built-in function-calling
interface (e.g., `bash`, `read`, `write`, `edit`, `fff_grep`, `fff_find_files`).
These execute outside the shell environment. Also known as "API Tools" or "MCP
Tools".

## Shell Command

An executable program or script run strictly _inside_ the payload of the `bash`
Agent Tool (e.g., `git`, `jaq`, `mise`, `pwsh`).

## Native Fallback

A Shell Command (like `findstr`, `Select-String`, `cat`, `New-Item`) that an
agent attempts to use to perform a task (like file searching or writing) when it
should be using a dedicated Agent Tool instead. These are explicitly banned for
specific operations to prevent bypassing constraints.

## Subshell Bypass

The act of invoking a new shell instance (e.g., `pwsh -c`, `pwsh -Command`,
`cmd.exe /c`, `sh -c`) within the `bash` Agent Tool to execute banned Native
Fallbacks, attempting to hide the violation from static rule checks. This is
strictly prohibited.

## Searching

The act of scanning the file system (directories or file contents on disk) for
information. This MUST be done using the custom `fff` Agent Tools (like
`fff_grep`, `fff_find_files`) or built-in fallback tools. Using Shell Commands
for searching is prohibited.

## Filtering

The act of narrowing down the standard output (`stdout`) of a legitimate Shell
Command (like `git log`, `docker ps`) via a pipeline operator (`|`). This is the
_only_ context where Shell Commands like `rg` are permitted. Filtering is
distinct from Searching.
