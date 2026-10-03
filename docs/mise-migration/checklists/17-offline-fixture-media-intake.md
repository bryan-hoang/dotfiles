# Offline Fixture Media Intake

Status: superseded on 2026-10-02. The Linux fixture is now a Fedora 44 WSL
instance, and the DVD, closure, and Hyper-V sections below are historical. See
the answer in
[Provide approved offline Windows and Linux fixtures](https://github.com/bryan-hoang/dotfiles/issues/362).\
Decision
date: 2026-09-20

## Fixed Fixture Choices

- Windows acceptance uses a fresh Windows Sandbox instance on the verified
  `25H2`, en-US, x64 host. Sandbox networking must be disabled.
- Sandbox receives only the verified Git and mise media through a read-only
  mapped folder. No Windows ISO, product key, or activation contact is used.
- Fedora Linux 44 Server, final `GA` DVD, `x86_64`, using Minimal Install.
- Fedora uses a fresh Hyper-V VM with no external network access.
- Git and stock mise `2026.9.10` come only from verified offline inputs.
- The Fedora fixture-ready checkpoint is created while powered off, after OS
  installation and Git/mise verification, but before any lab disk, repository,
  credential, setup history, or prototype state is introduced.
- Sandbox has no checkpoint or `shared-VHD` boundary. Each run starts fresh and
  terminates completely; ticket 18 owns the later exchange design.

## Automatic Acquisition Policy

The human authorized anonymous automatic downloads from exact first-party HTTPS
sources. Network subprocesses use an empty environment plus only fixed operating
system paths and temporary-directory settings. They send no credentials,
cookies, authentication headers, proxy values, telemetry identifiers, or
provider tokens. Redirects are followed one hop at a time and must stay on this
allowlist:

- Fedora: `fedoraproject.org`, `dl.fedoraproject.org`, and
  `mirrors.fedoraproject.org`.
- Git for Windows and mise releases: `github.com` and
  `release-assets.githubusercontent.com`.
- Mise key and documentation evidence: `raw.githubusercontent.com` and
  `mise.jdx.dev`.

No provider API or GitHub API endpoint is allowed. Do not retry Microsoft's
Download Connector or use the Media Creation Tool. Dynamic signed URL queries
must never be persisted or copied into planning artifacts.

## Windows Sandbox Media Boundary

- [x] Remove the Windows ISO and activation requirements.
- [x] Preserve the verified signed Git for Windows installer.
- [x] Preserve the verified stock Windows mise binary.
- [ ] Enable Windows Sandbox through a separately approved administrative step.
- [ ] Configure a fresh Sandbox launch with networking disabled and the verified
      tool-media folder mapped read-only.

Sandbox setup, launch, and exchange behavior are provisioning work, not media
acquisition. Sandbox cannot satisfy a powered-off checkpoint or `shared-VHD`
assumption; every acceptance run must begin from a fresh instance.

## Git for Windows

- [x] Acquire the official signed `Git-2.55.0.3-64-bit.exe` installer from the
      [Git for Windows `v2.55.0.windows.3` release](https://github.com/git-for-windows/git/releases/tag/v2.55.0.windows.3).
- [x] Preserve the installer filename, bytes, and embedded `Authenticode`
      signature.
- [x] Save the first-party release record and its published asset digest when
      one is present.
- [x] Record the acquisition date, release tag, filename, and byte size.

Verified result: version `2.55.0.windows.3`, 65,388,144 bytes, SHA-256
`af12577d0fdff74243a5988197aa49b957d5044edc17004f6ddf0768996f1dca`. The hash
matches GitHub's immutable release record. `Authenticode` is valid; the signer
certificate thumbprint is `3E9627155B7A6F29856321EE56D7FC25CF808407`, with a
timestamp signature.

## Fedora Installation and Git Media

- [x] Acquire the Fedora Linux 44 Server final `GA` DVD for `x86_64` from the
      [Fedora Server download page](https://fedoraproject.org/server/download).
- [x] Preserve the exact published `GA` compose suffix in
      `Fedora-Server-dvd-x86_64-44-<published-compose>.iso`.
- [x] Acquire the matching clear-signed
      `Fedora-Server-44-<published-compose>-x86_64-CHECKSUM` file.
- [x] Acquire the Fedora 44 public signing key `RPM-GPG-KEY-fedora-44-primary`
      and an official record of its complete fingerprint from
      [Fedora's security page](https://fedoraproject.org/security).
- [x] Save the official Fedora 44 final-release or compose record identifying
      the Server edition, DVD image, architecture, and exact `GA` compose.
- [x] Record each source page, acquisition date, filename, and byte size.

The DVD is the OS source and supplies every exact closure `NEVRA` it contains.
Packages absent from the DVD may come only from pinned Fedora 44 `GA` Everything
metadata. Updates, latest repositories, Everything `netinst`, Workstation Live,
Cloud, `CoreOS`, Beta, RC, Rawhide, and third-party RPMs are forbidden.

Verified media result: final compose `1.7`, 3,913,023,488 bytes, SHA-256
`85837793bfa36db6bc709b4cecd2ec116951b87d9c53c3d95eb2fac8dcf7cf1f`. The
clear-signed CHECKSUM validates with Fedora 44 fingerprint
`36F612DCF27F7D1A48A835E4DBFCF71C6D9F90A6`; `.treeinfo` identifies Fedora 44
Server `x86_64`.

The verified hard dependency closure for Fedora Server Minimal Install contains
82 `x86-64/noarch` packages. Eighty-one exact `NEVRAs` are present on the DVD.
The only retained external package is `git-core-2.53.0-1.fc44.x86_64.rpm`,
SHA-256 `b526494b519d4a123c7a2a860070f17dc7d9005c657596990e03ec29547e7e01`, from
pinned Fedora 44 `GA` Everything metadata. No updates repository was used.

Every package hash, header signature, header digest, and payload digest
validates with Fedora fingerprint `36F612DCF27F7D1A48A835E4DBFCF71C6D9F90A6`. An
`empty-installroot` RPM transaction test passed, which is stricter than the
selected Minimal Install baseline. The 82-package lock SHA-256 is
`0df5c8a4f21bcf38f6f976651e230bc6863e5efd6fa06951d1611960f7e10842`.

## Linux Mise

- [x] Acquire the official raw `mise-v2026.9.10-linux-x64` release artifact from
      the
      [mise `v2026.9.10` release](https://github.com/jdx/mise/releases/tag/v2026.9.10).
- [x] Acquire the matching `SHASUMS256.txt` and `SHASUMS256.txt.minisig` release
      assets.
- [x] Acquire the official tagged mise `Minisign` public key and record its key
      ID and SHA-256.
- [x] Save the first-party release record identifying tag `v2026.9.10`, the
      Linux x64 artifact, and its published asset digest when one is present.
- [x] Record the acquisition date, filenames, and byte sizes.

Verified result: 132,719,984-byte `ELF64` x86-64 artifact, SHA-256
`f917e52216924ef0a8b4eca3f7004dfcff3b94665716ac5685fd53006a491eee`. The
immutable release digest and signed manifest agree. The tagged `Minisign` key
has ID `64113EDF160FDEC2` and SHA-256
`647782ec4f81cc3b9be690bd266e30191acd6711cf0ff8163b7d1e46cd8f96a1`; both the
manifest and trusted-comment signatures validate. The signature time is
`2026-09-16T17:17:13Z`.

## Already Present

The reviewed stock Windows mise binary needs no new download:

- Version: `2026.9.10 windows-x64 (2026-09-16)`
- SHA-256: `98f2b199c6b283547b66c8ab6d721aab977ff5e084f0e034b71596c7d2aba2e1`
- `Authenticode` status: unsigned; acceptance depends on the previously
  source-verified stock digest above.

An installed Git tree is not approved installation media and cannot replace the
signed Git for Windows installer.

## Safe Acquisition and Intake

- [x] Acquire every required item directly from the listed first-party source.
- [x] Preserve original filenames and bytes. Do not execute, install, modify, or
      repackage acquired artifacts. Clean every temporary read-only extraction
      used for verification.
- [x] Keep only the listed artifacts and provenance records in one local,
      non-cloud-synced intake directory.
- [x] Exclude credentials, product keys, account exports, browser state,
      provider metadata, private URLs, VM exports, and unrelated files.
- [x] Do not record the intake directory in this repository. Provide it
      privately when acquisition is complete.

## Offline Verification Gates

No artifact may be mounted, executed, installed, or used to provision a VM until
all applicable pre-use gates pass offline.

- [x] The intake contains every required artifact and provenance record, with no
      unexpected file class.
- [x] Locally computed SHA-256 values and byte sizes are recorded before any
      artifact is opened or mounted.
- [x] Windows acceptance requires no ISO; the mapped Git and mise media are
      independently verified and ready for a read-only Sandbox mapping.
- [x] The Git for Windows signature chains to a trusted publisher, the installer
      identifies `2.55.0.windows.3` x64, and the SHA-256 of the installer is
      recorded.
- [x] The Fedora CHECKSUM signature validates with the Fedora 44 key whose full
      fingerprint matches the independent official fingerprint record.
- [x] The Fedora ISO digest matches the signed CHECKSUM, and its identity is
      Fedora Linux 44 Server final `GA` DVD, `x86_64`, at the recorded compose.
- [x] Offline repository inspection proves that `git-core.x86_64` and its full
      dependency closure are present. Every selected RPM signature validates
      with an approved Fedora key, and the exact package version is recorded.
- [x] The mise `Minisign` signature on `SHASUMS256.txt` validates with the
      approved mise key, the Linux artifact digest matches the signed manifest,
      and the artifact identifies Linux x86-64 and version `2026.9.10`.
- [x] The existing Windows mise binary still matches its approved SHA-256 and
      version before transfer into the fixture.
- [x] Every required file, identity, signature, digest, and Fedora package
      closure gate passed. Any future mismatch stops intake; no network fallback
      is allowed.

## Resume Condition

Acquisition is complete. The next stage requires explicit provisioning actions:

- Enable Windows Sandbox, then define a fresh, network-disabled launch with the
  verified Git/mise media mapped read-only. Do not launch it in this task.
- Create the Fedora VM, install Fedora Server 44 Minimal Install offline,
  install Git from the verified DVD-plus-lock closure, install stock mise, and
  create the approved powered-off fixture checkpoint.
- Leave the Sandbox-to-Fedora exchange mechanism undecided for ticket 18.

Do not write the private intake location into planning artifacts.
