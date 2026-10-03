# Mise `v2026.9.10` Setup Conversion and Adoption Constraints

Research date: 2026-09-17\
Release examined: immutable release tag `v2026.9.10`, commit
`9caff41702d293a13eda9f5ea36d1c33420755ad`.[`R1`](https://github.com/jdx/mise/releases/tag/v2026.9.10)

Method: static review of official documentation, tagged implementation, and
tagged tests only. No mise or Git command was run, and no mise or Git state was
changed.

## Outcome

**Gate status: verified, with one fresh-conflict sequence left unresolved.** For
this project's append-only requirement, mise accepts a new default-branch tip
that is an ordinary Git commit descended from the old `main` tip. Its tree must
contain a valid format-1 marker, a valid format-1 enrollment manifest, and the
intended portable streams. Older ancestors do not need mise metadata. The commit
does not need a mise-specific message
trailer.[`S1`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/format.rs)[`S2`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/manifest.rs)[`S4`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/shadow.rs)[`S5`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/run.rs)

The official workflow documents publishing to an empty private repository. It
does not document a command that converts an arbitrary nonempty repository in
place. The tagged implementation nevertheless accepts an ordinary append-only
conversion commit once its tip satisfies the setup-repository contract. This is
source-derived compatibility, not a documented conversion
workflow.[`D1`](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md)[`S4`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/shadow.rs)

Existing legacy paths do not all have to be deleted from the converted tip.
Files outside the manifest's enrolled streams can remain as **repository-only
files**: mise retains them in the complete Git tree but does not restore them
under `HOME`. They can still cause Git-level merge conflicts
later.[`D1`](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md)[`S2`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/manifest.rs)[`S5`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/run.rs)[`T2`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_incoming_enrollment)

For initial adoption, use a genuinely fresh mise history store and
`mise bootstrap --adopt`, not `mise dot origin set`. Fresh adoption was designed
to avoid creating an unrelated local root before comparing live files with the
setup
branch.[`D2`](https://github.com/jdx/mise/blob/v2026.9.10/docs/bootstrap.md)[`D3`](https://github.com/jdx/mise/blob/v2026.9.10/docs/bootstrap/setup.md)[`S8`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/onboard.rs)[`T3`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_bootstrap_from_git)[`T4`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_manifest_bootstrap)

## Evidence Labels

- **Documented** means stated in the official documentation at the `v2026.9.10`
  tag.
- **Source-derived** means required or accepted by the tagged implementation or
  demonstrated by its tagged tests, but not promised as a conversion workflow in
  the documentation.
- **Unresolved** means the documentation and source do not provide a fully
  consistent, tested answer without running a state-changing experiment.

## Exact Tip Contract

| Item                              | Exact `v2026.9.10` rule                                                                                                                                                                                                                                                                                  | Evidence                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| --------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Recognition marker                | The fetched branch tip must contain `.mise-history/format.toml`, parsable as TOML with integer `format = 1`. A missing marker classifies a nonempty branch as `Unmarked`; another format fails with an upgrade message.                                                                                  | Source-derived.[`S1`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/format.rs)                                                                                                                                                                                                                                                                                                                                          |
| Enrollment inventory              | Successful synchronization or adoption also requires `.mise-history/manifest.json`. The marker alone only selects the setup-repository path; a missing manifest fails with `setup repository has no enrollment metadata`.                                                                                | Source-derived.[`S5`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/run.rs)[`S8`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/onboard.rs)                                                                                                                                                                                                                                                       |
| Manifest object                   | The manifest must be a regular Git file (`100644`), no larger than 4 MiB, containing JSON format 1. Unknown and duplicate fields are rejected.                                                                                                                                                           | Source-derived.[`S2`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/manifest.rs)                                                                                                                                                                                                                                                                                                                                             |
| Portable content                  | Enrolled paths are `home/...`, `config`, or `config/...`; selected variants use tree roots such as `home@windows/`. `.mise-history/` is repository metadata and is never a live destination.                                                                                                             | Documented and source-derived.[`D1`](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md)[`S2`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/manifest.rs)[`S14`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/layout.rs)                                                                                                                                                                     |
| Branch selected by fresh adoption | `bootstrap --adopt` probes the repository's advertised default branch. If symbolic `HEAD` is unavailable, source fallback is `main`, then `master`, then the first advertised head. There is no `--branch` option on `bootstrap --adopt`.                                                                | Source-derived.[`S8`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/onboard.rs)[`S10`](https://github.com/jdx/mise/blob/v2026.9.10/src/cli/bootstrap.rs)[`T3`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_bootstrap_from_git)                                                                                                                                                                    |
| Ancestor metadata                 | Detection and incoming enrollment read the fetched tip. Earlier ordinary commits may lack both files and may lack mise commit trailers. If an ancestor does contain `.mise-history/manifest.json`, readers and the ancestry audit parse it, so malformed reserved metadata can still fail the operation. | Source-derived.[`S1`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/format.rs)[`S2`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/manifest.rs)[`S4`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/shadow.rs)[`S5`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/run.rs)[`S16`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/files.rs) |
| Encrypted-stream ancestry         | Every reachable version at a path marked encrypted by any reachable manifest must be a valid encrypted envelope. Earlier plaintext at that same canonical path blocks adoption or publication unless plaintext history is explicitly allowed.                                                            | Documented and source-derived.[`D1`](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md)[`S16`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/files.rs)                                                                                                                                                                                                                                                        |

The marker text generated by this release
is:[`S1`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/format.rs)

```toml
# This repository is a mise setup repository (`mise dot origin set`).
# Do not edit: mise reads this to recognize the layout it publishes.
format = 1
```

The manifest has these top-level
fields:[`S2`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/manifest.rs)

```json
{
  "format": 1,
  "enrollment": [
    {
      "path": "home/example",
      "autosave": true,
      "encrypt": false,
      "variants": []
    }
  ],
  "exclude": [],
  "recipients": [],
  "permissions": {}
}
```

Each enrollment path must be unique and safe, and must be `home/...`, `config`,
or `config/...`. Path components cannot be empty, `.`, `..`, or `.git`
(case-insensitive), and cannot contain a backslash, colon, or control character.
Variant names are also validated and unique. Permission values must be at most
`0777` and must belong to an enrolled
stream.[`S2`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/manifest.rs)[`S14`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/layout.rs)

## Metadata Generation

Only explicit `mode = "track"` declarations from system or global configuration
create enrollment. Copy, symlink, template, and other deployment declarations do
not enroll their targets or sources
implicitly.[`D4`](https://github.com/jdx/mise/blob/v2026.9.10/docs/dotfiles.md)[`S3`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/tracked.rs)[`T6`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_explicit_tracking)

On capture, mise builds the portable content tree, carries eligible
repository-only files from the current parent, validates and pretty-serializes
the manifest, and overlays both `manifest.json` and `format.toml`. The
checkpoint then becomes an ordinary child commit of the current local history
head.[`S2`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/manifest.rs)[`S4`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/shadow.rs)

The runtime does **not** prove that these files were generated by mise, by this
exact release, or at all. There is no signature or generator field in the
manifest, and the reader accepts an ordinary Git commit with a valid explicit
inventory. The tagged test
`ordinary_commit_needs_only_explicit_portable_inventory` demonstrates that no
mise operation trailer is
required.[`S2`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/manifest.rs)[`S4`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/shadow.rs)

Therefore, the handoff's rule not to hand-author the manifest remains a sound
migration safety rule, but it is not a mise validation rule. Generating the
prototype with `v2026.9.10` and transferring its reviewed tree avoids subtle
schema, path, variant, permission, and encryption mistakes; mise itself checks
validity, not
provenance.[`S2`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/manifest.rs)[`S3`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/tracked.rs)

## NonEmpty Branch Conversion

The documented first-publication path starts with an empty
repository.[`D1`](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md)[`D3`](https://github.com/jdx/mise/blob/v2026.9.10/docs/bootstrap/setup.md)
`mise dot origin set` is not an importer or general converter for an existing
ordinary branch. For an unmarked nonempty branch, its preview says that
connecting does not import files or replace unrelated history and requires an
empty origin or explicit Git
reconciliation.[`S7`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/origin.rs)

After confirmation, `origin set` records an unmarked branch as deliberately
adopted, which bypasses the separate unmarked-repository refusal. That does not
synthesize enrollment metadata. Synchronization immediately reads the remote
manifest and still fails with `setup repository has no enrollment metadata` if
the ordinary branch has none. If the command first captured local tracked files,
the independent unrelated-history error can occur before the manifest
check.[`S5`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/run.rs)[`S7`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/origin.rs)

The tagged source accepts this append-only structure:

1. Generate the intended portable tree and metadata with `v2026.9.10` in an
   isolated history
   store.[`S2`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/manifest.rs)[`S4`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/shadow.rs)
2. Create an ordinary conversion commit whose parent is the current old `main`
   tip and whose tree adds the generated marker, manifest, and enrolled `home/`,
   `config/`, or variant
   streams.[`S2`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/manifest.rs)[`S4`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/shadow.rs)
3. Keep or remove each old tip path deliberately. Paths retained outside the
   enrolled streams become repository-only files rather than live adoption
   inputs.[`D1`](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md)[`S2`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/manifest.rs)[`T2`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_incoming_enrollment)
4. Make converted `main` the remote's advertised default branch before fresh
   adoption, because `bootstrap --adopt` has no setup-branch
   override.[`S8`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/onboard.rs)[`S10`](https://github.com/jdx/mise/blob/v2026.9.10/src/cli/bootstrap.rs)[`T3`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_bootstrap_from_git)
5. Advance remote `main` with an ordinary fast-forward push. The mise publisher
   also uses non-forced explicit `refspecs` and rejects
   divergence.[`S9`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/network.rs)[`S12`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/publish.rs)

This shape retains every old commit as an ancestor. Mise does not itself verify
the project-specific fact that the conversion commit descends from the
pre-conversion `main`; that must remain an external migration gate. Once the
remote contains that ancestry, a fresh adoption preserves
it.[`S6`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/graph.rs)[`S8`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/onboard.rs)[`T3`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_bootstrap_from_git)[`T4`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_manifest_bootstrap)

Append-only ancestry has one additional runtime consequence for encrypted
enrollment. Adoption audits all reachable commits and expands the protected set
from every manifest it finds. If an old commit already contains plaintext at the
same canonical stream path, such as `home/example`, a newly encrypted tip does
not make it safe and adoption fails unless plaintext history is explicitly
allowed. A legacy `.config/example` path is a different Git path from
`home/.config/example`, but its public contents remain a separate security
problem.[`D1`](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md)[`S16`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/files.rs)

## Extra Repository-Root Files

The official history documentation explicitly says repository files such as a
README stay in Git instead of being restored as live
configuration.[`D1`](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md)
The tagged end-to-end test adds `README.md` by ordinary Git, synchronizes it
into another mise history store, and verifies that no `$HOME/README.md`
appears.[`T2`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_incoming_enrollment)

The exact source behavior is:

- `home`, `config`, their variants, and `.mise-history` have special layout
  meaning. Other first path components, including a legacy `.config/` or
  `AppData/`, are not mapped and are not
  restored.[`S14`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/layout.rs)
- A later capture carries files from the parent when neither the previous nor
  current manifest owns their portable path. This is how README files and
  retained legacy paths survive mise-authored
  checkpoints.[`S2`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/manifest.rs)[`S4`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/shadow.rs)
- A base stream under an enrolled path is owned by that enrollment and is
  rebuilt from the selected live files. It should not also be treated as an
  independent repository-only
  namespace.[`S2`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/manifest.rs)
- All existing `.mise-history/` entries are skipped during carry-forward;
  `Manifest::write` recreates only the marker and manifest. Do not place
  maintenance files under this reserved
  directory.[`S2`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/manifest.rs)
- Synchronization merges the complete ordinary tree, not only live-eligible
  paths. Conflicts in README files, inactive variants, or other repository-only
  content pause repository adoption and require explicit Git
  reconciliation.[`S5`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/run.rs)[`S12`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/publish.rs)

Keeping old `.config/...`, `.ssh/...`, or `AppData/...` names as repository-only
files is therefore technically valid, but it does not make unsafe content safe:
the public Git objects and old ancestry remain reachable. Enrollment and
reachable-history security are separate
gates.[`D1`](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md)[`S9`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/network.rs)

## Git Ancestry Rules

Here, **local** means `refs/heads/main` in the separate mise history store, not
the branch checked out by the legacy home-root
checkout.[`S4`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/shadow.rs)

| Local mise head and fetched setup head   | `v2026.9.10` result                                                                                                                                                                                                     | Evidence                                                                                                                                                                                                                                                                                                                                                              |
| ---------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| No local head; remote head exists        | After the complete live preflight and application, use the exact remote commit as the adoption boundary. The operation outcome may append a child checkpoint, but the remote commit and its full ancestry are retained. | Source-derived.[`S6`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/graph.rs)[`S8`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/onboard.rs)[`S15`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/scope.rs)[`T4`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_manifest_bootstrap) |
| Heads equal                              | No new candidate is needed.                                                                                                                                                                                             | Source-derived.[`S6`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/graph.rs)[`S12`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/publish.rs)                                                                                                                                                                            |
| Remote is the unique ancestor of local   | Keep/publish the local descendant after validation.                                                                                                                                                                     | Source-derived.[`S6`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/graph.rs)[`S12`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/publish.rs)                                                                                                                                                                            |
| Local is the unique ancestor of remote   | Fast-forward by adopting the remote commit when its complete tree is the applied tree.                                                                                                                                  | Source-derived.[`S6`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/graph.rs)                                                                                                                                                                                                                                                                   |
| Both diverged from one unique merge base | Build a merge commit with local and remote as parents, but only after metadata, repository-only content, and live application are reconciled.                                                                           | Documented and source-derived.[`D1`](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md)[`S5`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/run.rs)[`S6`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/graph.rs)[`S12`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/publish.rs)        |
| No merge base                            | Fail with `local and origin histories are unrelated ... Neither history was replaced`.                                                                                                                                  | Source-derived.[`S6`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/graph.rs)[`T3`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_bootstrap_from_git)                                                                                                                                                                       |
| Multiple merge bases                     | Refuse enrollment application with `multiple merge bases require explicit Git reconciliation before applying enrollment`.                                                                                               | Source-derived.[`S5`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/run.rs)[`S6`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/graph.rs)                                                                                                                                                                                 |

Mise fetches the full branch for synchronization, uses ordinary Git ancestry,
and pushes only the selected branch without force. A rejected publication is
fetched and reconciled again; it is never
force-pushed.[`D1`](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md)[`S5`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/run.rs)[`S9`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/network.rs)[`S12`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/publish.rs)

`--replace-history` is an explicit fresh-adoption option for intentionally
discarding an unrelated **local mise history**. It requires a valid marked setup
repository, does not resolve differing live files, and restores the old local
branch and sync state if replacement application fails. It does not rewrite the
remote
branch.[`D1`](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md)[`D3`](https://github.com/jdx/mise/blob/v2026.9.10/docs/bootstrap/setup.md)[`S8`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/onboard.rs)[`T3`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_bootstrap_from_git)

## `origin set` Behavior

`mise dot origin set` performs more than recording a
URL:[`S7`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/origin.rs)

1. It validates the URL, resolves a branch, and fetches that complete branch
   into
   `refs/remotes/origin/setup`.[`S7`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/origin.rs)[`S9`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/network.rs)
2. With no `--branch`, it reuses the branch already followed for the same URL;
   otherwise it uses the remote's default branch. Only a repository with no
   branches at all falls back to creating `main`. A missing selected branch in a
   nonempty repository is an error, not an empty
   origin.[`S7`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/origin.rs)
3. It captures the current tracked set before asking for final connection
   confirmation. If the user declines, the preview fetch ref is restored, but
   that local capture is not rolled
   back.[`S7`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/origin.rs)
4. After confirmation it writes machine-local `[history.origin]`, records the
   selected mode when needed, records per-origin sync status, and runs an
   initial
   synchronization.[`D1`](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md)[`S7`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/origin.rs)
5. Switching URL or branch clears replaceable per-path sync bookkeeping but
   keeps local checkpoints. Switching origins therefore does not cure unrelated
   ancestry.[`S7`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/origin.rs)

URL validation rejects empty or option-like values and HTTP(S) URLs containing
credentials, query parameters, or fragments. Network operations use the user's
Git configuration, credential helpers, SSH, and URL
rewrites.[`D1`](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md)[`S9`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/network.rs)

`history.sync = "manual"` means no **background** network activity. It does not
make the `origin set` command itself fetch-only: manual mode is publication
capable during the command's initial sync. The tagged end-to-end test proves
that `origin set --sync manual --yes` publishes the existing local commits to an
empty origin. `fetch-only` is the connection mode that suppresses
publication.[`D1`](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md)[`S7`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/origin.rs)[`S12`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/publish.rs)[`T1`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_onboarding)

For this migration, rerunning `origin set` against the ordinary unmarked branch
is neither a dry run nor a conversion step. It can create a local root, write
machine-local configuration, and attempt publication before exposing the
manifest or ancestry
failure.[`S5`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/run.rs)[`S7`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/origin.rs)[`T1`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_onboarding)

## Fresh Adoption Rules

`mise bootstrap --adopt <url>` first probes only the remote default-branch tip.
If the tip has the marker, it follows the setup-repository path; if not, it
falls back to the older behavior of cloning an ordinary global mise
configuration repository into
`$MISE_CONFIG_DIR`.[`D2`](https://github.com/jdx/mise/blob/v2026.9.10/docs/bootstrap.md)[`S8`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/onboard.rs)[`S10`](https://github.com/jdx/mise/blob/v2026.9.10/src/cli/bootstrap.rs)[`T3`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_bootstrap_from_git)

A machine recorded as actively connected to another URL or branch is not
silently moved during adoption. It must first be disconnected with
`mise dot origin --remove` or deliberately moved with `mise dot origin set`; URL
and branch comparisons are
literal.[`S8`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/onboard.rs)

For a recognized setup repository, fresh
adoption:[`D2`](https://github.com/jdx/mise/blob/v2026.9.10/docs/bootstrap.md)[`D3`](https://github.com/jdx/mise/blob/v2026.9.10/docs/bootstrap/setup.md)

1. Fetches full branch ancestry into the separate mise bare history
   store.[`S8`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/onboard.rs)[`S9`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/network.rs)[`T4`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_manifest_bootstrap)
2. Reads enrollment from the remote manifest instead of capturing live files
   into a new local
   root.[`S5`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/run.rs)[`S8`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/onboard.rs)[`T3`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_bootstrap_from_git)[`T4`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_manifest_bootstrap)
3. Stages only explicitly enrolled active configuration for bootstrap preview;
   repository-only files are not staged as
   configuration.[`S8`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/onboard.rs)
4. Accepts a missing live file as a create and an existing byte-and-mode match
   as identical
   adoption.[`D3`](https://github.com/jdx/mise/blob/v2026.9.10/docs/bootstrap/setup.md)[`S11`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/apply.rs)[`T4`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_manifest_bootstrap)
5. Holds an existing differing file, an unusable path such as a directory, or a
   staged change for a decision. One held path prevents the complete incoming
   batch from being
   applied.[`D3`](https://github.com/jdx/mise/blob/v2026.9.10/docs/bootstrap/setup.md)[`S11`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/apply.rs)[`T3`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_bootstrap_from_git)[`T4`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_manifest_bootstrap)
6. Advances the local history head only after the complete written batch is
   validated again. A truly fresh adoption first adopts the exact remote commit;
   its normal operation outcome can then append a child checkpoint, preserving
   the remote commit and ancestry as
   parents.[`S6`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/graph.rs)[`S11`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/apply.rs)[`S15`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/scope.rs)[`T4`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_manifest_bootstrap)
7. Runs the remaining bootstrap only when no setup path is held. A held setup
   leaves existing files in place and tells the user to resolve them before a
   later
   `mise bootstrap`.[`D3`](https://github.com/jdx/mise/blob/v2026.9.10/docs/bootstrap/setup.md)[`S8`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/onboard.rs)[`S10`](https://github.com/jdx/mise/blob/v2026.9.10/src/cli/bootstrap.rs)[`T3`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_bootstrap_from_git)
8. Records the origin in machine-local configuration for future synchronization
   after confirmed adoption, including an adoption paused on live-file
   decisions.[`S8`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/onboard.rs)[`T3`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_bootstrap_from_git)

`--dry-run` uses disposable probe and preview stores, shows the incoming plan,
and does not persist the connection, fetched refs, or live files. The tagged
end-to-end test checks those
absences.[`D2`](https://github.com/jdx/mise/blob/v2026.9.10/docs/bootstrap.md)[`D3`](https://github.com/jdx/mise/blob/v2026.9.10/docs/bootstrap/setup.md)[`S8`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/onboard.rs)[`T3`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_bootstrap_from_git)

Before even probing the marker, bootstrap checks whether the global mise
configuration directory itself contains `.git`. If so, its `remote.origin.url`
must exactly match the expanded adoption URL. A setup repository is still kept
in the separate mise store; files written into that configuration checkout
appear as ordinary working-tree
changes.[`D2`](https://github.com/jdx/mise/blob/v2026.9.10/docs/bootstrap.md)[`S10`](https://github.com/jdx/mise/blob/v2026.9.10/src/cli/bootstrap.rs)[`T3`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_bootstrap_from_git)[`T5`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_bootstrap_compatibility)

That guard checks `$MISE_CONFIG_DIR/.git`, not a `.git` in an ancestor such as
the home-root checkout. Mise does not convert, detach, or retire the legacy
home-root checkout. Its pull preflight notices staged changes in containing Git
checkouts, but an otherwise clean ancestor checkout is not a substitute for the
explicit home switchover. The handoff's checkout-model warning remains
valid.[`S10`](https://github.com/jdx/mise/blob/v2026.9.10/src/cli/bootstrap.rs)[`S11`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/apply.rs)

## Handoff Corrections and Qualifications

| Handoff premise                                                                                                              | Verdict for `v2026.9.10`                                                                                                                                                                       | Constraint to carry forward                                                                                                                                                                                                                                                                                                                                       |
| ---------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `.mise-history/format.toml` and `.mise-history/manifest.json` are needed, and the absent manifest caused the reported error. | **Confirmed.** The marker routes setup adoption; the manifest supplies enrollment.                                                                                                             | Require and validate both at converted `main` tip.[`S1`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/format.rs)[`S2`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/manifest.rs)[`S5`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/run.rs)                                                       |
| `origin set` does not import an arbitrary ordinary dotfiles tree.                                                            | **Confirmed, with nuance.** It can record deliberate acceptance of an unmarked branch, but still cannot invent a missing manifest or related ancestry.                                         | Do not use it as the conversion mechanism.[`S5`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/run.rs)[`S7`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/origin.rs)                                                                                                                                                 |
| The manifest must have been generated by the exact mise release.                                                             | **Not runtime-enforced.** This is a prudent safety policy, not repository provenance checked by mise.                                                                                          | Generate it with `v2026.9.10` anyway; do not rely on provenance enforcement.[`S2`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/manifest.rs)[`S4`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/shadow.rs)                                                                                                                    |
| Full conversion requires every old root file to move into `home/` or `config/`.                                              | **Does not hold as a mise validity rule.** Extra root files may remain repository-only and are preserved.                                                                                      | Classify each legacy path, but deletion is not required merely for setup recognition.[`D1`](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md)[`S2`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/manifest.rs)[`T2`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_incoming_enrollment)                           |
| Apply the conversion as ordinary Git commits without rewriting old history.                                                  | **Confirmed.** Ordinary commits and their parent identities are supported; a special trailer is optional.                                                                                      | A reviewed append-only commit can be the conversion boundary.[`S4`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/shadow.rs)                                                                                                                                                                                                                     |
| `bootstrap --adopt <url>` will adopt converted `main`.                                                                       | **Incomplete.** It adopts the advertised default branch and offers no setup `--branch` flag.                                                                                                   | Ensure remote `HEAD` points to converted `main` before the dry run.[`S8`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/onboard.rs)[`S10`](https://github.com/jdx/mise/blob/v2026.9.10/src/cli/bootstrap.rs)[`T3`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_bootstrap_from_git)                                    |
| Keep manual mode during validation.                                                                                          | **Confirmed, with an omitted connection-time caveat.** It prevents automatic network activity; `origin set` still performs a publication-capable initial sync.                                 | Treat `origin set --sync manual` as state-changing network publication, not a safe preview.[`D1`](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md)[`S7`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/origin.rs)[`T1`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_onboarding)                           |
| The original command requested `--sync sync`, but the captured machine later reported `manual`.                              | **Unresolved machine state, not a `v2026.9.10` rule.** The selected mode drives the initial sync; the writer persists an override only when it differs from the effective pre-command setting. | Recheck the effective setting and configuration provenance on that machine rather than inferring intent from either observation.[`D1`](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md)[`S7`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/origin.rs)                                                                          |
| "Zero checkpoints" is sufficient evidence of a fresh store.                                                                  | **Needs qualification.** Ancestry uses the actual local history ref.                                                                                                                           | Verify that the store has no local `refs/heads/main`; a stale root still triggers ancestry rules.[`S4`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/shadow.rs)[`S6`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/graph.rs)[`T4`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_manifest_bootstrap) |
| The home-root checkout conflict must be resolved deliberately.                                                               | **Confirmed.** Mise protects live files and staged checkout changes, but does not redesign that checkout.                                                                                      | Keep the handoff's separate home-root checkout switchover gate.[`S10`](https://github.com/jdx/mise/blob/v2026.9.10/src/cli/bootstrap.rs)[`S11`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/apply.rs)                                                                                                                                     |

## Unresolved Uncertainty

The tagged setup guide says that after a fresh adoption pauses on a differing
file, the user can save that local file and then choose
`--keep-local`.[`D3`](https://github.com/jdx/mise/blob/v2026.9.10/docs/bootstrap/setup.md)
The tagged end-to-end tests establish two surrounding facts: `--keep-local`
fails before a saved local version exists, and a paused truly fresh adoption
leaves the local history branch
absent.[`T3`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_bootstrap_from_git)[`T4`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_manifest_bootstrap)

The save implementation creates an ordinary checkpoint parented only by the
current local history head, while the ancestry implementation rejects a new
local root with no merge base against the fetched setup
branch.[`S4`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/shadow.rs)[`S6`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/graph.rs)[`S13`](https://github.com/jdx/mise/blob/v2026.9.10/src/cli/dotfiles/save.rs)
No tagged test exercises the exact fresh-pause, save, then keep-local sequence.
Without the prohibited state-changing experiment, it is unresolved whether a
different path seeds the required ancestry. Do not make preservation of the work
machine's edits depend on that sequence until it is verified in a disposable
`v2026.9.10` environment. Preserve and reconcile those edits outside the fresh
store first, or make their adoption strategy an explicit later
decision.[`D3`](https://github.com/jdx/mise/blob/v2026.9.10/docs/bootstrap/setup.md)[`S4`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/shadow.rs)[`S6`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/graph.rs)[`S13`](https://github.com/jdx/mise/blob/v2026.9.10/src/cli/dotfiles/save.rs)[`T3`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_bootstrap_from_git)[`T4`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_manifest_bootstrap)

The append-only ordinary-commit conversion is also source-derived rather than
documented as a supported migration recipe. The ticket 11 generated-tree
prototype should validate the exact marker, manifest, tree layout, default
branch, and fresh dry-run before the real branch
changes.[`D1`](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md)[`S2`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/manifest.rs)[`S8`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/onboard.rs)

## Downstream Decision Gates

1. Treat a `v2026.9.10-generated` tree as the conversion input, while
   recognizing that generation provenance is a project safety gate rather than a
   runtime
   marker.[`S2`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/manifest.rs)[`S4`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/shadow.rs)
2. Require the conversion commit to be a descendant of the reviewed old `main`,
   and use only a normal fast-forward remote
   update.[`S6`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/graph.rs)[`S9`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/network.rs)[`S12`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/publish.rs)
3. Decide which legacy tip paths remain repository-only, which are replaced by
   enrolled portable streams, and which are removed. Extra root files are
   allowed but remain part of complete-tree
   reconciliation.[`S2`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/manifest.rs)[`S5`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/run.rs)[`T2`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_incoming_enrollment)
4. Ensure converted `main` is the remote default
   branch.[`S8`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/onboard.rs)[`T3`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_bootstrap_from_git)
5. Test adoption with a store whose local history ref is absent, using
   `bootstrap --adopt --dry-run`; do not reconnect with `origin set` as a
   preview.[`S7`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/origin.rs)[`S8`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/onboard.rs)[`T3`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_bootstrap_from_git)[`T4`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_manifest_bootstrap)
6. Resolve the home-root checkout switchover and the work-machine edit strategy
   before confirmed adoption. Mise will hold differences but will not migrate
   the old checkout
   model.[`S10`](https://github.com/jdx/mise/blob/v2026.9.10/src/cli/bootstrap.rs)[`S11`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/apply.rs)

## Primary Sources

- [`R1`](https://github.com/jdx/mise/releases/tag/v2026.9.10) Official immutable
  `v2026.9.10` release page and tagged commit.
- [`D1`](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md) Tagged
  official dotfiles-history documentation, especially "Sharing across machines"
  and "How shared history is stored."
- [`D2`](https://github.com/jdx/mise/blob/v2026.9.10/docs/bootstrap.md) Tagged
  official bootstrap documentation, especially "Starting from a repository" and
  "Shared dotfile history."
- [`D3`](https://github.com/jdx/mise/blob/v2026.9.10/docs/bootstrap/setup.md)
  Tagged official machine-setup guide, especially "Set up another machine" and
  "When the machine already has these files."
- [`D4`](https://github.com/jdx/mise/blob/v2026.9.10/docs/dotfiles.md) Tagged
  official dotfiles guide, especially tracking and portable-path behavior.
- [`S1`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/format.rs)
  Tagged setup-format detection and marker writer.
- [`S2`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/manifest.rs)
  Tagged manifest schema, validation, carry-forward, reader, and writer.
- [`S3`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/tracked.rs)
  Tagged explicit enrollment and portable tracking implementation.
- [`S4`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/shadow.rs)
  Tagged bare history, capture, ordinary-commit, and parentage implementation.
- [`S5`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/run.rs)
  Tagged synchronization orchestration, incoming manifest, and complete
  repository-tree reconciliation.
- [`S6`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/graph.rs)
  Tagged Git-head and merge-base reconciliation.
- [`S7`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/origin.rs)
  Tagged origin connection, preview, branch, and local-configuration behavior.
- [`S8`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/onboard.rs)
  Tagged setup-repository onboarding and fresh adoption.
- [`S9`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/network.rs)
  Tagged fetch, URL validation, and non-forced push implementation.
- [`S10`](https://github.com/jdx/mise/blob/v2026.9.10/src/cli/bootstrap.rs)
  Tagged bootstrap dispatch and configuration-checkout guard.
- [`S11`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/apply.rs)
  Tagged all-or-nothing incoming application and live-file preflight.
- [`S12`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/publish.rs)
  Tagged publication and complete-tree merge implementation.
- [`S13`](https://github.com/jdx/mise/blob/v2026.9.10/src/cli/dotfiles/save.rs)
  Tagged explicit save implementation.
- [`S14`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/layout.rs)
  Tagged portable branch layout and live-path mapping.
- [`S15`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/scope.rs)
  Tagged operation-boundary and outcome-checkpoint implementation.
- [`S16`](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/files.rs)
  Tagged encrypted-stream full-ancestry audit.
- [`T1`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_onboarding)
  Tagged end-to-end origin publication test.
- [`T2`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_incoming_enrollment)
  Tagged end-to-end incoming enrollment and repository-only README test.
- [`T3`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_bootstrap_from_git)
  Tagged end-to-end setup onboarding, default-branch, conflict, and replacement
  tests.
- [`T4`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_manifest_bootstrap)
  Tagged end-to-end manifest-driven fresh adoption test.
- [`T5`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_bootstrap_compatibility)
  Tagged end-to-end configuration-checkout origin-guard test.
- [`T6`](https://github.com/jdx/mise/blob/v2026.9.10/e2e/cli/test_dotfiles_explicit_tracking)
  Tagged end-to-end explicit tracking test.
