# Global OpenCode Rules

These are personal defaults for every OpenCode session. Read the glossary at
`~/.config/opencode/CONTEXT.md` (or its equivalent absolute path) before
applying rules involving `Agent Tool`, `Question Agent Tool`, `Shell Command`,
`Host Shell`, `Command Interceptor`, `Searching`, `Filtering`,
`Native Fallback`, or `Subshell Bypass`.

## Tools

- Check the reported platform before issuing shell commands. On Windows
  (`win32`), `bash` is the Agent Tool name and its payload runs in PowerShell;
  use PowerShell syntax, quoting, and escaping. On other platforms, use the
  reported Host Shell's syntax.
- Search with `fff_find_files`, `fff_grep`, or `fff_multi_grep` when available;
  otherwise use the built-in `Glob` or `Grep` tools. Read files with `read` and
  edit files with `apply_patch`.
- Use dedicated Agent Tools for workspace search, reading, and editing; invoke
  `fff` as an Agent Tool rather than a Shell Command. Reserve Shell Commands for
  executable work. Use a Native Fallback only when the dedicated tool cannot
  perform the operation; never use a Subshell Bypass to evade a constraint.
- Use `aube` instead of `npm`, `uv` instead of `pip`, and `mise` to install
  tools. Use `jaq`, `yq`, `xmlstarlet`, and `htmlq` for structural JSON, YAML,
  XML, and HTML operations.
- `rtk` may rewrite shell commands before execution. If an error shows a command
  that was not written, diagnose that rewritten command.
- Permission prompts and denials are intentional. Use the dedicated Agent Tool
  or obtain approval rather than bypassing the configured constraint.

## Grilling

- In `/grilling` and any skill that invokes it, use the built-in `question`
  Agent Tool for every frontier decision and the final shared-understanding
  confirmation.
- Put the complete frontier in one `question` call per round, with the
  recommended option first. Treat custom user answers as valid decisions.
- Present questions through the `question` UI only when it succeeds; if it
  fails, use the grilling skill's numbered Markdown format as the fallback.

## Worktree Safety

- Before editing, walk from the working directory to the repository root and
  read every applicable project-local instruction file. Then inspect relevant
  manifests, scripts, and configuration; resolve conflicts in favor of
  more-local instructions and executable configuration.
- Preserve user changes and unrelated dirty files. Scope status and diffs to the
  files being worked on.
- Check `git ls-files` before treating a file as versioned when ignore rules or
  generated files make its status unclear.
- Treat generated or tool-managed files as read-only unless their owning tool
  documents an edit workflow; inspect their headers or configuration first.

## Git

- Perform commits, pushes, pulls, resets, restores, and other Git writes only
  after the user explicitly requests them.
- Before committing, inspect `git status`, `git diff`, and recent `git log`;
  stage only intended files.
- Commit messages explain why, are hard-wrapped at 80 columns, and group
  trailers with no blank lines in this order when applicable: `Refs: <ticket>`,
  `Assisted-by: <agent>:<model> [optional tools]`, `Link: <url> # [n]`.
  Agent-authored commits include `Assisted-by: OpenCode:<model>`; mention a
  specialized skill only when one was used.

## Engineering Defaults

- Surface material ambiguity before editing; do not silently choose between
  interpretations that change behavior.
- Trace the real flow and all callers before fixing a bug; fix the shared root
  cause rather than patching one named symptom path.
- Prefer the smallest correct change: reuse existing code, then use standard or
  native facilities, then add only the minimum new code required.
- Keep changes scoped to the requested behavior; add abstractions, features, or
  dependencies only when required.
- Run the repository's applicable focused checks and report their results. For
  nontrivial logic, leave one runnable check that would fail if it regressed.
- If no relevant test, build, or lint workflow exists, report that instead of
  inventing one.
- Before reporting completion, confirm the requested behavior is implemented,
  applicable instruction sources were read, and focused checks passed or were
  explicitly unavailable.
