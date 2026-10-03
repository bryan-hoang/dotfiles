# Reachable Sensitive-History Audit (Redacted)

Audit date: 2026-09-17

## Outcome

**Audit status: resolved. Enrollment status: pending the sensitive-data policy
decision.** Provenance-verified MongoDB Kingfisher `v2.4.0` produced zero
findings across the complete reachable repository history and zero findings in
the separately scanned live mise file. A targeted, value-suppressing review of
57 sensitive-path candidates and 303 unique reachable blobs found no direct
credential value, credential-bearing URI, or private-key material.

No reusable credential, private key, token, cookie, or authentication session
was confirmed. This is not proof that arbitrary sensitive data cannot exist:
Kingfisher applies secret-detector rules, not a complete personal-identity or
private-infrastructure policy. The targeted review confirmed identity, account,
endpoint, and machine metadata in the path classes recorded below, plus
command-based credential-store indirection in three current account
configurations. Those paths still require the explicit disposition owned by
[Set the sensitive-data and encryption policy](https://github.com/bryan-hoang/dotfiles/issues/350).

Validity and rotation status remain unknown for every nonempty
credential-capable or identity-bearing artifact. No provider was contacted. The
two all-history empty-file findings are the only cases where repository metadata
proves that no value exists in the artifact.

## Scope and Isolation

- Source repository: the workspace clone
- Named live exception: `~/.config/mise/config.toml`
- Reachable refs: `refs/heads/main`, `refs/remotes/origin/HEAD`, and
  `refs/remotes/origin/main`
- Reachable tip for all three refs: `dca1b12e99e7`
- Reachable history: 2,534 commits; source and audit mirror were non-shallow

The repository scan used a disposable `git clone --mirror --no-local` under the
approved external temporary directory. The mirror contained the same three ref
names and object IDs as the source, including both remote-tracking refs, and
`git rev-list --all --count` returned 2,534 in both repositories.
`git fsck --unreachable --no-reflogs` found no unreachable mirror objects. The
scanner therefore inspected the exact closure advertised by the source refs,
rather than loose or unreachable source objects.

Both scanner invocations used only one-shot mise execution pinned to
`github:mongodb/kingfisher@2.4.0`. Each included `--redact`, `--no-validate`,
`--no-update-check`, `--no-rule-cache`, `--quiet`, JSON output, and an output
path outside the repository. The Git invocation additionally used selector-free
`--git-history full`. No configuration file, validation, revocation, blast
radius, remote target, webhook, alert, or viewer option was used.[`S1`] [`S2`]

## Scanner Coverage

| Target                       | Recorded scope and status                                                  |                                  Volume | Detector findings |
| ---------------------------- | -------------------------------------------------------------------------- | --------------------------------------: | ----------------: |
| Disposable repository mirror | `completed`; `all_fetched_git_objects`; 2,534 fetched commits; non-shallow | 4,132 eligible blobs; 100,353,796 bytes |                 0 |
| Named live mise file         | `completed`; local file                                                    |                        1 blob; 80 bytes |                 0 |

Kingfisher's report version was `2.4.0`, its update-check status was disabled,
and both JSON finding arrays were empty. Structural JSON checks confirmed all
required safety flags and no forbidden feature flags. The report schema had no
finding objects from which an unredacted value could be retained. Each quiet
terminal capture contained only the same non-secret mise warning about an
ignored repository setting. No raw report body was printed.

Kingfisher records selector-free full-history scans as
`all_fetched_git_objects`; its `v2.4.0` enumerator indexes the local object
database before scanning eligible blobs.[`S2`] [`S3`] Source refs and source
status were unchanged after cloning and scanning. The mirror, reports, terminal
captures, and review script were deleted after this report was written.

## Scanner Findings

There are no scanner-affected paths, detector classes, commit ranges, or values
to report. All built-in Kingfisher rule classes returned zero findings for both
targets. No rotation task is triggered by a detected repository or live-file
value; later review of other live machine files remains outside this audit and
must not infer rotation from this result.

## Metadata-Resolved Findings

| Path                      | Class                                                  | Reachable                                                                               | Current state   | False-positive rationale                                                                                                              | Required gate                                                                                                                                             |
| ------------------------- | ------------------------------------------------------ | --------------------------------------------------------------------------------------- | --------------- | ------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `.config/git/credentials` | Credential-store filename; no Kingfisher rule hit      | Introduced `6989dc6c3801`; reachable at `dca1b12e99e7`                                  | Current         | Its sole unique reachable blob is empty, as is the source worktree file. Repository metadata proves no value exists in this artifact. | No validity or rotation gate from this artifact. Exclude the placeholder or keep it empty under the policy decision.                                      |
| `.config/yarn/config`     | Registry-auth-capable filename; no Kingfisher rule hit | Introduced `86f5d826747d`; reachable at `dca1b12e99e7`                                  | Current         | Its sole unique reachable blob is empty. Repository metadata proves no value exists in this artifact.                                 | No validity or rotation gate from this artifact. Exclude the behavior-free placeholder.                                                                   |
| `.local/share/pass`       | Password-store pathname                                | Added `c90307e02333`; changed `41b8173fd8b5` and `06cd3f34594f`; deleted `cd1fc0c11735` | Historical only | Every reachable entry is Git mode `160000`: this repository stores commit pointers, not password-store content.                       | Do not infer that the linked repository is safe. Keep the `gitlink` repository-only and audit that dependency separately before any restoration decision. |

The filename screen found no reachable private-key, cookie-file, session-file,
`.env`, `.netrc`, credential-database, or keyring path. Filename review cannot
clear a value embedded under an ordinary path, which is why the independent
full-object scan was required.

## Targeted Safe Review

The follow-up review inspected only the 57 candidates already identified by path
role, clean-filter metadata, or identity-bearing format. It deduplicated their
reachable content to 303 blobs and emitted only path names, counts, booleans,
and safe commit IDs. It retained no values or snippets.

The review produced these false-positive resolutions:

| Paths                                 | Review class                                                      | Reachable                                               |                                     Count | Rationale and gate                                                                                                                                                                       |
| ------------------------------------- | ----------------------------------------------------------------- | ------------------------------------------------------- | ----------------------------------------: | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `.npmrc`, `.config/npm/npmrc`         | Registry authentication field names                               | Historical and current, respectively                    | 4 reviewed blobs with auth-capable fields | No reachable version had a direct credential value or credential-bearing URI. Rotation remains unknown; securely reconcile any distinct live work-machine file before enrollment.        |
| `.myclirc`, `.config/mycli/myclirc`   | Token-name heuristic                                              | Historical and current, respectively                    |                            2 unique blobs | Matches were syntax-presentation metadata, not authentication tokens. Database identity and endpoint settings still require policy review.                                               |
| `.config/himalaya/config.toml`        | Authentication-method metadata and credential command indirection | First touched `b9a2df9e7246`; current at `dca1b12e99e7` |                            2 unique blobs | Method selectors were not secrets; credential inputs are command-redirected rather than stored directly. Keep reusable inputs outside enrollment and review account identity separately. |
| `.config/meli/config.toml`            | Credential command indirection                                    | First touched `d6539c4d5c60`; current at `dca1b12e99e7` |                             1 unique blob | The stored configuration references a credential-producing command, not a direct value. Keep the reusable input and private item identity outside public enrollment.                     |
| `.config/spotifyd/spotifyd.conf`      | Credential command indirection                                    | First touched `05d8f5f94c1c`; current at `dca1b12e99e7` |                             1 unique blob | The stored configuration references a credential-producing command, not a direct value. Keep the reusable input outside enrollment.                                                      |
| `.config/windows/lemonade-server.xml` | Session-name heuristic                                            | Added `0e5b263e8000`; current at `dca1b12e99e7`         |                             1 unique blob | The match controls Windows execution-session behavior; it is not a cookie or authentication session. The task export still carries machine/account metadata and must be regenerated.     |

No reviewed blob contained a private-key marker. No reviewed value matched the
targeted credential-URI screen. The review did not treat a command that obtains
a credential as evidence that the credential is valid, rotated, or safe.

## Credential-Capable Path Ledger

Kingfisher returned zero findings for every path below, and the targeted review
found no direct credential field value. They remain policy findings because
their formats can hold reusable credentials or account metadata and because a
separate live copy may differ from the repository blob.

| Path                                     | Class                                         | Reachable status                                                   |
| ---------------------------------------- | --------------------------------------------- | ------------------------------------------------------------------ |
| `.config/docker/config.json`             | Registry authentication                       | First touched `6a630da79739`; current                              |
| `.npmrc`                                 | Package-registry authentication               | Touched `b9a2df9e7246..0e142e892c2f`; historical only              |
| `.config/npm/npmrc`                      | Package-registry authentication               | First touched `07481cb8a491`; current; last touched `33f4f5b71f90` |
| `.config/pnpm/rc`                        | Package-registry authentication               | Touched `00dc6e4dfefb..7dc75ddcb3a2`; historical only              |
| `.config/pnpm/config.yaml`               | Package-registry authentication               | First touched `7dc75ddcb3a2`; current; last touched `32154adbfcfb` |
| `.config/bundle/config`                  | Package-registry authentication               | First touched `36408011a713`; current; last touched `aac665e0570e` |
| `.gemrc`                                 | Package-registry authentication               | Touched `b9a2df9e7246..07481cb8a491`; historical only              |
| `.config/gem/gemrc`                      | Package-registry authentication               | First touched `1c8cefc21d85`; current; last touched `3df56557aa75` |
| `.config/pip/pip.conf`                   | Package-registry authentication               | First touched `306ee67dd70c`; current                              |
| `.config/pypoetry/config.toml`           | Package-registry authentication               | First touched `0a1e9579a078`; current; last touched `058f541fa255` |
| `.config/uv/uv.toml`                     | Package-registry authentication               | First touched `e950cdc5b9cf`; current                              |
| `.my.cnf`                                | Database authentication                       | Touched `b9a2df9e7246..75b18bdf938d`; historical only              |
| `.config/mysql/my.cnf`                   | Database authentication                       | First touched `6f74ffdef832`; current; last touched `d3003ceeceb7` |
| `.myclirc`                               | Database authentication                       | Touched `b9a2df9e7246..07481cb8a491`; historical only              |
| `.config/mycli/myclirc`                  | Database authentication                       | First touched `07481cb8a491`; current                              |
| `.config/pgcli/config`                   | Database authentication                       | First touched `b9a2df9e7246`; current                              |
| `.config/litecli/config`                 | Database authentication                       | First touched `b9a2df9e7246`; current                              |
| `.config/himalaya/config.toml`           | Mail account and credential indirection       | First touched `b9a2df9e7246`; current; last touched `de20bd3b0ace` |
| `.config/meli/config.toml`               | Mail account and credential indirection       | First touched `d6539c4d5c60`; current                              |
| `.config/spotify-tui/client.yml`         | Service client identity or credentials        | First touched `b9a2df9e7246`; current                              |
| `.config/spotifyd/spotifyd.conf`         | Service account and credential indirection    | First touched `05d8f5f94c1c`; current                              |
| `.config/ncspot/config.toml`             | Service account credentials                   | First touched `4505f13a19d3`; current                              |
| `.config/bigquery/bigqueryrc`            | Cloud project identity or authentication      | First touched `ca3e60865ed7`; current                              |
| `.config/gh/config.yml`                  | Service account preferences                   | First touched `b9a2df9e7246`; current; last touched `023fb6a9ad77` |
| `.curlrc`                                | Network authentication, headers, or cookies   | Touched `b9a2df9e7246..07481cb8a491`; historical only              |
| `.config/.curlrc`                        | Network authentication, headers, or cookies   | First touched `07481cb8a491`; current; last touched `9b5fc213c4f1` |
| `.wgetrc`                                | Network authentication or cookies             | Touched `b9a2df9e7246..07481cb8a491`; historical only              |
| `.config/wget/wgetrc`                    | Network authentication or cookies             | First touched `07481cb8a491`; current; last touched `2df1d665ee9c` |
| `.config/youtube-dl/config`              | Account or cookie configuration               | First touched `b9a2df9e7246`; current                              |
| `.config/yt-dlp/config`                  | Account or cookie configuration               | First touched `b9a2df9e7246`; current; last touched `b15fcf08485c` |
| `.config/mise/conf.d/fnox.toml`          | Secret-manager integration                    | First touched `22db453fac87`; current; last touched `70b5c30cb7d7` |
| `.config/opencode/opencode.jsonc`        | Provider or service authentication capability | First touched `3eb7ca366dbe`; current; last touched `44c89d0dadc3` |
| `.config/opencode/plugins/inject-env.ts` | Environment-value injection logic             | First touched `4854c333075d`; current                              |
| `AppData/Roaming/streamlink/config`      | Legacy clean-filtered service configuration   | Touched `b9a2df9e7246..33d2e5163b43`; current                      |
| `.config/i3status-rust/config.toml`      | Legacy clean-filtered service configuration   | Touched `b9a2df9e7246..b62cd6c0a7f4`; current                      |
| `.config/macchina/macchina.toml`         | Legacy clean-filtered machine identity        | Added `8db1c5b9f3b9`; current                                      |

Required disposition for this ledger: ticket 05 must assign each exact path an
excluded, sanitized/replaced, repository-only, or approved sensitive
configuration treatment. Reusable credentials, credential stores, and live
secret inputs remain excluded. Legacy Git clean filters are not an enrollment
boundary. The modified work-machine npm configuration is a distinct live file
and must receive secure review during the already planned work-machine
reconciliation.[`S4`]

## Identity-Bearing Path Ledger

These are identity and access-topology findings, not Kingfisher secret-rule
findings. No private-key path or private-key material was found.

| Path                                  | Class                                     | Reachable status                                                   | Required gate                                                        |
| ------------------------------------- | ----------------------------------------- | ------------------------------------------------------------------ | -------------------------------------------------------------------- |
| `.ssh/config`                         | SSH identity, host, and access topology   | First touched `f9aa83c3ac95`; current; last touched `9bcefecc6582` | Exclude or replace with an explicitly approved sanitized source.     |
| `.ssh/rc`                             | SSH session setup                         | Touched `a307db63c69b..b9c37fd4b250`; historical only              | Do not restore without exact-path review.                            |
| `.gnupg/gpg.conf`                     | GPG identity metadata                     | Touched `b9a2df9e7246..ec64712ff38a`; historical only              | Never enroll parent key or trust state.                              |
| `.gnupg/gpg-agent.conf`               | GPG agent metadata                        | Touched `b9a2df9e7246..ec64712ff38a`; historical only              | Never enroll parent key, socket, or trust state.                     |
| `.local/share/gnupg/gpg.conf`         | GPG identity metadata                     | First touched `07481cb8a491`; current; last touched `e48ad71edfd8` | Review and enroll only this exact file if approved.                  |
| `.local/share/gnupg/gpg-agent.conf`   | GPG agent metadata                        | First touched `07481cb8a491`; current; last touched `e48ad71edfd8` | Review and enroll only this exact file if approved.                  |
| `.gitconfig`                          | Git identity and endpoint metadata        | Touched `b9a2df9e7246..07481cb8a491`; historical only              | Apply the policy decision to replacement fragments.                  |
| `git/.gitconfig`                      | Git identity and endpoint metadata        | Touched `b9a2df9e7246..90f35f747cd2`; historical only              | Apply the policy decision to replacement fragments.                  |
| `.config/git/config`                  | Git identity and endpoint metadata        | First touched `07481cb8a491`; current; last touched `01a5308abc17` | Split machine/private metadata before enrollment.                    |
| `.config/git/dotfiles.gitconfig`      | Git identity and endpoint metadata        | First touched `b9a2df9e7246`; current; last touched `df4a63b9187b` | Replace the legacy checkout coupling; review identity fields.        |
| `.config/git/src.gitconfig`           | Git identity and endpoint metadata        | Touched `90f35f747cd2..c97b0e7b3566`; historical only              | Do not restore without exact-path review.                            |
| `.config/git/windows.gitconfig`       | Git identity and endpoint metadata        | First touched `cf9b3b016f6b`; current                              | Review under the Windows profile.                                    |
| A legacy work-identity fragment       | Git identity and endpoint metadata        | First touched `90f35f747cd2`; current                              | Keep repository-only unless its caller is restored.                  |
| `.config/windows/atuin-daemon.xml`    | Exported Windows account/machine metadata | Added `486d7fbbbaa9`; current                                      | Regenerate for the adopting account; do not enroll the export as-is. |
| `.config/windows/glazewm.xml`         | Exported Windows account/machine metadata | Touched `486d7fbbbaa9..aa0ae3eb6c56`; current                      | Regenerate for the adopting account; do not enroll the export as-is. |
| `.config/windows/lemonade-server.xml` | Exported Windows account/machine metadata | Added `0e5b263e8000`; current                                      | Regenerate for the adopting account; do not enroll the export as-is. |

Mail, music-service, cloud-project, package-manager, and database paths in the
credential-capable ledger can also contain account identifiers and endpoints.
Validity and rotation remain unknown because identity metadata neither proves
nor disproves a reusable credential.

## Named Live Candidate

| Path                         | Class                                | Scope and result                                                                                                                        | Required gate                                                                                                                                              |
| ---------------------------- | ------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `.config/rtx/config.toml`    | Historical predecessor configuration | Added `2f3f39849b19`; modified through `70fa4683a76e`; renamed in `5990713f17fc`; historical only; 0 Kingfisher findings                | No detected-secret remediation. Preserve only through the approved migration disposition.                                                                  |
| `.config/mise/config.toml`   | Historical mise configuration        | Created by rename in `5990713f17fc`; modified through `d5d7f35faf39`; deleted in `fca12ebaa9a0`; historical only; 0 Kingfisher findings | No detected-secret remediation. Preserve only through the approved migration disposition.                                                                  |
| `~/.config/mise/config.toml` | Named live mise configuration        | Live-only; 1 blob and 80 bytes scanned; 0 Kingfisher findings; structural review found wrappers-only configuration                      | The scanner gate is clear. Ticket 05 still decides enrollment treatment; validity and rotation are unknown because no credential finding exists to assess. |

The live file differs in size from the historical file, so it was scanned and
reviewed independently. No other untracked file under `HOME` was crawled.

## Disposition Gates

1. Ticket 05 must decide the exact treatment of every credential-capable and
   identity-bearing path above; this audit does not approve broad directory
   enrollment.
2. Keep every reusable credential, private key, token, cookie, session, and
   credential store outside public enrollment. If a later live-file review
   discovers one, revoke or rotate it and remove plaintext from the new tip
   without rewriting existing ancestry.
3. Reconcile the work-machine live changes through their existing adoption
   ticket. This repository audit cannot clear bytes that were never present in
   the audited repository or named live exception.
4. Preserve append-only ancestry. No finding from this audit calls for history
   rewriting, force-pushing, or contacting a provider.

## Primary Evidence

- [`S1`]
  [Trusted scanner decision and provenance](https://github.com/bryan-hoang/dotfiles/issues/360),
  including the official
  [MongoDB Kingfisher `v2.4.0` release](https://github.com/mongodb/kingfisher/releases/tag/v2.4.0)
  and attested Windows artifact.
- [`S2`] MongoDB Kingfisher `v2.4.0`,
  [usage and repository coverage](https://github.com/mongodb/kingfisher/blob/v2.4.0/docs/USAGE.md).
- [`S3`] MongoDB Kingfisher `v2.4.0`,
  [`scan_audit.rs`](https://github.com/mongodb/kingfisher/blob/v2.4.0/src/scan_audit.rs)
  and
  [`git_repo_enumerator.rs`](https://github.com/mongodb/kingfisher/blob/v2.4.0/src/git_repo_enumerator.rs).
- [`S4`]
  [Legacy path and dependency inventory](04-legacy-path-and-dependency-inventory.md),
  including clean-filter, sensitive-path, task-export, and work-machine
  findings.
- Isolation and source-state evidence: local read-only `git for-each-ref`,
  `git rev-list --all --count`, `git rev-parse --is-shallow-repository`,
  `git fsck --unreachable --no-reflogs`, and `git status` checks before and
  after the audit.

No scanner report, terminal capture, audit clone, or review script remains on
disk, and no secret value is recorded in this report.
