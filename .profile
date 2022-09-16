#!/usr/bin/env bash
# -*- coding: utf-8 -*-

# "${HOME}"/.profile: executed by the command interpreter for login shells.
#
# See /usr/share/doc/bash/examples/startup-files for examples.
#
# The files are located in the bash-doc package.

if command -v tmux &>/dev/null \
  && [[ -n "${PS1}" ]] \
  && [[ ! "${TERM}" =~ screen ]] \
  && [[ ! "${TERM}" =~ tmux ]] \
  && [[ -n "${SSH_CONNECTION}" ]] \
  && [[ -z "${TMUX}" ]]; then
  exec tmux new-session -A -s ssh
fi

export TEXDIR=/usr/local/texlive/2022
export VOLTA_HOME="${HOME}"/.volta
export PNPM_HOME="${HOME}"/.local/share/pnpm
export XDG_BIN_HOME="${HOME}"/.local/bin
# Bun
export BUN_INSTALL="${HOME}"/.bun

# shellcheck source=.path
. "${HOME}"/.path
# shellcheck source=.exports
. "${HOME}"/.exports
