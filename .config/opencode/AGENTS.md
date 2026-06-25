# Personal Coding Agent Rules

**CRITICAL: You MUST read `~/.config/opencode/CONTEXT.md` (or the equivalent
absolute path for your environment) to understand the exact definitions of terms
like "Agent Tool", "Shell Command", "Native Fallback", "Subshell Bypass",
"Searching", and "Filtering" used in these rules.**

Personal dotfiles and environment constraints shared across machines.

## Environment & Tooling

- **Host Shell Awareness**: The `bash` Agent Tool executes the **Host Shell**,
  not necessarily `bash`. You MUST check your environment data (OS/Platform). If
  the Host Shell is `pwsh` (e.g., on `win32`), you MUST use PowerShell syntax,
  quoting, and escaping rules (e.g., backticks, \`, for escaping, `&` call
  operator), completely ignoring the `bash` name.
- **Dotfiles Repo**: Root (`~`/`$HOME`) is a dotfiles git repo. Exercise caution
  with git commands here.
- **Cloned Repos**: Located in `src/<host>/` (e.g., `src/github.com/`).
- **Package & Environment Managers**:
  - `mise`: Install tools/languages (`mise use -g <tool>`).
  - `aube`: Use exclusively instead of `npm` (NEVER `npm`).
  - `uv`: Use exclusively for Python packages/CLI tools (NEVER `pip`).
- **Git Hooks**: Managed by `hk` (`hk install`).
- **CLI Preferences**: Use `git filter-repo` (not `filter-branch`).
  - **JSON Processing**: For structural parsing, reading, or extracting specific
    fields from JSON files, ALWAYS use `jaq` (another `jq` implementation) via
    bash instead of text-search Agent Tools (`fff_grep`, `grep`). For modifying
    JSON, prefer the `edit` Agent Tool for simple string replacements. For
    complex structural changes, use `jaq` or read/modify/write the file.
- **Search/Grep**: ALWAYS use the custom `fff` Agent Tools (`fff_find_files`,
  `fff_grep`, `fff_multi_grep`).
  - CRITICAL: These are built-in Agent Tools, NOT Shell Commands. NEVER try to
    execute `fff_grep` or `fff_find_files` inside the `bash` Agent Tool.
  - CRITICAL: Fall back to the built-in `grep` Agent Tools if needed.
  - CRITICAL: DO NOT use Native Fallbacks (`grep`, `find`, `findstr`,
    `Select-String`, `sls`, or `rg`) or inline language scripts (e.g.,
    `node -e`, `python -c`) for Searching files or the codebase.
  - EXCEPTION: You may use `rg` ONLY for Filtering pipeline output in the shell
    (e.g., `cmd | rg`).
  - EXCEPTION: You may use the `fd` Shell Command ONLY when you need to search
    for files in directories _outside_ the current workspace (since built-in
    tools may be restricted).
- **File Reading**: ALWAYS use the built-in `read` Agent Tool.
  - CRITICAL: DO NOT use Native Fallbacks (`cat`, `type`, or `Get-Content`) or
    inline language scripts (e.g., `node -e`, `python -c`) via bash to read file
    contents. DO NOT attempt a Subshell Bypass by wrapping them in
    `pwsh -Command` or `pwsh -c`. DO NOT use these tools to pipe into other
    commands (e.g., NEVER do `cat file | cmd`). If a Shell Command needs to
    process a file, pass the file path directly as an argument.
  - CRITICAL: DO NOT use Native Fallbacks (`sed`, `awk`, `head`, `tail`, `more`,
    or `less`) to print or read file contents. If you need to read specific line
    ranges, use the built-in `read` Agent Tool with the `offset` and `limit`
    parameters.
- **File Writing/Editing**: ALWAYS use the built-in `write` and `edit` Agent
  Tools.
  - CRITICAL: DO NOT use Native Fallbacks (`New-Item`, `Set-Content`,
    `Out-File`, `Add-Content`, `echo`, or `cat` with redirection `>`) via bash
    to create, modify, or append to files.
  - EXCEPTION: You may execute Shell Commands (like formatters, linters, or
    scaffolding tools like `aube create`) that modify files as part of their
    intended automated workflow.

## Agent Skills

- `azure-devops-cli`: For Azure DevOps (ADO) and `az` CLI tasks.
- `git-commit`: For generating git commit messages.
- `agent-browser` / `chrome-devtools` (MCP): For browser automation/tasks.

## Formatting Constraints

- **Markdown**: Use `oxfmt`. Run manually via bash ONLY after creating a new
  file.
- **SQL**: Use `sqlfluff`. Run manually via bash ONLY after creating a new file.
- **JSON**: Do NOT use `prettier`.
- **Line Length**: Soft cap at 80, 100, or 120 columns (especially comments).

## Git Commit Standards (CRITICAL)

**THESE STANDARDS MUST BE FOLLOWED FOR ALL COMMITS IN ALL REPOSITORIES.**

- **Context**: ALWAYS explain _why_ changes are made.
- **Formatting**: Hard wrap at 80 columns. Group all trailers together (no blank
  lines between).
- **Trailers** (in the following order):
  - `Refs: <ticket>`: For ADO/work items (e.g., `Refs: #123`).
  - `Assisted-by: <AGENT_NAME>:<MODEL_VERSION> [OPTIONAL_TOOLS]`: Required
    attribution for agent-authored commits. Omit `[OPTIONAL_TOOLS]` unless a
    specialized skill (e.g., `domain-modeling`) was used. Do not list basic
    Agent Tools (e.g., `read`, `write`, `bash`, `edit`, `fff_grep`). _Example:
    `Assisted-by: OpenCode:gemini-3.1-pro-preview`_
  - `Link: <url> # [X]`: Bracketed footnote notation for references.

    ```text
    Context referencing a doc [1].

    Link: https://example.com/docs # [1]
    ```

## Karpathy's Guidelines

Behavioral guidelines to reduce common LLM coding mistakes. Merge with
project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial
tasks, use judgment.

### 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:

- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes,
simplify.

### 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:

- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove preexisting dead code unless asked.

The test: Every changed line should trace directly to the user's request.

### 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:

- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multistep tasks, state a brief plan:

```text
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it
work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer
rewrites due to overcomplication, and clarifying questions come before
implementation rather than after mistakes.
