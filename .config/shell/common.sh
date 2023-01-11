#!/usr/bin/env bash
#
# shellcheck disable=SC2154

# Load the shell dotfiles, and then some:
# * ~/.extra can be used for other settings you don't want to commit.
for file in "$XDG_CONFIG_HOME"/shell/{aliases,functions,extra}.sh; do
	# shellcheck disable=SC1090
	[[ -f "$file" ]] && . "$file"
done

if is_git_bash; then
	start_ssh_agent
fi

# region: Completions

does_program_exist thefuck && eval "$(thefuck --alias)"
does_program_exist dra \
	&& generate_completions zsh dra dra completion zsh \
	&& generate_completions bash dra dra completion bash
does_program_exist rustup \
	&& generate_completions zsh cargo rustup completions zsh cargo \
	&& generate_completions bash cargo rustup completions bash cargo \
	&& generate_completions zsh rustup rustup completions zsh rustup \
	&& generate_completions bash rustup rustup completions bash rustup
does_program_exist trash \
	&& generate_completions zsh trash trash completions zsh \
	&& generate_completions bash trash trash completions bash
does_program_exist deno \
	&& generate_completions zsh deno deno completions zsh \
	&& generate_completions bash deno deno completions bash
does_program_exist glab \
	&& generate_completions zsh glab glab completion --shell zsh \
	&& generate_completions bash glab glab completion --shell bash

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

# Set the environment variable per interactive session. Otherwise `tty` returns
# "not a tty" if ran from `.profile`.
# https://wiki.archlinux.org/title/GnuPG#Configure_pinentry_to_use_the_correct_TTY
export GPG_TTY=${TTY:-$(tty)}
if command -v gpg-connect-agent >/dev/null; then
	gpg-connect-agent updatestartuptty /bye &>/dev/null
fi

