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

# shellcheck disable=SC1091
. "${HOME}"/.config/shell/exports
# shellcheck disable=SC1091
. "${HOME}"/.config/shell/path
