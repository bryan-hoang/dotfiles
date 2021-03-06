#!/usr/bin/env bash
# -*- coding: utf-8 -*-

cd "$(dirname "${BASH_SOURCE[0]}")" || exit

git pull origin main

function doIt() {
  rsync --exclude ".git/" \
    --exclude ".DS_Store" \
    --exclude ".osx" \
    --exclude "bootstrap.sh" \
    --exclude "README.md" \
    --exclude "LICENSE-MIT.txt" \
    -avh --no-perms . ~
  # shellcheck disable=SC1090
  source ~/.bash_profile
}

if [ "$1" == "--force" ] || [ "$1" == "-f" ]; then
  doIt
else
  read -pr "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1
  echo ""
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    doIt
  fi
fi
unset doIt
