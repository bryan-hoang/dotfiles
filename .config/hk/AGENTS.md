# Global `hk` Configuration

This directory owns the machine-wide [`hk`](https://hk.jdx.dev/) configuration.
Changes here affect every repository that reaches the global Git hooks.

## Source of Truth

- [`config.pkl`](./config.pkl) is the Pkl configuration and the place to change
  lint, format, and hook policy.
  - `steps` defines reusable named steps.
  - `hooks` assigns steps to `check`, `fix`, `fix-minimal`, and Git hook events.
  - `exclude` defines paths omitted from the global configuration.
- `~/.config/git/hook.gitconfig` wires Git events to
  `mise x -- hk run <event> --from-hook "$@"`. Change that file only when
  changing which Git events invoke `hk`; change `config.pkl` for rule changes.
- A repository-local `hk.pkl` is not required for this global setup. A local
  configuration can still change the effective behavior for that repository.

## Change Workflow

1. **Trace the blast radius.** Read `config.pkl` and find every hook that
   consumes the step being changed. Add reusable behavior under `steps`, then
   reference it from the intended entries in `hooks`. Completion means every
   changed step is reachable from an intentional hook and no unrelated hook
   changed.
2. **Keep the release pins coherent.** Check the installed version with
   `mise x -- hk --version`. Keep the `amends` and `import` package URLs in
   `config.pkl` on the same compatible release; update both together when
   upgrading `hk`. Completion means `mise x -- hk validate` exits successfully.
3. **Run focused checks.** Check changed files with
   `mise x -- hk check <files>`. If formatting is intended, use
   `mise x -- hk fix <files>` and run the check again. Exercise an affected hook
   with `mise x -- hk run <hook>`, such as `pre-commit` or `fix-minimal`. Use
   `mise x -- hk check --all` only when a global change requires repository-wide
   coverage. Completion means the relevant commands pass and `git diff --check`
   is clean.
4. **Review the final diff.** Preserve unrelated working-tree changes,
   especially changes already present in `config.pkl`. Completion means the
   `AGENTS.md` diff contains only the requested documentation changes and
   preexisting `config.pkl` changes remain intact.

## Troubleshooting

- If Pkl evaluation fails after an `hk` upgrade, compare
  `mise x -- hk --version` with both package URLs in `config.pkl`, make the pins
  compatible, and rerun `mise x -- hk validate`.
- To bypass the global hooks for one Git command, use `HK=0 git <command>` in a
  POSIX shell or `$env:HK='0'; git <command>` in PowerShell. Use this only when
  the bypass is intentional.
