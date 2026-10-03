# Generated Setup Tree Prototype

Prototype date: 2026-09-18\
Release: mise `2026.9.10 windows-x64`, executable SHA-256
`98f2b199c6b283547b66c8ab6d721aab977ff5e084f0e034b71596c7d2aba2e1`

## Outcome

The approved inventory is internally consistent, but the exact generated-tree
prototype is blocked by the isolation policy on this Windows host. This is not
an approved 176-root manifest, and the ticket remains open and unresolved.

Every runtime result in this report is preliminary and non-gating. Acceptance
requires a complete offline rerun with stock mise `2026.9.10` in the approved
Windows and Linux VM fixtures. The static inventory expansion remains planning
input to that rerun, not a substitute for generated runtime evidence.

The safe portions completed:

- All 176 records expanded to 235 synthetic regular files without reading source
  contents.
- The 421-path legacy partition, named live mise exception, stream policies,
  modes, bootstrap-repository count, and deferred-X11 boundary matched the
  approved inventory exactly.
- A preliminary stock-mise, configuration-root-only setup exercised marker and
  manifest generation, append-only conversion ancestry, default-branch
  recognition, dry-run behavior, confirmed adoption, and repository-only
  root-file behavior.
- A preliminary fresh pause, save, then `--keep-local` sequence exercised two
  fresh stores and exposed an unrelated-history failure.

## Inventory Proof

| Measure                               |       Expected |       Observed |
| ------------------------------------- | -------------: | -------------: |
| Legacy entries                        |            421 |            421 |
| Core / Windows / Unix coverage        | 263 / 57 / 101 | 263 / 57 / 101 |
| Enrollment roots                      |            176 |            176 |
| Exact / directory roots               |        174 / 2 |        174 / 2 |
| Shared / Windows / Linux roots        |  139 / 24 / 13 |  139 / 24 / 13 |
| Autosave on / off                     |       147 / 29 |       147 / 29 |
| Encryption / recipients               |          0 / 0 |          0 / 0 |
| Expanded files                        |            235 |            235 |
| Shared / Windows / Linux files        |  198 / 24 / 13 |  198 / 24 / 13 |
| `Nvim` / TeX directory descendants    |         57 / 4 |         57 / 4 |
| Regular `0644` / Git `100644` files   |      235 / 235 |      235 / 235 |
| Source / enrollment / stream overlaps |      0 / 0 / 0 |      0 / 0 / 0 |
| Active bootstrap repositories         |             11 |             11 |
| Deferred X11 sources / links          |        22 / 10 |        22 / 10 |
| Active X11 roots / repositories       |          0 / 0 |          0 / 0 |

The named live `~/.config/mise/config.toml` row is present exactly once as
`E006` and is absent from the 421-path legacy tree at
`dca1b12e99e7632c6911be647248762d75514d1e`. The full sorted expected stream
summary hashes to
`f65098cd323a45e0b6ab2b5c900a6cc875af1f4870ff5a3d403c455e894508f9`.

## Isolation Blocker

On Windows, mise `2026.9.10` obtains `dirs::HOME` from `homedir::my_home()`. The
pinned `homedir` implementation calls `SHGetKnownFolderPath(FOLDERID_Profile)`
and ignores process `HOME` and `USERPROFILE`. `MISE_CONFIG_DIR`,
`MISE_GLOBAL_CONFIG_FILE`, and `MISE_GLOBAL_CONFIG_ROOT` isolate configuration
but do not replace history's `home/` mapping root.

Consequences:

- Generating approved `home/...` paths with the stock Windows binary would
  require materializing the synthetic files at their real profile paths.
- A Windows capture cannot materialize the selected Linux streams; a stock Linux
  capture in a second isolated machine is also required.
- Hand-writing or rewriting the manifest would violate the ticket's provenance
  rule, so no full manifest was produced.

The approved temp root is also physically below the legacy home-root checkout.
The mise incoming preflight walks path ancestors for staged changes. A clean
disposable enclosing Git repository safely stopped that walk for the
configuration-root-only experiment, but it cannot change the fixed HOME mapping.

An initial probe, before this behavior was established, emitted a warning that
named the live mise settings file. A first dry run also attempted a read-only
staged-change check against the live home-root checkout and failed before
application. Neither operation changed live state. All successful experiments
used the corrected configuration boundary and disposable enclosing checkout.

## Preliminary Generated Control

The stock binary generated the retained preliminary minimal
[format marker](11-minimal-generated-format.toml) and
[manifest](11-minimal-generated-manifest.json) with `mise dot track`; neither
file was hand-authored in the disposable repository.

In the preliminary run, an ordinary conversion commit was the direct child of an
unmarked legacy tip. Its seven-file tree retained `README.md`, `package.json`,
`.config/legacy-record.txt`, and `.local/bin/install-dotfiles` as
repository-only files. The local bare remote advertised `main`; dry-run and
confirmed adoption recognized it as a format-1 setup repository. The old tip
remained an ancestor, the confirmed adopter's head descended from the conversion
tip, no `gitlink` existed, and none of the four extra root files was restored.

`mise bootstrap --adopt --dry-run` wrote no live file, origin configuration,
ref, or fetched object. It did initialize an empty bare repository, lock files,
and a runtime migration marker under the isolated state/data roots. The useful
no-write guarantee is therefore narrower than literal filesystem immutability.

## Preliminary Differing-File Result

The preliminary fresh sequence had two failure modes:

1. With no local declaration, paused adoption left no local head, then
   `mise dot save <path>` failed because the path was not captured.
2. With a command-generated declaration created while history was disabled,
   paused adoption again left no local head. `mise dot save <path>` created a
   new root commit. That root had no merge base with the conversion tip, and
   `mise dot pull --keep-local <path>` failed with
   `local and origin histories are unrelated`.

Both paths retained the synthetic local bytes. The local bare remote remained
unchanged. Preservation of a fresh machine's differing file must not depend on
save followed by `--keep-local`.

## Credential Containment

The safely known credential class is inherited `GITHUB_TOKEN`. It appeared only
in child-session tool output and in no filesystem artifact. No command used it
or contacted a GitHub or provider API after exposure. A provenance-verified
Kingfisher `2.4.0` scan with redaction, validation disabled, update checks
disabled, and no rule cache found no credential-like material in the source
workspace or prototype files. All verification output and disposable state were
deleted. The human confirmed revocation on 2026-09-18. No credential value is
recorded, and every inherited provider credential is treated as unusable.

## Confirmed Decisions

1. Acceptance uses separate stock Windows and Linux `VMs`. A fresh VM or
   approved stock base image needs a disposable checkpoint. Existing not
   reviewed `VMs` are ineligible, and instrumented mise builds remain
   exploratory only.
2. Permanent membership in the local Hyper-V Administrators group supplies VM
   management access; one-time elevation does not.
3. One shared virtual disk carries the setup repository and dependency mirrors.
   Only one VM may attach it at a time.
4. One stock OS seeds the local bare remote. The other adopts that lineage and
   adds its selected stream with byte-identical shared files.
5. Current runtime evidence remains preliminary and non-gating. Every runtime
   check reruns under strict isolation.
6. Differing live files are backed up externally and moved aside before fresh
   adoption. Reviewed local content is reconciled after remote ancestry exists,
   then saved as a descendant. A headless fresh store is never saved first.
7. Dry-run may create only empty repository metadata, locks, and migration
   markers in disposable state. It must create no refs, objects, origin
   settings, or live writes, and all allowlist-approved state is cleaned
   afterward.
8. Machine-local history sync is forced to manual and verified before probing.
9. Exact public HTTPS dependency declarations remain unchanged. Isolated Git URL
   redirects target local bare mirrors, while non-file protocols are denied.
10. Adoption applies history only. Bootstrap and deployment plans are tested
    separately against local substitutes.

## Primary Evidence

- [mise `v2026.9.10` release](https://github.com/jdx/mise/releases/tag/v2026.9.10)
- [Windows HOME selection](https://github.com/jdx/mise/blob/v2026.9.10/src/env.rs)
- [Tracked-path mapping](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/tracked.rs)
- [Format marker writer](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/format.rs)
- [Manifest writer](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/manifest.rs)
- [Fresh-machine setup guide](https://github.com/jdx/mise/blob/v2026.9.10/docs/bootstrap/setup.md#when-the-machine-already-has-these-files)
- [Pull conflict implementation](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/apply.rs)
- [Approved inventory](../matrices/10-approved-enrollment-inventory.md)
