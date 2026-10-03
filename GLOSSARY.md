# Dotfiles

This context names the repository states and file classes used while managing
personal configuration across machines.

## Language

**Enrollment**: The reviewed set of live files that mise records, restores, and
synchronizes with their tracking policies. _Avoid_: Import, tracked tree

**Setup repository**: The Git history managed by mise for enrolled setup state,
separate from a live home-directory checkout. _Avoid_: Dotfiles checkout, home
repository

**Home-root checkout**: The legacy Git work tree whose root is the user's home
directory. _Avoid_: Setup repository, dotfiles store

**Legacy path**: An entry managed by the home-root checkout before conversion to
mise. _Avoid_: Enrolled path

**Audited tip**: The newest `main` commit whose history has passed the audit
gate and whose tree has a complete enrollment disposition. _Avoid_: Baseline,
legacy tip

**Audit gate**: The check that clears commits made after the audited tip. It
consists of a redacted secret scan of their new history and an enrollment
disposition for every path they add, change, or delete. _Avoid_: Re-audit, delta
scan

**Repository-only file**: A maintenance file kept in the setup repository but
not applied as live configuration. _Avoid_: Dotfile, enrolled file

**Required dependency**: An external repository, link, or service needed for an
enrolled file to work. _Avoid_: Package inventory, machine bootstrap

**Canonical source**: The one authoritative file for configuration that may
appear at multiple live paths. _Avoid_: Primary copy, original file

**Sanitized source**: A canonical source approved for public disclosure after
nonpublic identity, endpoint, machine, and credential data has been removed.
_Avoid_: Redacted file, scrubbed copy

**Local input**: Not enrolled machine- or profile-specific configuration used to
derive a managed destination. _Avoid_: Enrolled override, local secret

**Managed destination**: A live path derived from a canonical source for a
particular application or machine profile rather than enrolled independently.
_Avoid_: Duplicate, tracked copy

**Application deployment unit**: The managed destinations and required
dependencies for one optional application that are preflighted together before
any destination changes. _Avoid_: Capability profile, package group

**Protected clone**: The host-only bare copy of the origin where a setup commit
is staged, verified, and published without force. _Avoid_: Canonical exchange,
staging repo

**Supported-workflow block**: A local stop condition honored by managed
automation and documented run books but not enforced against direct invocation
of the underlying tool. _Avoid_: Absolute lock, security boundary
