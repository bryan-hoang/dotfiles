#!/usr/bin/env sh
# -*- coding: utf-8 -*-

git clone --bare git@github.com:bryan-hoang/dotfiles.git "${HOME}"/config

config() {
  /usr/bin/git --git-dir="${HOME}"/config/ --work-tree="${HOME}" "$@"
}

mkdir -p config-backup
if config checkout; then
  echo "Checked out config."
else
  echo "Backing up pre-existing dot files."
  config checkout 2>&1 | grep -E "\s+\." | awk '{print $1}' | xargs -I{} mv {} .config-backup/{}
fi
config checkout
config config status.showUntrackedFiles no
