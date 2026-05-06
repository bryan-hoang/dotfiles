# Personal Coding Agent Rules

Personal dotfiles and environment constraints shared across machines.

## Environment & Tooling

- **Dotfiles Repo**: Root (`~`/`$HOME`) is a dotfiles git repo. Exercise caution
  with git commands here.
- **Cloned Repos**: Located in `src/<host>/` (e.g., `src/github.com/`).
- **Package & Env Managers**:
  - `mise`: Install tools/languages (`mise use -g <tool>`).
  - `uv`: Use exclusively for Python packages/CLI tools (NEVER `pip`).
  - `pnpm dlx`: Use instead of `npx`.
- **Git Hooks**: Managed by `hk` (`hk install`).
- **CLI Preferences**: Use `jq`/`jaq` for JSON, `git filter-repo` (not
  `filter-branch`).

## Agent Skills

- `azure-devops-cli`: For Azure DevOps (ADO) and `az` CLI tasks.
- `git-commit`: For generating git commit messages.
- `agent-browser` / `chrome-devtools` (MCP): For browser automation/tasks.

## Formatting Constraints

- **Markdown**: Use `oxfmt`.
- **SQL**: Use `sqlfluff`.
- **JSON**: Do NOT use `prettier`.
- **Line Length**: Soft cap at 80, 100, or 120 columns (especially comments).

## Git Commit Standards

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
