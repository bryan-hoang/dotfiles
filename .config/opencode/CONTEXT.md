# OpenCode Configuration

This glossary names the boundaries between the agent, the shell, and workspace
file operations used by the configuration instructions.

## Execution

**Agent Tool**: A function exposed to the agent and invoked directly without
typing a command into the Host Shell. Built-in tools and MCP tools are both
Agent Tools. _Avoid_: API tool, Shell Command

**Question Agent Tool**: The built-in Agent Tool that presents structured
choices and accepts custom user answers. During grilling, it is the channel for
frontier decisions and final confirmation. _Avoid_: Markdown-only question

**Shell Command**: A program or script supplied as the payload of the `bash`
Agent Tool and run by the Host Shell. _Avoid_: Agent Tool, bash (when naming the
interpreter)

**Host Shell**: The operating-system command interpreter behind the `bash` Agent
Tool. On this machine it is PowerShell (`pwsh`) because the platform is `win32`.
_Avoid_: bash

**Command Interceptor**: A hook that can replace a Shell Command before the Host
Shell executes it. _Avoid_: shell error, alias

## File Operations

**Searching**: Locating files or matching file contents in the workspace.
_Avoid_: Filtering

**Filtering**: Narrowing the standard output of a legitimate Shell Command
through a pipeline. _Avoid_: Searching

**Native Fallback**: A Shell Command, inline script, or runtime API used for a
task that has a dedicated Agent Tool. _Avoid_: Agent Tool

**Subshell Bypass**: Starting another shell from the Host Shell to evade an
Agent Tool or permission constraint. _Avoid_: nested shell
