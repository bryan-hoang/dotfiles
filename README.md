# Dotfiles

[![standard-readme compliant](https://img.shields.io/badge/standard--readme-OK-green.svg?style=flat-square)](https://github.com/RichardLitt/standard-readme)

My dotfiles, kept as a [mise](https://mise.jdx.dev) setup repository.

The mise history store owns the tracked files. The `home/` and `config/` trees
hold the files shared by every machine; `home@windows/`, `config@windows/`,
`home@linux/`, and `config@linux/` hold the per-OS files. `.mise-history/` holds
the manifest. Every other path at the repository root is a legacy record from
the old home-directory checkout: it is never restored and never a source.

## Install

> [!WARNING]
>
> Adoption pauses if a live file differs from the repository. Back up each
> differing file, move it aside, adopt, then copy your reviewed bytes back and
> save them.

```console
mise bootstrap --adopt https://github.com/bryan-hoang/dotfiles --yes
```

This writes the tracked files for the current OS into `HOME`, clones the
bootstrap repositories under `~/src/github.com`, and connects local history to
this repository. `~/.config/mise/conf.d/dotfiles.toml` declares what is tracked.

## Usage

```console
# Show tracked files and sharing state
mise dot status
# Save a checkpoint of tracked files
mise dot save --description 'Describe the change'
# Publish local checkpoints and pull remote ones
mise dot sync
```

Machine-only settings go in excluded `*.local.toml` files, never in tracked
files.

## Maintainers

[Bryan Hoang](https://github.com/bryan-hoang)

## Contributing

PRs accepted.

Small note: If editing the README, please conform to the
[standard-readme](https://github.com/RichardLitt/standard-readme) specification.

## License

MIT © 2024 Bryan Hoang
