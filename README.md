# dotfiles

[![standard-readme compliant](https://img.shields.io/badge/standard--readme-OK-green.svg?style=flat-square)](https://github.com/RichardLitt/standard-readme)

My dotfiles repo.

## Install

I used to use the `.local/bin/install-dotfiles` script. But nowadays, I
typically perform

> [!WARNING]
>
> `git switch -f` throws away the current copies of dotfiles on the machine.
> Back them up first if you don't want to lose them.

```console
cd ~
git init
git remote add origin git@github.com:bryan-hoang/dotfiles.git
git fetch origin
git switch -ft origin/main
```

## Usage

```console
# Install tools using mise
mise use -g node go python
# Install default packages
install_default_pkgs go
install_default_pkgs pnpm
# ...
```

## Maintainers

[@bryan-hoang](https://github.com/bryan-hoang)

## Contributing

PRs accepted.

Small note: If editing the README, please conform to the
[standard-readme](https://github.com/RichardLitt/standard-readme) specification.

## License

MIT © 2024 Bryan Hoang
