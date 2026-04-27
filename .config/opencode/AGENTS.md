# Personal Coding Agent Rules

## Skills

- When using the `az` CLI tool, use the `azure-devops-cli` skill
  - Try using `jq` to parse the JSON output of `az` commands where reasonable to
    reduce token usage.
- Use the `git-commit` skill when writing git commit messages
- Use the `agent-browser` skill to do browser related tasks.

## Tool Usage

- When parsing JSON output, use `jq`
- Never use `pip` to manage python packages or install python CLI tools. Use
  `uv` instead.

## Formatting Generated Code or Prose

- Don't use `prettier` to format `.json` files
- Use `oxfmt` to format generated Markdown code
- Use `sqlfluff` to format generated SQL code
- Try to maintain a max line length of 80, 100, or 120 columns, especially for
  comments.

## Git Commit Messages

- Don't commit or stage any changes made if unspecified
- Hard wrap commit messages to 80 columns
