#!/usr/bin/env bash

# Load the shell dotfiles, and then some:
# * ~/.extra can be used for other settings you don't want to commit.
for file in "$XDG_CONFIG_HOME"/shell/{aliases,functions,extra}.sh; do
	# shellcheck disable=SC1090
	[[ -f "$file" ]] && . "$file"
done

# If on a machine that doesn't have keychain, don't use it
if is_git_bash || ! does_program_exist keychain; then
	start_ssh_agent
	gpg-connect-agent reloadagent /bye &>/dev/null
else
	# If we're in a shell without a display manager, don't ask for a
	# password for the ssh key's to be added (unless we're in WSL, which is
	# fine).
	if is_login_shell && ! is_interactive_shell && ! is_wsl && ! is_ssh_session; then
		KEYCHAIN_NOASK='--noask'
	fi

	if ! start_ssh_keychain "$KEYCHAIN_NOASK"; then
		keychain -q -k all
		start_ssh_keychain "$KEYCHAIN_NOASK"
	fi
fi

# region: Completions

does_program_exist thefuck && eval "$(thefuck --alias)"
does_program_exist dra \
	&& generate_completions zsh dra dra completion zsh \
	&& generate_completions bash dra dra completion bash
does_program_exist rustup \
	&& generate_completions zsh cargo rustup completions zsh cargo \
	&& generate_completions bash cargo rustup completions bash cargo
does_program_exist trash \
	&& generate_completions zsh trash trash completions zsh \
	&& generate_completions bash trash trash completions bash

# endregion

# https://wiki.archlinux.org/title/XDG_Base_Directory
mkdir -p "$XDG_DATA_HOME"/tig

# Make direnv silent by default. Doesn't work in `.exports` for some reason.
export DIRENV_LOG_FORMAT=""

# If set, bash/zsh does not overwrite an existing file with the >, >&, and <>
# redirection operators. This may be overridden when creating output files by
# using the redirection operator >| instead of >.
set -o noclobber

# Set tabs in the terminal to differ from the default of 8.
tabs 2
