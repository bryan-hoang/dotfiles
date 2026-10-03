# Mise `v2026.9.10` Enrollment, Encryption, and Path Semantics

Research date: 2026-09-17

Version examined: mise `v2026.9.10`, tag commit
`9caff41702d293a13eda9f5ea36d1c33420755ad`. The release is immutable; this
report cites the documentation and implementation at that tag rather than
assuming that the live documentation will remain equivalent.
[Release](https://github.com/jdx/mise/releases/tag/v2026.9.10)

## Result

The legacy home-root checkout cannot be translated into one broad mise history
enrollment. History enrollment is an explicit filesystem inventory, not an
import of a Git index. `mode = "track"` accepts exact files or directories under
the home or mise configuration roots and refuses the home root itself. It
recurses into enrolled directories and ignores the user's Git index and ignore
rules. It does not accept the deployment-only `exclude` or `manifest = "git"`
fields. The migration therefore needs reviewed, granular enrollment roots and
global history exclusions.
[Dotfiles: files, directories, and symlinks](https://github.com/jdx/mise/blob/v2026.9.10/docs/dotfiles.md#files-directories-and-symlinks)
[Tagged tracking walker](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/tracked.rs#L1-L44)
[Tagged track declaration validation](https://github.com/jdx/mise/blob/v2026.9.10/src/system/files.rs#L934-L980)

For a public setup repository, the only behavior established as safe by the
official sources is storing reviewed public plaintext. `mise` can technically
store age ciphertext, but its own setup guide tells users to use a private
repository, and encryption leaves filenames, enrollment policy, recipients, Unix
permission metadata, commit timing, and ciphertext size visible. The official
sources do not state a public-origin threat model or promise that an encrypted
file is suitable for public disclosure. Treat encrypted publication as a
separate security approval, not as an implication of `encrypt = true`.
[Dotfiles: share with another machine](https://github.com/jdx/mise/blob/v2026.9.10/docs/dotfiles.md#share-with-another-machine)
[History: encrypted shared files](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md#encrypted-shared-files)
[Tagged encrypted envelope](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/files.rs#L11-L197)
[Tagged manifest schema](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/manifest.rs#L12-L113)

Bootstrap support is required for anything history does not recreate: the
watcher service; copy, link, or template deployment from canonical sources;
nested repositories; system paths and ownership; and any ACL, extended
attribute, or other metadata outside Unix mode bits. The setup configuration and
every required deployment source must themselves be explicitly enrolled and
shared. `mise dot pull` restores tracked bytes but does not install tools or
services, clone repositories, or render templates.
[History: sync immediately](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md#sync-immediately)
[Bootstrap: shared dotfile history](https://github.com/jdx/mise/blob/v2026.9.10/docs/bootstrap.md#shared-dotfile-history)
[Bootstrap repositories](https://github.com/jdx/mise/blob/v2026.9.10/docs/bootstrap/repos.md)
[Bootstrap files](https://github.com/jdx/mise/blob/v2026.9.10/docs/bootstrap/files.md)

## 1. Enrollment Roots and Repository Layout

### Allowed Roots

- Only explicit `mode = "track"` declarations enroll history. A copy, template,
  content, symlink, or `symlink-each` declaration does not implicitly enroll
  either its source or target. Tracking declarations are accepted from
  system/global configuration (including roots composed by global bootstrap
  configuration), not ordinary project configuration.
  [Tagged tracked-set construction](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/tracked.rs#L143-L278)
  [Tagged configuration-layer guard](https://github.com/jdx/mise/blob/v2026.9.10/src/system/files.rs#L775-L835)

- A tracking target must be absolute or start with `~/`, and after expansion it
  must be expressible in a portable way under the current home directory or the
  current global mise configuration directory. Arbitrary paths such as
  `/etc/hosts` are not history-eligible for enrollment. The repository maps them
  to `home/<relative-path>` and `config/<relative-path>`; the configuration root
  wins when it is inside home. Machine-specific absolute root names and drive
  letters are not stored.
  [Dotfiles: whole-file entries and tracking files](https://github.com/jdx/mise/blob/v2026.9.10/docs/dotfiles.md#files-directories-and-symlinks)
  [Tagged path mapper](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/layout.rs#L12-L104)

- The global mise configuration directory itself can map to `config`, but the
  home directory itself, any ancestor of it, and a filesystem root are refused
  as capture roots. Consequently, `[dotfiles] "~" = { mode = "track" }` is not a
  valid way to preserve a home-root checkout.
  [Tagged root refusal](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/tracked.rs#L750-L760)
  [Tagged manifest validation](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/manifest.rs#L348-L390)

- Repository-root files that are not mapped under `home/` or `config/`, such as
  a README, remain ordinary repository-only files and are not restored as live
  configuration.
  [History: how shared history is stored](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md#how-shared-history-is-stored)

### Exact Paths, Directories, Overlaps, and Path Spelling

- A tracking declaration is an exact file or directory path, not a glob. An
  enrolled directory includes files added below it later. Globs exist only in
  history exclusions.
  [Dotfiles: files, directories, and symlinks](https://github.com/jdx/mise/blob/v2026.9.10/docs/dotfiles.md#files-directories-and-symlinks)

- When tracking entries overlap, each file is owned by the most-specific
  enrollment root and receives that root's `autosave` and `encrypt` policy.
  Repeating the same normalized root does not create a second owner; an exact
  duplicate with a contradictory encryption policy is invalid.
  [Tagged ownership selection](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/tracked.rs#L280-L346)

- Existing non-link targets and their existing ancestors are canonicalized. The
  enrolled leaf is not followed when it is a symlink or Windows junction. A
  symlink/junction below home or the configuration root cannot be used as an
  intermediate parent: enroll the link itself, then enroll the real target by
  its real path. The home and global configuration roots may themselves be
  symlinks and are mapped to the corresponding root on each machine.
  [Dotfiles: files, directories, and symlinks](https://github.com/jdx/mise/blob/v2026.9.10/docs/dotfiles.md#files-directories-and-symlinks)
  [Tagged normalization and ancestor checks](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/tracked.rs#L708-L840)

- Repository paths use `/` on every platform. Unsafe components are rejected:
  empty components, `.`/`..`, a case-insensitive `.git`, backslash, colon, and
  control characters. Windows root matching tolerates case differences while
  deciding whether a target is under `home/config.`
  [Tagged path mapper and validation](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/layout.rs#L12-L104)
  [Tagged ancestor check](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/tracked.rs#L708-L840)

- History requires UTF-8-expressible path names. A non-UTF-8 enrollment path is
  rejected, and a non-UTF-8 descendant encountered during a tracked walk aborts
  that walk rather than inventing a portable name. The dotfiles page's
  `mise:path-bytes:` JSON convention applies to other dotfile reporting and is
  not evidence that history can store such a tracked filename.
  [Tagged tracked path checks](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/tracked.rs#L708-L840)
  [Tagged tracked walk](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/tracked.rs#L351-L600)

### This Is Not a Git Manifest Import

- History's walker decides what to capture and passes literal paths to its own
  bare Git repository. It deliberately does not use the legacy checkout's
  `.gitignore`, tracked set, clean/dirty state, or index. It never writes the
  user's checkout or index.
  [Tagged tracking contract](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/tracked.rs#L1-L44)
  [Tagged bare-repository contract](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/shadow.rs#L1-L30)

- `manifest = "git"` is a deployment feature for directory `copy` and
  `symlink-each`; it runs `git ls-files` against a canonical source. It cannot
  be combined with `mode = "track"`. Likewise, a per-entry `exclude` list is a
  deployment source filter and is invalid on a tracking entry.
  [Dotfiles: Git-tracked directories](https://github.com/jdx/mise/blob/v2026.9.10/docs/dotfiles.md#git-tracked-directories)
  [Tagged track validation](https://github.com/jdx/mise/blob/v2026.9.10/src/system/files.rs#L934-L980)
  [Tagged manifest mode validation](https://github.com/jdx/mise/blob/v2026.9.10/src/system/files.rs#L1050-L1080)

Migration consequence: do not enroll a large legacy directory expecting the
current public repository's index to bound it. Either enumerate reviewed history
roots with `[history].exclude`, or keep this repository as a canonical source
and deploy its Git manifest through `copy`/`symlink-each` plus bootstrap.
[Dotfiles: excluding files](https://github.com/jdx/mise/blob/v2026.9.10/docs/dotfiles.md#excluding-files)

### Capture Limits and Omissions

- Regular files over 16 MiB are omitted. A root scan stops after 100,000 files
  or 1 GiB. Special files and unreadable paths are omitted. A failed observation
  is not treated as deletion: the prior saved version is retained while other
  files can still be checkpointed, and the omission/incomplete scan is reported.
  [History: what a checkpoint records](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md#what-a-checkpoint-records)
  [Tagged limits](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/shadow.rs#L18-L30)
  [Tagged walker](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/tracked.rs#L351-L600)

- Git does not represent empty directories. Directory permission records are
  derived only for enrolled directories on the path to captured files, so an
  empty directory is not a portable history resource. Declare a required empty
  directory with bootstrap instead.
  [History: rolling back](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md#rolling-back)
  [Tagged permission capture](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/checkpoint.rs#L958-L1001)

## 2. Variants and Cross-Platform Destinations

Tracking variants create separate history streams for the same live path. `os`
accepts an OS with an optional `/arch`; `profile` matches an active mise
environment; one selector-free `default = true` may provide a fallback. A
profile contributes two specificity points, an OS one, and an architecture one.
The unique highest-scoring match wins. A top-score tie is invalid and skips the
path; no match and no default also skips it while preserving other machines'
streams. Variant streams appear as roots such as `home@macos/`.
[Dotfiles: variants](https://github.com/jdx/mise/blob/v2026.9.10/docs/dotfiles.md#different-contents-on-different-machines)
[Tagged variant selector](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/select.rs#L10-L123)

`autosave` and `encrypt` belong to the enrollment, outside the variant array, so
all streams of that enrollment share those policies. The recipient list is
global to all encrypted streams. Per-variant encryption, autosave, or recipient
sets are not expressible in this format.
[Tagged manifest schema](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/manifest.rs#L12-L113)

When `mise dot track <existing-path> --os ...` specializes an existing
`unvariant` declaration, the command inserts a `default` variant first so the
old shared stream continues serving other machines. Hand-written variants do not
receive that convenience; their selection follows only the array as declared.
[Tagged track variant edit](https://github.com/jdx/mise/blob/v2026.9.10/src/cli/dotfiles/track.rs#L180-L245)

Tracking variants cannot redirect a target. If Windows and Unix use different
live paths, use one of these shapes:
[Dotfiles: platform-specific destinations](https://github.com/jdx/mise/blob/v2026.9.10/docs/dotfiles.md#platform-specific-destinations)
[Tagged destination validation](https://github.com/jdx/mise/blob/v2026.9.10/src/system/files.rs#L160-L230)

1. Declare each native tracking path separately and give each declaration an
   appropriate OS selector.
2. Prefer one canonical source plus destination `variants` in `copy`, `symlink`,
   `symlink-each`, or `template` mode. Track the source and configuration, then
   let `mise bootstrap`/`mise dot apply` deploy the selected target.

The second shape avoids treating platform-generated bytes, line endings,
absolute paths, and executable modes as the same shared file. Changing a
selected deployment destination does not remove the old destination
automatically.
[Dotfiles: platform-specific destinations](https://github.com/jdx/mise/blob/v2026.9.10/docs/dotfiles.md#platform-specific-destinations)

## 3. Exclusions

There are two unrelated exclusion mechanisms:

| Mechanism                    | Applies to                                           | Semantics                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| ---------------------------- | ---------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `[history].exclude`          | Files below `mode = "track"` roots                   | Absolute/home-expanded glob program. Layers are concatenated in order; the last matching pattern wins, and a later `!glob` re-includes an earlier exclusion. Excluded files leave future checkpoints but remain in old commits. [History: explicit tracking and exclusions](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md#explicit-tracking-and-exclusions) [Tagged exclusion implementation](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/tracked.rs#L636-L675) |
| `[dotfiles].<entry>.exclude` | Source walks for directory `copy` and `symlink-each` | A component pattern without `/` matches at any level; a pattern with `/` is source-root-relative. Excluding a former `symlink-each` source removes its recorded link on apply; directory copy leaves an old target copy behind. It is invalid with `mode = "track"`. [Dotfiles: excluding files](https://github.com/jdx/mise/blob/v2026.9.10/docs/dotfiles.md#excluding-files) [Tagged track validation](https://github.com/jdx/mise/blob/v2026.9.10/src/system/files.rs#L934-L980)              |

`mise dot include <glob>` removes that exact global history exclusion. A
hand-written later `!glob` is how a narrow path is re-included under a broader
pattern. Exclusion is not local-only storage: there is no per-file local-only
history, and an old committed version remains shareable.
[History: explicit tracking and exclusions](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md#explicit-tracking-and-exclusions)
[Tagged include/exclude command](https://github.com/jdx/mise/blob/v2026.9.10/src/cli/dotfiles/exclude.rs)

### Built-in Protection and Hard Exclusions

- `*.local.toml` is always omitted, even under an encrypted enrollment. For
  non-encrypted policies, mise also omits `basenames` `.netrc`, `*.age`,
  `*.key`, `*.pem`, `*.gpg`, `*.kdbx`, `id_*`, `*token*`, `*secret*`,
  `credentials*`, and `oauth*`; under the mise configuration root it also
  recognizes `github_tokens.toml`, `hosts.yml`, and `age.txt`. Most of those
  name-based guards may be passed only by an encrypted policy; `.local.toml` may
  not.
  [Tagged credential exclusions](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/tracked.rs#L24-L43)

- The mise state, cache, data, installs, downloads, plugins, history store, and
  configured/default age and SSH identity paths are hard exclusions. Any `.git`
  component is also hard excluded. Encryption does not override these hard
  exclusions.
  [Tagged hard exclusions](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/tracked.rs#L600-L706)

The migration policy is stricter than the technical allowance in mise: reusable
credentials, private keys, tokens, cookies, sessions, and credential stores must
remain excluded even if a filename guard could be bypassed with
`encrypt = true`.
[Migration map](https://github.com/bryan-hoang/dotfiles/issues/345)

Official sources do not specify whether history exclusion matching should be
treated as case-insensitive on Windows/macOS, nor do they define collision
behavior for two repository names that differ only by case. Avoid relying on
case folding: use exact native spelling and test the generated setup on every
target filesystem. The tagged code delegates exclusion matching to
`globset::Glob` without documenting a mise portability contract.
[Tagged exclusion implementation](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/tracked.rs#L636-L675)

## 4. Autosave and Synchronization

- `autosave` defaults to `true`. `mise dot track` saves an initial baseline
  immediately, including when `--no-autosave` was selected; that flag affects
  later ordinary checkpoints. A baseline failure normally rolls back the new
  declaration. Encrypted enrollment is rejected while history is disabled and
  must be run outside `mise dot capture` so the encrypted initial baseline can
  be verified.
  [Dotfiles: saving and encryption](https://github.com/jdx/mise/blob/v2026.9.10/docs/dotfiles.md#saving-and-encryption)
  [Tagged enrollment transaction](https://github.com/jdx/mise/blob/v2026.9.10/src/cli/dotfiles/track.rs#L54-L444)

- One exception matters operationally: non-encrypted tracking may be declared
  while `history.enabled = false`; the command warns that no baseline was saved.
  A declaration alone is therefore not proof of a checkpoint. Verify
  `mise dot paths` and `mise dot status` before relying on enrollment.
  [Tagged baseline behavior](https://github.com/jdx/mise/blob/v2026.9.10/src/cli/dotfiles/track.rs#L54-L444)

- With `autosave = false`, ordinary watcher/other-file checkpoints carry the
  last explicitly saved version. Promote current contents by naming the path,
  `mise dot save <path>`; a bare automatic save does not silently promote it.
  Capture wrappers and operations that explicitly modify the path can include it
  in their before/after checkpoints.
  [History: saving](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md#saving)
  [History: operation checkpoints](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md#operation-checkpoints)
  [Tagged manual-save planner](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/checkpoint.rs#L850-L879)

- Automatic saving requires the `history-watch` user service. It uses a systemd
  user unit on Linux, a `LaunchAgent` on macOS, and a Scheduled Task on Windows.
  Ordinary edits wait for two seconds of quiet by default; noisy files are
  progressively throttled rather than excluded, while explicit saves are
  immediate.
  [History: automatic saves](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md#automatic-saves)
  [Services: user services](https://github.com/jdx/mise/blob/v2026.9.10/docs/bootstrap/services.md#user-services)

- Every content checkpoint requires a usable Git binary. Without Git,
  `mise dot save` fails; bootstrap operations may still run, but there is no
  content history to rely on. A replacement machine needs Git before setup
  adoption.
  [History: requirements and settings](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md#requirements-and-settings)

- Autosave and sharing are separate. `history.sync = "sync"`, an origin, Git
  credentials usable by the service, and the watcher are all required for
  unattended two-way synchronization. `autosave = false` is not a privacy
  boundary: once explicitly saved, its commits are pushed with the rest of the
  history.
  [Dotfiles: share with another machine](https://github.com/jdx/mise/blob/v2026.9.10/docs/dotfiles.md#share-with-another-machine)
  [History: choose a sync mode](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md#choose-a-sync-mode)

## 5. Encryption and Key Behavior

### What Is Encrypted

`encrypt = true` encrypts each captured regular file or symlink target before
its bytes enter Git. The editable/restored live file remains plaintext. The
stored blob is a mise envelope containing age ciphertext; the encrypted inner
record binds the repository path, Git mode, recipient-scheme hash, and content.
Encryption failure stops the checkpoint rather than falling back to plaintext.
[History: encrypted shared files](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md#encrypted-shared-files)
[Tagged encrypted envelope](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/files.rs#L11-L197)
[Tagged capture path](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/shadow.rs#L350-L525)

Encryption is content confidentiality, not metadata confidentiality. At least
these remain public in the setup Git history: the full path, enrollment roots,
variant names, `autosave`/`encrypt` flags, recipient strings, non-default Unix
permission bits, Git commit metadata, and encrypted blob size. The outer
encrypted Git object is mode `100644`, but its inner file/symlink mode and the
manifest's Unix permissions are restored after decryption.
[History: encrypted shared files](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md#encrypted-shared-files)
[Tagged manifest schema](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/manifest.rs#L12-L113)
[Tagged encrypted object handling](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/files.rs#L281-L367)

Global mise configuration control files cannot themselves be encrypted, and
inline `content`, block, line, or inline-template edits are not an encrypted
canonical form. Put approved sensitive material in a separately tracked external
source with `encrypt = true`, keep the public configuration declarative, and use
copy/template deployment if an application needs a generated plaintext target.
The rendered target is plaintext and needs its own permissions and tracking
decision.
[History: encrypted template sources](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md#encrypted-shared-files)
[Tagged control-file refusal](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/files.rs#L198-L215)
[Tagged incoming declaration validation](https://github.com/jdx/mise/blob/v2026.9.10/src/system/files.rs#L620-L715)

### Recipients and Identities

- `[history.encryption].recipients` is one effective list for every encrypted
  file. Each version is encrypted to every listed public recipient.
  Configuration layers do not concatenate recipient tables: a later
  system/global layer that declares `[history.encryption]` replaces the earlier
  list. The declaring configuration must be trusted, and an explicitly empty
  list is rejected. The stored manifest sorts/deduplicates the effective
  strings.
  [History: choose recipients](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md#choose-recipients)
  [Tagged recipient configuration](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/config.rs#L21-L60)
  [Tagged encrypted object commit](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/files.rs#L281-L367)

- Accepted recipient forms are native age `x25519` (`age1...`), SSH public keys,
  tagged age recipients (`age1tag1...`), and age-plugin recipients. Native age,
  SSH, and tagged public recipients can be used for background encryption.
  Parsing any plugin recipient requires interactive synchronization, so one
  plugin recipient in the list prevents watcher saves even if native recipients
  are also present.
  [History: choose recipients](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md#choose-recipients)
  [Tagged recipient parser](https://github.com/jdx/mise/blob/v2026.9.10/src/agecrypt.rs#L235-L291)

- Decryption identities are discovered from `MISE_AGE_KEY`, configured
  `settings.age.identity_files`, `settings.age.key_file`, the default
  `~/.config/mise/age.txt`, configured `settings.age.ssh_identity_files`, and
  default `~/.ssh/id_ed25519`/`id_rsa`. These private identities are separate
  from Git authentication and are hard-excluded from history.
  [History: choose recipients](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md#choose-recipients)
  [Tagged identity loader](https://github.com/jdx/mise/blob/v2026.9.10/src/agecrypt.rs#L304-L550)
  [Tagged hard exclusions](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/tracked.rs#L600-L706)

- `mise` does not prompt to unlock an SSH private key. A passphrase-protected,
  `encrypted-PEM`, unsupported-cipher, hardware, or unsupported-type SSH
  identity cannot decrypt history through this path; an SSH agent does not help
  age. Use a dedicated age identity for unattended history. Plugin identities
  can be invoked only during an interactive restore.
  [History: use an existing SSH key](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md#use-an-existing-ssh-key)
  [Tagged SSH identity classification](https://github.com/jdx/mise/blob/v2026.9.10/src/agecrypt.rs#L25-L83)

- Each machine that must decrypt needs a recipient present before the relevant
  version is saved. A machine without a matching identity can transfer the Git
  data but a pull that needs the file fails with `cannot unlock <path>`; because
  pull is a complete batch, this can hold the whole setup. Keep an independent
  recovery identity outside all enrolled paths.
  [History: generate a dedicated age key and recovery recipient](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md#generate-a-dedicated-age-key)
  [Tagged decrypt failure](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/files.rs#L238-L279)

- The docs instruct `chmod 600 ~/.config/mise/age.txt`, but the identity loader
  merely reads existing files; the official sources do not establish automatic
  permission repair for an identity file or a Windows ACL policy. Provision and
  audit key-file protection outside setup history.
  [History: generate a dedicated age key](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md#generate-a-dedicated-age-key)
  [Tagged identity loader](https://github.com/jdx/mise/blob/v2026.9.10/src/agecrypt.rs#L304-L550)

### Recipient Changes and Old History

Changing recipients re-encrypts a file the next time it is saved; it does not
rewrite earlier commits. Adding a machine later cannot make that machine read
old versions, and removing a recipient does not revoke that recipient's access
to old ciphertext. Add all intended machine and recovery recipients before the
first approved encrypted checkpoint.
[History: choose recipients](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md#choose-recipients)

Before publication, mise audits every reachable commit and merge parent for
paths that any reachable manifest or live policy marks encrypted. An earlier
plaintext/invalid envelope blocks push even when the tip is encrypted. The
`--allow-plaintext-history`/`allow_plaintext_history` escape hatch deliberately
publishes the plaintext and is not remediation. `mise` never force-pushes a
rewritten history.
[History: encrypted shared files and plaintext history](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md#encrypted-shared-files)
[Tagged ancestry audit](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/files.rs#L42-L130)

Migration consequence: with the map's append-only rule, adding encryption at the
new tip cannot make sensitive plaintext already reachable in the public ancestry
safe. Such a path needs the map's separate rotate/revoke and history decision;
it cannot be classified safe merely because its future versions are encrypted.
[Migration map](https://github.com/bryan-hoang/dotfiles/issues/345)

## 6. Permissions and Other Filesystem Metadata

On Unix, history preserves the low nine permission bits (`0o000` through
`0o777`) for regular files and enrolled directories. Git modes represent the
common regular-file defaults `0644`/`0755`; the plaintext manifest carries other
modes and non-default directory modes. Permission-only changes are checkpoint
changes and are restored on `pull/rollback.` Special bits, ownership, ACLs,
extended attributes, timestamps, and hard-link identity have no field in the
`v1` manifest.
[Tagged manifest schema and validation](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/manifest.rs#L12-L113)
[Tagged permission capture](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/checkpoint.rs#L958-L1001)
[Tagged permission apply](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/apply.rs#L418-L665)

On Windows, Unix permission capture and application are disabled and regular
files are captured as non-executable Git files. Windows read-only attributes,
ACLs, ownership, alternate data streams, and executable intent are not given a
portable history representation by the official sources. A shared `unvariant`
file that must remain executable on Unix should therefore use an OS-specific
stream or a canonical source deployed by bootstrap rather than relying on a
Windows save to preserve its Unix mode.
[Tagged non-Unix mode path](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/checkpoint.rs#L958-L1001)
[Tagged regular-file capture](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/shadow.rs#L534-L590)

For managed dotfiles, Unix inline `content` is created as `0600`, and a template
target takes the source file's permissions and repairs later drift. Ordinary
`[dotfiles]` writes run as the current user and do not elevate. For absolute
system paths, owner/group/mode, or root access, use `[bootstrap.files]` and
`[bootstrap.directories]`, which explicitly model and compare those fields and
can use a narrow privileged batch.
[Dotfiles: inline content](https://github.com/jdx/mise/blob/v2026.9.10/docs/dotfiles.md#inline-content)
[Dotfiles: templates](https://github.com/jdx/mise/blob/v2026.9.10/docs/dotfiles.md#templates)
[Dotfiles: root-owned files](https://github.com/jdx/mise/blob/v2026.9.10/docs/dotfiles.md#root-owned-files)
[Bootstrap files](https://github.com/jdx/mise/blob/v2026.9.10/docs/bootstrap/files.md)

### Platform Summary

| Behavior                | Unix                                                                                                                                                            | Windows                                                                                                                                      | Sources                                                                                                                                                                                                                                 |
| ----------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Stored path             | Native `home/config` prefix is replaced by `home/` or `config/`; repository separators are `/`.                                                                 | Same mapping; drive/root prefix disappears, repository separators are `/`, and root membership comparison tolerates case differences.        | [Tagged path mapper](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/layout.rs#L12-L104) [Tagged ancestor check](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/tracked.rs#L708-L840)               |
| Regular-file content    | Raw file bytes are hashed; mise does not normalize line endings.                                                                                                | Same, so `CRLF`/`LF` differences are content changes in an `unvariant` stream.                                                               | [Tagged regular-file capture](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/shadow.rs#L534-L590)                                                                                                                       |
| Permissions             | Git executable mode plus complete low-nine-bit mode metadata for regular files and enrolled directories.                                                        | No Unix mode capture/apply; ordinary files capture as non-executable.                                                                        | [Tagged permission capture](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/checkpoint.rs#L958-L1001)                                                                                                                    |
| Tracked link target     | Capture reads native target bytes, but replay decodes them as UTF-8 with possible loss before creating the link; only UTF-8 target text has a clear round trip. | Capture converts the target with possible loss to text and changes `\` to `/`; tracked file-link restoration is not documented as supported. | [Tagged link target encoding](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/shadow.rs#L1685-L1700) [Tagged history link restore](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/replay.rs#L1510-L1591) |
| Managed link deployment | `symlink`/`symlink-each` create symlinks.                                                                                                                       | File `symlink` attempts a real link then copies on failure; directory links use junctions; `symlink-each` copies.                            | [Dotfiles: Windows](https://github.com/jdx/mise/blob/v2026.9.10/docs/dotfiles.md#windows)                                                                                                                                               |
| Autosave service        | systemd user service on Linux; `LaunchAgent` on macOS.                                                                                                          | Scheduled Task.                                                                                                                              | [Services: user services](https://github.com/jdx/mise/blob/v2026.9.10/docs/bootstrap/services.md#user-services)                                                                                                                         |
| Conflict notification   | Supported Linux/macOS installs can issue desktop notifications.                                                                                                 | Use `mise dot status`/`mise doctor`; no desktop notification support is documented.                                                          | [History: conflict notifications](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md#conflict-notifications)                                                                                                                   |

## 7. Symlinks and Junctions

- History saves a symlink as the link, not the target contents. Enroll the real
  target separately if its content belongs in history. The saved target text is
  not rewritten between machine roots, so an absolute target remains
  machine-specific; a relative link is portable only when every machine has the
  same relative topology.
  [Dotfiles: files, directories, and symlinks](https://github.com/jdx/mise/blob/v2026.9.10/docs/dotfiles.md#files-directories-and-symlinks)
  [Tagged symlink capture](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/shadow.rs#L534-L590)

- On Unix, capture stores native link-target bytes, but replay converts them
  with lossy UTF-8 decoding before creating a symlink. Non-UTF-8 link targets
  therefore have no byte-exact round-trip contract. On Windows, capture already
  converts the target through a lossy string and changes `\` to `/`. The history
  restore path calls the general mise link helper; that helper's Windows
  implementation is `directory-link/junction-oriented.` The official Windows
  documentation does not promise that a tracked _file_ symlink can be restored.
  Do not use tracked file symlinks as a cross-platform canonical representation
  without a disposable Windows proof.
  [Tagged link target encoding](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/shadow.rs#L1685-L1700)
  [Tagged history link restore](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/replay.rs#L1510-L1591)
  [Tagged Windows link helper](https://github.com/jdx/mise/blob/v2026.9.10/src/file.rs#L1000-L1103)

- Managed `mode = "symlink"` has a different, documented Windows contract: it
  attempts a real file symlink (Developer Mode normally supplies permission) and
  falls back to copying if unavailable; directory links use junctions. Managed
  `symlink-each` copies files on Windows. `mise dot status` accepts the
  resulting form.
  [Dotfiles: Windows](https://github.com/jdx/mise/blob/v2026.9.10/docs/dotfiles.md#windows)
  [Tagged managed-link implementation](https://github.com/jdx/mise/blob/v2026.9.10/src/system/files.rs#L3527-L3550)

The official sources do not establish history behavior for arbitrary Windows
`reparse` points, directory junction capture, or cross-volume absolute link
targets. Represent required links declaratively in bootstrap/dotfile
configuration, or replace them with regular canonical sources, rather than
assuming history will round-trip every `reparse` type.

## 8. Nested Repositories and Git Links

When the walker encounters a Git repository _below_ an enrolled directory, it
does not descend into `.git` or working-tree content. It records a `Gitlink`
(`160000`) containing only the repository's current commit SHA. Dirty,
untracked, stashed, remote/configuration, branch, and object-database state are
not in that pointer. A failure to read the current SHA is an omission, not a
backup of the working tree.
[History: what a checkpoint records](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md#what-a-checkpoint-records)
[Tagged nested-repository detection](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/tracked.rs#L321-L341)
[Tagged `gitlink` capture](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/shadow.rs#L552-L570)

Rollback explicitly skips a `gitlink` whether it is present, missing, changed,
or deleted; it never writes into or removes the nested repository. The setup
guide therefore says to keep a nested repository backed up separately.
[Tagged rollback `gitlink` handling](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/replay.rs#L899-L1270)
[Setup: add more files](https://github.com/jdx/mise/blob/v2026.9.10/docs/bootstrap/setup.md#add-more-files)

An encrypted directory cannot safely absorb a nested repository as one of its
descendants in this release. The walker assigns the directory's encryption
policy to the `gitlink`, while the encryption envelope accepts only
regular-file, executable-file, or symlink modes and the capture path rejects a
non-file. Exclude the repository from that root and bootstrap it separately.
[Tagged encrypted capture](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/shadow.rs#L350-L525)
[Tagged encrypted mode validation](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/files.rs#L281-L367)

A `gitlink` is not enough for fresh-machine recreation: it carries no clone URL
and history does not promise submodule initialization. A required nested repo or
submodule needs `[bootstrap.repos]` (or another reviewed bootstrap mechanism)
with its URL and desired ref. Repository bootstrap runs before dotfile
deployment and refuses dirty or mismatched existing repositories rather than
resetting them.
[Bootstrap repositories](https://github.com/jdx/mise/blob/v2026.9.10/docs/bootstrap/repos.md)

The docs say "a nested Git repository is saved as a pointer" but do not define
the edge case where the repository directory itself is the exact enrollment
root. The tagged walker skips nested-repository detection for the enrollment
root and applies it only to descendants, which suggests that exact-root
enrollment walks regular working-tree files while still excluding `.git`.
Because documentation and this edge implementation are not an explicit portable
contract, do not rely on either shape: exclude repository roots from parent
enrollment and declare them as bootstrap repositories.
[Tagged tracked walk](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/tracked.rs#L351-L600)

## 9. Conflicts and Adoption

### Shared-History Conflicts

- A fresh machine with no common base accepts an identical existing file, but
  differing local and remote files need adoption. Missing live paths can be
  created. `--take-remote` chooses the setup repository; `--keep-local` chooses
  the machine's _saved_ version and therefore requires `mise dot save <path>`
  first.
  [Setup: machine already has these files](https://github.com/jdx/mise/blob/v2026.9.10/docs/bootstrap/setup.md#when-the-machine-already-has-these-files)
  [Tagged reconciliation table](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/reconcile.rs#L1-L380)

- With a common base, disjoint text edits are three-way merged. Same-hunk text,
  binary edits, delete/modify, file/symlink type changes, and divergent symlink
  targets become explicit conflicts. Unix mode metadata and enrollment metadata
  are merged separately; incompatible edits to the same enrollment field,
  recipient list, exclusion program, or permission path require repository-level
  reconciliation.
  [History: resolve a conflict](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md#resolve-a-conflict)
  [Tagged content reconciler](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/reconcile.rs#L1-L380)
  [Tagged manifest merge](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/manifest.rs#L126-L215)

- Unsaved live edits, staged changes in any containing user checkout, invalid
  incoming configuration/missing sources, an unreadable path, or a real
  directory where a repository file belongs also block application. A directory
  occupant must be moved; neither take-remote nor keep-local can reinterpret it
  as a file.
  [History: resolve a conflict](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md#resolve-a-conflict)
  [Tagged apply preflight](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/apply.rs#L850-L891)

- Pull is deliberately complete, not path-partial. One unsafe path holds the
  entire write batch; conflicts pause both publication and application for all
  tracked files while local saves and remote fetches continue. Decisions are
  bound to the observed local, remote, live, and permission versions and are
  validated again before writing.
  [History: sync immediately and resolve a conflict](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md#sync-immediately)
  [Tagged all-or-nothing apply](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/apply.rs#L112-L488)

- `v2026.9.10` adds `--take-remote-all` and `--keep-local-all`. Per-path flags
  act as exceptions. A blanket decision records choices it can make and holds an
  unusable/unsaved path instead of discarding all other choices, but nothing is
  applied or published until every conflict is resolved.
  [Release](https://github.com/jdx/mise/releases/tag/v2026.9.10)
  [Tagged bulk-resolution path](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/apply.rs#L133-L260)

- Divergent/unrelated histories, inactive-stream repository conflicts, or
  multiple merge bases may require an explicit separate Git checkout and Git
  repair. `mise` uses fast-forwards and merge commits and does not force-push.
  [History: shared storage and conflict resolution](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md#how-shared-history-is-stored)
  [Tagged multiple-base refusal](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/run.rs#L987-L1010)

An encrypted conflict also requires an available decryption identity before mise
can inspect, merge, or apply it. A missing key is not treated as an optional
file conflict.
[Tagged decrypt path](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/sync/files.rs#L238-L279)

### Managed-Dotfile Conflicts Are Separate

`mise dot apply` refuses to replace a real file/directory with a configured
symlink unless `--force` is given. Copy and template entries overwrite changed
targets without `--force`; edit entries reject a symlink target. These are
deployment conflicts, not history adoption conflicts. `--force-dotfiles` and
`--replace-history` do not resolve an existing-file history conflict.
[Dotfiles: conflicts](https://github.com/jdx/mise/blob/v2026.9.10/docs/dotfiles.md#conflicts)
[Setup: machine already has these files](https://github.com/jdx/mise/blob/v2026.9.10/docs/bootstrap/setup.md#when-the-machine-already-has-these-files)

## 10. Migration Representation Matrix

| Legacy path/state                                                          | Safe setup representation                                                                         | Bootstrap or shape requirement                                                                                                                                                                                                                   |
| -------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Reviewed public regular file below `home/config`                           | Granular `mode = "track"`; plaintext history                                                      | None for byte restore. Explicit enrollment still needs a verified baseline. [Dotfiles: tracking](https://github.com/jdx/mise/blob/v2026.9.10/docs/dotfiles.md#files-directories-and-symlinks)                                                    |
| Same live path, different OS/profile contents                              | One tracking entry with unambiguous variants                                                      | No bootstrap for byte restore; use a default only when its content is truly a fallback. [Dotfiles: variants](https://github.com/jdx/mise/blob/v2026.9.10/docs/dotfiles.md#different-contents-on-different-machines)                              |
| Different native paths on Windows and Unix                                 | Separate OS-scoped tracking entries, or preferably one canonical source with destination variants | Canonical-source form requires the source and configuration to be tracked, then `mise bootstrap`/`mise dot apply`. [Dotfiles: destination variants](https://github.com/jdx/mise/blob/v2026.9.10/docs/dotfiles.md#platform-specific-destinations) |
| Approved sensitive, non-credential configuration                           | Separately tracked external source with `encrypt = true`; private identity out of history         | Public-origin confidentiality is not officially established. Template/copy output requires bootstrap and remains plaintext. [History: encryption](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md#encrypted-shared-files)            |
| Reusable credential, private key, token, cookie, session, credential store | Excluded; never enrolled                                                                          | Provision out of band. `encrypt = true` does not override this migration policy. [Migration map](https://github.com/bryan-hoang/dotfiles/issues/345)                                                                                             |
| Machine-only mise settings or origin/auth material                         | `config.local.toml` or another excluded local input                                               | `.local.toml` is never captured; provision it per machine. [History: exclusions](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md#explicit-tracking-and-exclusions)                                                                   |
| Symlink                                                                    | Track only when link text/topology is intentionally portable and tested                           | Prefer declarative symlink/copy variants for cross-platform links; Windows tracked-file-link restore is not promised. [Dotfiles: Windows](https://github.com/jdx/mise/blob/v2026.9.10/docs/dotfiles.md#windows)                                  |
| Nested repo, submodule, or worktree dependency                             | `[bootstrap.repos]` or an explicit external dependency                                            | A `gitlink` is only a commit pointer and rollback skips it. Clone/update before dotfile deployment. [Bootstrap repositories](https://github.com/jdx/mise/blob/v2026.9.10/docs/bootstrap/repos.md)                                                |
| Cache, log, database, generated session state                              | Excluded; for real configuration that merely changes often, `autosave = false`                    | Manual autosave is still shared once saved and is not local-only. [History: exclusions](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md#explicit-tracking-and-exclusions)                                                            |
| Required empty directory                                                   | `[bootstrap.directories]`                                                                         | Git history cannot represent empty directories. [Bootstrap files](https://github.com/jdx/mise/blob/v2026.9.10/docs/bootstrap/files.md)                                                                                                           |
| Absolute system path, owner/group, privileged mode                         | `[bootstrap.files]` / `[bootstrap.directories]`                                                   | History cannot enroll it; ordinary dotfiles do not `sudo`. [Bootstrap files](https://github.com/jdx/mise/blob/v2026.9.10/docs/bootstrap/files.md)                                                                                                |
| ACL, Windows file attributes/ADS, `xattrs`, timestamps, hard-link relation | Not expressible by `v1` history metadata                                                          | Use a platform bootstrap task/resource or another canonical form and test it; official support is not established. [Tagged manifest schema](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/manifest.rs#L12-L113)                 |
| Watcher and automatic two-way sync                                         | Track the global configuration containing the service and sync declarations                       | Bootstrap installs the user service; separately provision durable mise, Git credentials, and age identity. [Services](https://github.com/jdx/mise/blob/v2026.9.10/docs/bootstrap/services.md#user-services)                                      |

## 11. Exact Bootstrap Boundary

`mise bootstrap --adopt` recognizes the setup marker, fetches into the bare mise
history store, restores selected configuration and tracked files, records the
origin, then runs bootstrap. If an existing-file conflict remains, it stops
before the remaining bootstrap phases.
[Bootstrap: shared dotfile history](https://github.com/jdx/mise/blob/v2026.9.10/docs/bootstrap.md#shared-dotfile-history)
[Setup: another machine](https://github.com/jdx/mise/blob/v2026.9.10/docs/bootstrap/setup.md#when-the-machine-already-has-these-files)

After a normal sync, `mise dot pull` restores the complete tracked-file set but
does not clone repos, install tools/services, or render/apply managed dotfiles.
Run bootstrap when shared declarations or sources changed. For this to work on a
fresh machine, explicitly enroll all of these public inputs:
[History: sync immediately](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md#sync-immediately)

- The global mise configuration and relevant `conf.d` files.
- Every canonical dotfile/template source referenced by that configuration.
- Any public bootstrap file source needed by `[bootstrap.files]`.

Keep these outside enrollment and provision them separately:
[History: repository authentication and encryption](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md#repository-authentication)

- Git credentials usable by the background service.
- Every private age/recovery identity.
- Reusable application credentials and machine-local secret inputs.

For self-managing configuration or a `dotfiles.root` symlink, the real source
repository must exist before first apply; declare it in `[bootstrap.repos]` or
clone it out of band. Repos run before dotfiles in full bootstrap.
[Dotfiles: self-managing mise configuration](https://github.com/jdx/mise/blob/v2026.9.10/docs/dotfiles.md#self-managing-mise-config)
[Bootstrap repositories](https://github.com/jdx/mise/blob/v2026.9.10/docs/bootstrap/repos.md)

## 12. Behaviors Not Established by Official Sources

The following must not be assumed from mise `v2026.9.10`:

- That age-encrypted files are approved for a public setup origin. Official
  guidance says private repository and specifies metadata leakage, but gives no
  public-origin security guarantee.
  [Dotfiles: share with another machine](https://github.com/jdx/mise/blob/v2026.9.10/docs/dotfiles.md#share-with-another-machine)
  [History: encryption](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md#encrypted-shared-files)
- Portable Windows preservation of ACLs, ownership, read-only flags, alternate
  data streams, hard links, junctions/`reparse` points, or tracked file-symlink
  restoration. The history manifest has only Unix `0o777` permissions, and the
  documented Windows link fallback is for managed deployment, not history.
  [Tagged manifest schema](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/manifest.rs#L12-L113)
  [Dotfiles: Windows](https://github.com/jdx/mise/blob/v2026.9.10/docs/dotfiles.md#windows)
- Portable case-only filename/exclusion behavior between case-sensitive and
  case-insensitive filesystems, or a promise about history-glob case folding.
  [Tagged exclusion implementation](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/tracked.rs#L636-L675)
- Preservation of `uid`/`gid`, `setuid/setgid/sticky` bits, ACLs, `xattrs`,
  timestamps, sparse layout, or hard-link identity. No such fields exist in the
  format-1 manifest.
  [Tagged manifest schema](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/manifest.rs#L12-L113)
- Recreation, remote discovery, submodule initialization, dirty-state backup, or
  checkout movement from a `gitlink`. Official behavior establishes only a
  commit pointer and says to back up the repository separately.
  [History: what a checkpoint records](https://github.com/jdx/mise/blob/v2026.9.10/docs/history.md#what-a-checkpoint-records)
  [Setup: add more files](https://github.com/jdx/mise/blob/v2026.9.10/docs/bootstrap/setup.md#add-more-files)
- Pointer semantics when the Git repository itself is the exact enrollment root;
  the documentation does not distinguish it and the tagged descendant walker
  does. Use bootstrap rather than depending on this edge.
  [Tagged tracked walk](https://github.com/jdx/mise/blob/v2026.9.10/src/system/history/tracked.rs#L351-L600)

## Primary Sources
