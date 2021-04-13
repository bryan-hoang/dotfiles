#!/usr/bin/env bash
# -*- coding: utf-8 -*-

function clone_repo() {
  readonly REPOSITORY_HOST=github.com
  readonly REPOSITORY=git@${REPOSITORY_HOST}:bryan-hoang/dotfiles.git

  if ! grep -q "^${REPOSITORY_HOST} " ~/.ssh/known_hosts; then
    touch ~/.ssh/known_hosts
    ssh-keyscan ${REPOSITORY_HOST} >>~/.ssh/known_hosts 2>/dev/null
  fi

  if ! git clone --bare $REPOSITORY "${HOME}"/config; then
    echo "Could not clone ${REPOSITORY}"
    exit $?
  fi

  function config() {
    git --git-dir="${HOME}"/config/ --work-tree="${HOME}" "$@"
  }

  mkdir -p config-backup

  if config checkout; then
    echo "Checked out config."
  else
    echo "Backing up pre-existing dot files."
    config checkout 2>&1 |
      grep -E "\s+\." |
      awk '{print $1}' |
      xargs -I{} mv {} config-backup/{}
  fi

  config checkout
  config submodule update --init --recursive
  config config status.showUntrackedFiles no
}

function install_nvm() {
  echo "Installing nvm..."
  wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh |
    bash >/dev/null
  echo "Installed nvm successfully!"
}

function install_starship() {
  echo "Installing starship..."
  mkdir -p ~/bin
  curl -fsSL https://starship.rs/install.sh |
    BIN_DIR=~/bin bash -s -- -y >/dev/null
  echo "Installed starship successfully!"
}

function does_function_exist() {
  declare -f -F "$1" >/dev/null
  return $?
}

if [ ! -d "$HOME"/config ]; then
  clone_repo
fi

# shellcheck source=./.bashrc
source ~/.bashrc

if ! does_function_exist nvm; then
  install_nvm
fi

if ! command -v starship &>/dev/null; then
  install_starship
fi

echo "Finished installing Bryan's dotfiles setup!"
