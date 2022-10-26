#!/usr/bin/env bash

if command -v tmux &>/dev/null \
	&& [[ -n "$PS1" ]] \
	&& [[ ! "$TERM" =~ screen ]] \
	&& [[ ! "$TERM" =~ tmux ]] \
	&& [[ -n "$SSH_CONNECTION" ]] \
	&& [[ -z "$TMUX" ]]; then
	exec tmux new-session -A -s ssh
fi

# shellcheck disable=SC1091
. "$XDG_CONFIG_HOME"/shell/common

# Setting shell options

# Configure Ctril-w to delete words like ZSH.
if is_interactive_shell; then
	stty werase undef
	bind '\C-w:unix-filename-rubout'
fi

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
if command -v brew &>/dev/null && [ -r "$(brew --prefix)/etc/profile.d/bash_completion.sh" ]; then
	# Ensure existing Homebrew v1 completions continue to work
	BASH_COMPLETION_COMPAT_DIR="$(brew --prefix)/etc/bash_completion.d"
	export BASH_COMPLETION_COMPAT_DIR
	# shellcheck disable=SC1091
	. "$(brew --prefix)/etc/profile.d/bash_completion.sh"
elif [ -f /etc/bash_completion ]; then
	# shellcheck disable=SC1091
	. /etc/bash_completion
fi

# Enable tab completion for `g` by marking it as an alias for `git`
if type _git &>/dev/null; then
	complete -o default -o nospace -F _git g
fi

# Add tab completion for SSH hostnames based on ~/.ssh/config, ignoring wildcards
[ -e "${HOME}/.ssh/config" ] \
	&& complete -o "default" -o "nospace" -W "$(grep "^Host" ~/.ssh/config \
		| grep -v "[?*]" \
		| cut -d " " -f2- \
		| tr ' ' '\n')" scp sftp ssh

# Add tab completion for `defaults read|write NSGlobalDomain`
# You could just use `-g` instead, but I like being explicit
complete -W "NSGlobalDomain" defaults

# Add `killall` tab completion for common apps
complete -o "nospace" -W "Contacts Calendar Dock Finder Mail Safari iTunes SystemUIServer Terminal Twitter" killall

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

# shellcheck disable=SC1091
[[ -s "$OSH"/oh-my-bash.sh ]] && . "$OSH"/oh-my-bash.sh

does_function_exist && pyvenv_auto_activate_enable

[[ -s "$ASDF_DIR"/asdf.sh ]] && . "$ASDF_DIR"/asdf.sh

# endregion

# Remove timestamps from history file to let zsh history parse it.
unset HISTTIMEFORMAT

# shellcheck disable=SC1091
[[ -s "$ASDF_DIR"/completions/asdf.bash ]] \
	&& . "$ASDF_DIR"/completions/asdf.bash

# shellcheck disable=SC1091
[[ -s "$ASDF_DIR"/plugins/java/set-java-home.bash ]] \
	&& . "$ASDF_DIR"/plugins/java/set-java-home.bash

# Completions
# git
# shellcheck disable=SC1091
[[ -f /usr/share/bash-completion/completions/git ]] \
	&& . /usr/share/bash-completion/completions/git
# dot
__git_complete dot __git_main
# deno
# shellcheck disable=1090
does_program_exist deno && . <(deno completions bash)

# shellcheck disable=1090
does_program_exist vr && . <(vr completions bash)

# does_program_exist npm && . <(npm completion bash)

# tabtab source for packages
# uninstall by removing these lines
# shellcheck disable=SC1090
[ -f ~/.config/tabtab/bash/pnpm.bash ] && . ~/.config/tabtab/bash/pnpm.bash

does_program_exist mcfly && eval "$(mcfly init bash)"
is_interactive_shell && does_program_exist navi && eval "$(navi widget bash)"
does_program_exist zoxide && eval "$(zoxide init bash)"
does_program_exist gh && eval "$(gh completion -s bash)"
does_program_exist starship && eval "$(starship init bash)"
does_program_exist broot && eval "$(broot --print-shell-function bash)"

# shellcheck disable=SC1091
if [[ -f "${XDG_CONFIG_HOME:-${HOME}/.config}/asdf-direnv/bashrc" ]]; then
	# shellcheck disable=SC2250
	source "${XDG_CONFIG_HOME:-$HOME/.config}/asdf-direnv/bashrc"
fi
