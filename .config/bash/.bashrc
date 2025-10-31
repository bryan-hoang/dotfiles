#!/usr/bin/env bash
#
# shellcheck disable=SC1091,SC2154

# From `/etc/skel/.bashrc`.
# If not running interactively, don't do anything.
case $- in
	*i*) ;;
	*) return ;;
esac
if [[ -z $PS1 ]]; then
	return
fi

[[ -f "$XDG_DATA_HOME"/blesh/ble.sh ]] \
	&& . "$XDG_DATA_HOME"/blesh/ble.sh --noattach

# Setting shell options

# If set, bash attempts to save all lines of a multiple-line command in the same
# history entry. This allows easy re-editing of multi-line commands.  This
# option is enabled by default, but only has an effect if command history is
# enabled, as described above under HISTORY.
shopt -s cmdhist

# Case-insensitive globbing (used in pathname expansion)
shopt -s nocaseglob

# If set, the history list is appended to the file named by the value of the
# HISTFILE variable when the shell exits, rather than overwriting the file.
shopt -s histappend

# Autocorrect typos in path names when using `cd`
shopt -s cdspell

# If set, and the cmdhist option is enabled, multi-line commands are saved to
# the history with embedded newlines rather than using semicolon separators
# where possible.
shopt -s lithist

# The last element of a pipeline may be run by the shell process.
shopt -s lastpipe

# Allows patterns which match no files (see Pathname Expansion above) to expand
# to a null string, rather than themselves.
shopt -s nullglob

# The pattern ** used in a pathname expansion context will match all files and
# zero or more directories and subdirectories. If the pattern is followed by
# a /, only directories and subdirectories match.
shopt -s globstar

# Enable the extended pattern matching features described in "Pattern Matching".
shopt -s extglob

# export SHELDON_CONFIG_DIR="$XDG_CONFIG_HOME"/sheldon/bash
# command -v sheldon >/dev/null && eval "$(sheldon source)"

# Remove timestamps from history file to let zsh history parse it.
unset HISTTIMEFORMAT

# Bind Alt-s (see `help bind`)
bind -x '"\es":"ssnz"'

# Add tab completion for many Bash commands
if [[ -z ${BASH_COMPLETION_VERSINFO:-} ]]; then
	if [[ -f /usr/local/share/bash-completion/bash_completion ]]; then
		# Locally installed completions. e.g., Git Bash on Windows, newer version
		# compared to distribution's version.
		. /usr/local/share/bash-completion/bash_completion
	elif [[ -f /usr/share/bash-completion/bash_completion ]]; then
		. /usr/share/bash-completion/bash_completion
	fi
fi

# Completions
# git
# shellcheck disable=SC1091
[[ -f /usr/share/bash-completion/completions/git ]] \
	&& . /usr/share/bash-completion/completions/git
# dot
__git_complete dot __git_main

. "$XDG_CONFIG_HOME"/shell/common.sh

if is_git_bash; then
	start_ssh_agent
fi

[[ -z ${BLE_VERSION-} ]] || ble-attach
