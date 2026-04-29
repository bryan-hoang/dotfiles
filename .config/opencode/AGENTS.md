# Personal Coding Agent Rules

This is a personal `AGENTS.md` for `opencode`, shared across machines via a
`dotfiles` git repo.

## Repository Context

- **Dotfiles Repo:** The root directory (`~`, `$HOME`) is a git repository
  managing dotfiles. Use caution when running git commands here.
- **Environment Management:** Use `mise` for installing tools/languages
  (`mise use -g <tool>`).
- **Package Manager:** Use `pnpm` (run via `pnpm dlx` instead of `npx`).
- **Git Hooks:** `hk` is used for git hooks (`hk install`).
- **Cloned Repos:** The `src/` directory contains cloned repositories organized
  by host (e.g., `src/github.com/`).

## Skills

- Use the `azure-devops-cli` skill when doing tasks relating to Azure DevOps
  (ADO). I.e., using the `az` CLI.
- Use the `git-commit` skill when writing git commit messages.
- Use the `agent-browser` skill or `chrome-devtools` MCP server to do browser
  related tasks.

## Tool Usage

- When parsing JSON output, use `jq` or `jaq`.
- Never use `pip` to manage python packages or install python CLI tools. Use
  `uv` instead.
- Use `pnpm dlx` over `npx`.

## Formatting Generated Code or Prose

- Don't use `prettier` to format `.json` files.
- Use `oxfmt` to format generated Markdown code.
- Use `sqlfluff` to format generated SQL code.
- Try to maintain a max line length of 80, 100, or 120 columns, especially for
  comments.

## Git Commit Messages

- Hard wrap commit messages to 80 columns.
- Include an explanation of why the changes are being made.
