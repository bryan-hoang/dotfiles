# Personal Coding Agent Rules

Personal dotfiles and environment constraints shared across machines.

## Environment & Tooling

- **Dotfiles Repo**: Root (`~`/`$HOME`) is a dotfiles git repo. Exercise caution
  with git commands here.
- **Cloned Repos**: Located in `src/<host>/` (e.g., `src/github.com/`).
- **Package & Environment Managers**:
  - `mise`: Install tools/languages (`mise use -g <tool>`).
  - `aube`: Use exclusively instead of `npm` (NEVER `npm`).
  - `uv`: Use exclusively for Python packages/CLI tools (NEVER `pip`).
- **Git Hooks**: Managed by `hk` (`hk install`).
- **CLI Preferences**: `rg` (not `grep`), `fd` (not `find`). `git filter-repo`
  (not `filter-branch`), `jaq` for parsing/reading JSON.
- **Search/Grep**: ALWAYS use the custom `fff` tools (`fff_find_files`,
  `fff_grep`, `fff_multi_grep`).
  - CRITICAL: DO NOT use the built-in `grep` or `glob` tools.
  - CRITICAL: DO NOT use command-line `grep`, `find` in bash.

## Agent Skills

- `azure-devops-cli`: For Azure DevOps (ADO) and `az` CLI tasks.
- `git-commit`: For generating git commit messages.
- `agent-browser` / `chrome-devtools` (MCP): For browser automation/tasks.

## Formatting Constraints

- **Markdown**: Use `oxfmt`.
- **SQL**: Use `sqlfluff`.
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
    attribution for agent-authored commits (exclude basic tools like
    git/editor). _Example: `Assisted-by: OpenCode:gemini-3.1-pro-preview`_
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
