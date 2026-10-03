# Home-Root Checkout Removal Forensics

Investigation date: 2026-10-02\
Ticket: [Determine what removed the home-root checkout and what it held](https://github.com/bryan-hoang/dotfiles/issues/364)

## Outcome

A command in the ticket 17 media-acquisition session deleted the profile by
mistake. It tried to assign a relative path to a variable named `$home`.
PowerShell variable names are case-insensitive, so `$home` is the read-only
automatic variable `$HOME`. The assignment failed, the variable kept the value
`~`, and the next statement recursively deleted the profile. The tool timeout
killed the process after two minutes, partway through `~\.local\share`.

The checkout was at `dca1b12`, the audited baseline. It held no unpublished
commits and no staged content newer than 2026-09-14. Every tracked file, every
`gitlink` commit, and the original named live mise configuration can be
recovered. The exact set of removed untracked files cannot be.

## Cause

Confidence: high.

| Fact          | Evidence                                                                                                                                                                                                                                                |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Session       | An OpenCode session from 2026-09-20, which worked ticket 17.                                                                                                                                                                                            |
| Command       | A shell call run from a private intake directory. It started with `$home='<relative intake subfolder>';if(Test-Path $home){[IO.Directory]::Delete((Resolve-Path $home),$true)};...`.                                                                    |
| Timing        | Ran from 13:25:44. The 120-second tool timeout killed it at 13:27:45.                                                                                                                                                                                   |
| Mechanism     | `(Get-Variable HOME).Options` is `ReadOnly, AllScope`. Assigning to `$home` raises a statement error but does not stop the script, so `$home` stayed `~`. `Directory.Delete(path, true)` removes every entry it can and skips read-only and open files. |
| Corroboration | At 13:27:46 the harness reported every skill under `~\.agents` as unavailable. `~\.git` was last written at 13:27. The running harness recreated `~\.cache\opencode` and rewrote `~\.config\opencode\cli.json` at 13:27.                                |
| Detection     | The session did not notice. Its next call checked only the key file, and it went on to write the ticket 17 comments at 13:35–13:38.                                                                                                                     |

Later cleanup commands in the same session used other variable names and
targeted only the temporary intake root.

## Scope

The deletion walked `HOME` in NTFS name order, so names that start with `.` came
first. It removed every entry it reached unless the file was read-only or open,
and it kept the parent directories of anything that survived.

- **Reached and removed:** `~\.agents`, `.bash_logout`, `.bash_profile`,
  `.bashrc`, most of `.cache`, nearly all of `.config` (tracked and untracked),
  `.editorconfig`, everything in `.git` except read-only object files,
  `.gitmodules`, `.hushlogin`, and `.local\bin`.
- **Kill point:** inside `.local\share`, at or before `atuin`. The directories
  under `.local\share` and `.local\state` still carry their original 2023–2026
  creation times.
- **Not reached:** everything that sorts after `.local`, including
  `.lycheeignore`, `.ssh`, `AppData`, `Desktop`, `Documents`, `Downloads`, and
  `src`.
- **Legacy tree:** 366 of the 421 entries at `dca1b12` were removed: 314 regular
  files, 17 executables, and 35 symlinks. The 55 survivors are 21 regular files,
  22 symlinks, and 12 `gitlink` worktrees. Nineteen of the surviving symlinks
  dangle because their `.config` targets are gone.
- **Untracked files:** every untracked or ignored file under `.config` and
  `.local\bin` that was not open was removed. Git cannot list what they were.
  The named live mise `~\.config\mise\config.toml` (`E006`) was one of them.

## Checkout State at Removal

The object store survived because Git writes its object files read-only. It
holds 11 packs and 122 loose objects: 2,540 commits, 8,310 trees, and 4,167
blobs.

| Commit tip            | Date       | Relation to `origin/main`                        | Paths touched                                                                            |
| --------------------- | ---------- | ------------------------------------------------ | ---------------------------------------------------------------------------------------- |
| `dca1b12`             | 2026-09-17 | Ancestor; the audited baseline                   | Not applicable                                                                           |
| `05d36e5` `autostash` | 2026-06-15 | Not on origin; based on an ancestor of `dca1b12` | `.config/aube/config.toml`, `.config/hk/config.pkl`, `.config/mise/conf.d/00-tools.toml` |
| `5c9a7ba` `autostash` | 2026-06-12 | Same                                             | `.config/aube/config.toml`                                                               |
| `8dc52d9` `autostash` | 2026-07-23 | Same                                             | `.config/opencode/opencode.jsonc`                                                        |

- **Unpublished commits:** none. `origin/main` (`cae675d`) was fetched only into
  the workspace clone, so its six newer commits are not in `~\.git`.
- **Staged content:** the newest loose object is from 2026-09-14, so nothing was
  staged after the baseline. The 45 unreachable objects (21 blobs, 24 trees) are
  older staging leftovers; their content was not inspected.
- **Unstaged edits:** any edits made between 2026-09-17 and the removal are
  unrecoverable. No evidence suggests there were any.
- **Lost metadata:** `HEAD`, `config` (remote and submodule settings), `index`,
  `refs`, `packed-refs`, and `logs`. The stash `reflog` is gone too, so it is
  unknown whether the three `autostash` commits were still listed in the stash.

## `Gitlinks`

The deletion did not reach the 12 `gitlink` worktrees under `src\github.com`.
Their `.git` files still point into `~\.git\modules\<owner>\<repository>`, but
all 45 module directories there keep only `objects`, with no `HEAD`, `config`,
`index`, or `refs`. As a result, `git rev-parse HEAD` fails in every worktree.

All 12 commits recorded at `dca1b12` are present in their module object stores.
The other 33 module directories belong to historical submodules.

## Live Writes After the Removal

| Path                                                                               | Class                   | Written                                     | Probable writer                | Compared with `dca1b12`                       |
| ---------------------------------------------------------------------------------- | ----------------------- | ------------------------------------------- | ------------------------------ | --------------------------------------------- |
| `.config/atuin/config.toml`                                                        | Legacy, `E038`          | Created 2026-09-20 21:14                    | `Atuin` regenerated a default  | Differs                                       |
| `.config/opencode/opencode.jsonc`                                                  | Legacy                  | 2026-10-01 23:54                            | OpenCode setup; `$schema` only | Differs                                       |
| `.config/mise/config.toml`                                                         | Named live file, `E006` | Directory 2026-09-28; file 2026-10-02 00:23 | Unknown                        | Six lines; differs from the one-line original |
| `.config/opencode/cli.json`                                                        | Untracked               | Rewritten 2026-09-20 13:27                  | Running harness                | Not applicable                                |
| `.config/opencode/service.json`, `package.json`, `package-lock.json`, `.gitignore` | Untracked               | 2026-09-25 to 2026-10-01                    | OpenCode                       | Not applicable                                |
| `.config/herdr/*`                                                                  | Untracked runtime files | From 2026-09-20 13:39                       | `Herdr`                        | Not applicable                                |
| `.local/bin/mise.exe`, `mise-shim.exe`                                             | Untracked               | 2026-09-25                                  | Mise reinstall                 | Not applicable                                |
| `~\.agents`                                                                        | Untracked               | 2026-10-02 00:23                            | The human, restoring skills    | Not applicable                                |

## Work-Machine Handoff

This event did not remove the private work-machine handoff note. Its folder
sorts after the kill point, and its siblings survived. The Recycle Bin holds no
entries from 2026-09-20 onward. The transcripts show only reads of the file, all
on 2026-09-17, and no agent delete or move. Its fate is unknown. The
reconciliation table in the
[legacy path inventory](04-legacy-path-and-dependency-inventory.md) is the
retained record.

## Recovery Sources

| Source                     | What it can restore                                                                                                                                                                            |
| -------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Workspace clone            | All tracked content at `dca1b12` and `cae675d`, including symlink targets and `gitlink` commit IDs                                                                                             |
| `~\.git\objects`           | The same history up to `dca1b12`, plus the three `autostash` commits and the 45 unreachable objects                                                                                            |
| `~\.git\modules\*\objects` | All 12 recorded `gitlink` commits; the worktrees themselves are intact                                                                                                                         |
| OpenCode transcripts       | The exact one-line original `E006` file. Full reads in three earlier session transcripts (2026-09-14 and 2026-09-17) agree. Listings may also identify some removed untracked `.config` files. |
| Recycle Bin                | Nothing                                                                                                                                                                                        |
| Volume shadow copies       | Not checked; reading them requires elevation                                                                                                                                                   |

## Inputs for Restoration

- **Target commit:** `dca1b12` was the pre-removal `HEAD`. `origin/main`
  (`cae675d`) fast-forwards from it.
- **Metadata:** rebuild `~\.git` around the surviving object store rather than
  cloning into `HOME`. Restore `HEAD`, `config`, and refs, then rebuild the
  index before restoring any working-tree file.
- **Back up first:** the two differing legacy files (`E038` and
  `opencode.jsonc`), the current `E006` file, and every untracked file that
  appeared after the removal inside tracked directories.
- **Do not overwrite:** `~\.agents`, `.local\bin\mise*.exe`, `Herdr` runtime
  files, or OpenCode package files.
- **Symlinks:** the 35 missing symlinks need native Windows symlinks. The 19
  dangling links will resolve again once their targets return.
- **`Gitlinks`:** recreate the metadata of each of the 12 module directories at
  its recorded commit, or re-clone them.
- **Safeguard:** never assign to PowerShell automatic variables such as `$HOME`,
  `$PWD`, `$Host`, or `$Input`. Before any recursive delete, check that the
  resolved target is strictly inside the approved disposable root and is not a
  link. `PSScriptAnalyzer` rule `PSAvoidAssignmentToAutomaticVariable` catches
  this mistake in scripts.

## Open Uncertainties

- The exact set of untracked files removed under `.config`, `.cache`,
  `.local\bin`, and the part of `.local\share` that sorts before `atuin`.
- Whether the three `autostash` commits were still stash entries.
- Whether any unstaged edits existed between 2026-09-17 and the removal.
- What happened to the work-machine handoff.

## Method

All checks were read-only against live state. Git objects were read through
disposable bare repositories in a disposable temp directory that referenced
`~\.git\objects` and each module object store as alternates. Transcript evidence
came from a copy of the OpenCode database in the same directory. The comparisons
used hashes and structure-only views, and no blob or configuration content was
printed. The temporary directory was deleted after a guarded check that its
resolved path was inside the approved temporary root. No live file, Git
directory, the Recycle Bin, or the workspace clone was modified.
