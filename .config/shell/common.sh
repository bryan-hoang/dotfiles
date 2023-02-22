#!/usr/bin/env bash
#
# shellcheck disable=SC2154

# Load the shell dotfiles, and then some:
# * ~/.extra can be used for other settings you don't want to commit.
for file in "$XDG_CONFIG_HOME"/shell/{aliases,functions,extra}.sh; do
	# shellcheck disable=SC1090
	[[ -f $file ]] && . "$file"
done

# Source: https://unix.stackexchange.com/a/37535
SHELL_BASENAME=$(basename "$(readlink -f /proc/$$/exe)")
readonly SHELL_BASENAME

# Temporarily add rtx bin-paths to $PATH.
OLD_PATH=$PATH

# https://github.com/jdxcode/rtx#rtx-inside-of-direnv-use-rtx-in-envrc
[[ ! -s ~/.config/direnv/lib/use_rtx.sh ]] \
	&& rtx direnv activate >~/.config/direnv/lib/use_rtx.sh
does_program_exist direnv && eval "$(direnv hook "$SHELL_BASENAME")"
does_program_exist rtx && eval "$(rtx activate "$SHELL_BASENAME")" \
	&& PATH=$(rtx bin-paths | paste -sd :):$PATH

if [[ -n $SSH_CONNECTION ]] && does_program_exist rust-motd; then
	rust-motd
fi

# region: Completions

does_program_exist dra \
	&& generate_completions "$SHELL_BASENAME" dra dra completion "$SHELL_BASENAME"
does_program_exist rustup \
	&& generate_completions "$SHELL_BASENAME" cargo rustup completions "$SHELL_BASENAME" cargo \
	&& generate_completions "$SHELL_BASENAME" rustup rustup completions "$SHELL_BASENAME" rustup
does_program_exist trash \
	&& generate_completions "$SHELL_BASENAME" trash trash completions "$SHELL_BASENAME"
does_program_exist deno \
	&& generate_completions "$SHELL_BASENAME" deno deno completions "$SHELL_BASENAME"
does_program_exist glab \
	&& generate_completions "$SHELL_BASENAME" glab glab completion --shell "$SHELL_BASENAME"
does_program_exist just \
	&& generate_completions "$SHELL_BASENAME" just just --completions "$SHELL_BASENAME"
does_program_exist starship \
	&& generate_completions "$SHELL_BASENAME" starship starship completions "$SHELL_BASENAME"

# Doesn't support bash.
does_program_exist bw \
	&& generate_completions zsh bw bw completion --shell zsh | sed -e 's/\x1b\[[0-9;]*m//g'
does_program_exist register-python-argcomplete pipx \
	&& eval "$(register-python-argcomplete pipx)"

# endregion

does_program_exist thefuck && eval "$(thefuck --alias)"

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

PATH=$OLD_PATH
unset OLD_PATH
