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

# Temporarily add rtx bin-paths to $PATH.
OLD_PATH=$PATH

# https://github.com/jdxcode/rtx#rtx-inside-of-direnv-use-rtx-in-envrc
[[ ! -s ~/.config/direnv/lib/use_rtx.sh ]] \
	&& does_command_exist direnv \
	&& does_command_exist rtx \
	&& rtx direnv activate >~/.config/direnv/lib/use_rtx.sh
does_command_exist direnv && eval "$(direnv hook "$SHELL_BASENAME")"
does_command_exist rtx && eval "$(rtx activate "$SHELL_BASENAME")" \
	&& PATH=$(rtx bin-paths | paste -sd :):$PATH

if [[ -n $SSH_CONNECTION ]] && [[ -z $TMUX ]]; then
	does_command_exist rust-motd && rust-motd
	does_command_exist macchina && macchina
fi

# region: Completions

does_command_exist dra \
	&& generate_completions dra dra completion "$SHELL_BASENAME"
does_command_exist rustup \
	&& generate_completions cargo rustup completions "$SHELL_BASENAME" cargo \
	&& generate_completions rustup rustup completions "$SHELL_BASENAME" rustup
does_command_exist trash \
	&& generate_completions trash trash completions "$SHELL_BASENAME"
does_command_exist deno \
	&& generate_completions deno deno completions "$SHELL_BASENAME"
does_command_exist glab \
	&& generate_completions glab glab completion --shell "$SHELL_BASENAME"
does_command_exist just \
	&& generate_completions just just --completions "$SHELL_BASENAME"
does_command_exist starship \
	&& generate_completions starship starship completions "$SHELL_BASENAME"
does_command_exist ruff \
	&& generate_completions ruff ruff generate-shell-completion "$SHELL_BASENAME"
does_command_exist poetry \
	&& generate_completions poetry poetry completions "$SHELL_BASENAME"
does_command_exist gh \
	&& generate_completions gh gh completion -s "$SHELL_BASENAME"
does_command_exist cht.sh \
	&& generate_completions cht.sh curl https://cheat.sh/:bash_completion \
	&& generate_completions cht.sh curl https://cheat.sh/:zsh
does_command_exist cog \
	&& generate_completions cog cog generate-completions "$SHELL_BASENAME"
does_command_exist rtx \
	&& generate_completions rtx rtx complete --shell "$SHELL_BASENAME"

# Doesn't support bash.
does_command_exist bw \
	&& generate_completions bw bw completion --shell zsh | sed -e 's/\x1b\[[0-9;]*m//g'
does_command_exist pipenv \
	&& generate_completions pipenv env _PIPENV_COMPLETE=zsh_source pipenv
does_command_exist kubectl \
	&& generate_completions kubectl kubectl completion zsh
does_command_exist register-python-argcomplete pipx \
	&& eval "$(register-python-argcomplete pipx)"

# endregion

does_command_exist thefuck && eval "$(thefuck --alias)"

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
unset OLD_PATH SHELL_BASENAME
