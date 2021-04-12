#!/usr/bin/env bash
# -*- coding: utf-8 -*-

if ! grep -q "^github.com " ~/.ssh/known_hosts; then
  touch ~/.ssh/known_hosts
  ssh-keyscan github.com >>~/.ssh/known_hosts 2>/dev/null
fi

if ! git clone --bare git@github.com:bryan-hoang/dotfiles.git "${HOME}"/config; then
  echo "Could not clone repository"
  exit 1
fi

function config() {
  git --git-dir="${HOME}"/config/ --work-tree="${HOME}" "$@"
}

mkdir -p config-backup
if config checkout; then
  echo "Checked out config."
else
  echo "Backing up pre-existing dot files."
  config checkout 2>&1 | grep -E "\s+\." | awk '{print $1}' | xargs -I{} mv {} config-backup/{}
fi
config checkout
config submodule update --init --recursive
config config status.showUntrackedFiles no

# Install nvm
wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh |
  bash >/dev/null
echo 'Installed nvm successfully!'

# Install starship
mkdir -p ~/bin
curl -fsSL https://starship.rs/install.sh |
  BIN_DIR=~/bin bash -s -- -y >/dev/null
echo 'Installed starship successfully!'
