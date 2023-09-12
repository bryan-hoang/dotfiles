#!/usr/bin/env bash
#
# shellcheck disable=SC1091,SC2154

# From `/etc/skel/.bashrc`.
# If not running interactively, don't do anything.
case $- in
	*i*) ;;
	*) return ;;
esac

# Setting shell options

# Configure Ctril-w to delete words like ZSH.
stty werase undef
bind '\C-w:backward-kill-word'

# Bind Alt-s
bind '"\es":"multiplex-session\n"'

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

# Add tab completion for many Bash commands
if command -v brew &>/dev/null && [[ -r "$(brew --prefix)/etc/profile.d/bash_completion.sh" ]]; then
	# Ensure existing Homebrew v1 completions continue to work
	BASH_COMPLETION_COMPAT_DIR="$(brew --prefix)/etc/bash_completion.d"
	export BASH_COMPLETION_COMPAT_DIR
	# shellcheck disable=SC1091
	. "$(brew --prefix)/etc/profile.d/bash_completion.sh"
elif [[ -f /etc/bash_completion ]]; then
	# shellcheck disable=SC1091
	. /etc/bash_completion
elif [[ -s /usr/local/share/bash-completion/bash_completion ]]; then
	# Locally install completions. e.g., Git Bash on Windows.
	. /usr/local/share/bash-completion/bash_completion
fi

# region ohmybash

# Which completions would you like to load? (completions can be found in
# ~/.oh-my-bash/completions/*) Custom completions may be added to
# ~/.oh-my-bash/custom/completions/ Example format: completions=(ssh git
# bundler gem pip pip3) Add wisely, as too many completions slow down shell
# startup.
# shellcheck disable=SC2034
completions=(
	git
	composer
	ssh
)

# Which aliases would you like to load? (aliases can be found in
# ~/.oh-my-bash/aliases/*) Custom aliases may be added to
# ~/.oh-my-bash/custom/aliases/ Example format: aliases=(vagrant composer
# git-avh) Add wisely, as too many aliases slow down shell startup.
# shellcheck disable=SC2034
aliases=(
	general
)

# Which plugins would you like to load? (plugins can be found in
# ~/.oh-my-bash/plugins/*) Custom plugins may be added to
# ~/.oh-my-bash/custom/plugins/ Example format: plugins=(rails git textmate
# ruby lighthouse) Add wisely, as too many plugins slow down shell startup.
# shellcheck disable=SC2034
plugins=(
	git
	bashmarks
	# Custom
	pyvenv-activate
)

export SHELDON_CONFIG_DIR="$XDG_CONFIG_HOME"/sheldon/bash

# command -v sheldon >/dev/null && eval "$(sheldon source)"

# Avoid `oh-my-bash` from overwriting `LS_COLORS` using `dircolors`.
ORIGINAL_LS_COLORS="$LS_COLORS"

# shellcheck disable=SC1091
[[ -s "$OSH"/oh-my-bash.sh ]] && . "$OSH"/oh-my-bash.sh

export LS_COLORS="$ORIGINAL_LS_COLORS"

. "$XDG_CONFIG_HOME"/shell/common.sh

does_function_exist && pyvenv_auto_activate_enable

# endregion

# Remove timestamps from history file to let zsh history parse it.
unset HISTTIMEFORMAT

# # shellcheck disable=SC1091
# [[ -s "$ASDF_DIR"/completions/asdf.bash ]] \
# 	&& . "$ASDF_DIR"/completions/asdf.bash

# # shellcheck disable=SC1091
# [[ -s "$ASDF_DIR"/plugins/java/set-java-home.bash ]] \
# 	&& . "$ASDF_DIR"/plugins/java/set-java-home.bash

# Completions
# git
# shellcheck disable=SC1091
[[ -f /usr/share/bash-completion/completions/git ]] \
	&& . /usr/share/bash-completion/completions/git
# dot
__git_complete dot __git_main

[[ -f $XDG_CONFIG_HOME/tabtab/bash/pnpm.bash ]] \
	&& . "$XDG_CONFIG_HOME"/tabtab/bash/pnpm.bash

[[ -f "$GHQ_ROOT"/github.com/rcaloras/bash-preexec/bash-preexec.sh ]] \
	&& . "$GHQ_ROOT"/github.com/rcaloras/bash-preexec/bash-preexec.sh

is_interactive_shell && does_command_exist navi && eval "$(navi widget bash)"
does_command_exist zoxide && eval "$(zoxide init bash)"
does_command_exist gh && eval "$(gh completion -s bash)"
does_command_exist starship && eval "$(starship init bash)"
does_command_exist broot && eval "$(broot --print-shell-function bash)"
does_command_exist direnv && eval "$(direnv hook bash)"
# Requires `bash-preexec`.
does_command_exist atuin && eval "$(atuin init bash)"

if is_git_bash; then
	start_ssh_agent
fi
