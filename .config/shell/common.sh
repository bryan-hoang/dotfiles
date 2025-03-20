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
export SHELL_BASENAME

# NOTE: Activate starship before `mise` to avoid `_mise_hook` in
# `$PROMPT_COMMAND` (bash) from getting saved into `$_PRESERVED_PROMPT_COMMAND`.
# This avoids getting "command not found: _mise_hook" for every prompt due too
# starship's hook trying to to eval the ones it "saved".
does_command_exist starship && eval "$(starship init "$SHELL_BASENAME")"
does_command_exist mise && eval "$(mise activate "$SHELL_BASENAME")"

if [[ -n $SSH_CONNECTION ]] \
	&& [[ -z $TMUX ]] \
	&& [[ -z $ZELLIJ ]] \
	&& [[ -z $VSCODE_INJECTION ]]; then
	does_command_exist rust-motd && rust-motd
fi

# region: Completions

generate_completions ast-grep ast-grep completions
generate_completions atuin atuin gen-completions --shell "$SHELL_BASENAME"
generate_completions bob bob complete "$SHELL_BASENAME"
generate_completions cargo rustup completions "$SHELL_BASENAME" cargo
generate_completions delta delta --generate-completion "$SHELL_BASENAME"
generate_completions deno deno completions "$SHELL_BASENAME"
generate_completions dufs dufs --completions "$SHELL_BASENAME"
generate_completions genact genact --print-completions "$SHELL_BASENAME"
generate_man_pages genact genact --print-manpage
generate_completions gh gh completion -s "$SHELL_BASENAME"
generate_completions git-absorb git-absorb --gen-completions "$SHELL_BASENAME"
generate_completions glab glab completion --shell "$SHELL_BASENAME"
generate_completions just just --completions "$SHELL_BASENAME"
generate_completions mise mise completion "$SHELL_BASENAME"
generate_completions poetry poetry completions "$SHELL_BASENAME"
generate_completions ruff ruff generate-shell-completion "$SHELL_BASENAME"
generate_completions rustup rustup completions "$SHELL_BASENAME" rustup
generate_completions sheldon sheldon completions --shell "$SHELL_BASENAME"
generate_completions starship starship completions "$SHELL_BASENAME"
generate_completions uv uv generate-shell-completion "$SHELL_BASENAME"
generate_completions watchexec watchexec --completions "$SHELL_BASENAME"
generate_man_pages watchexec watchexec --manual
generate_completions zellij zellij setup --generate-completion "$SHELL_BASENAME"

# Doesn't support bash.
generate_completions bw bw completion --shell zsh
generate_completions kubectl kubectl completion zsh
generate_completions pipenv env _PIPENV_COMPLETE=zsh_source pipenv
does_command_exist register-python-argcomplete pipx \
	&& eval "$(register-python-argcomplete pipx)"

# endregion

does_command_exist thefuck && eval "$(thefuck --alias)"
# Hook in before `atuin` to avoid overwriting CTRL-R keybind.
does_command_exist fzf && eval "$(fzf --"$SHELL_BASENAME")"

# Disable atuin on zfs file systems. See
# https://github.com/atuinsh/atuin/issues/952
# if [[ -d /home ]] && df --print-type /home | tail --lines=+2 \
# 	| awk '{print $2}' | grep --quiet --invert-match zfs; then
does_command_exist atuin && eval "$(atuin init --disable-up-arrow "$SHELL_BASENAME")"
# fi

# https://wiki.archlinux.org/title/XDG_Base_Directory
mkdir -p "$XDG_DATA_HOME"/tig

# If set, bash/zsh does not overwrite an existing file with the >, >&, and <>
# redirection operators. This may be overridden when creating output files by
# using the redirection operator >| instead of >.
set -o noclobber

# Set tabs in the terminal to differ from the default of 8.
tabs -2

# Set the environment variable per interactive session. Otherwise `tty` returns
# "not a tty" if ran from `.profile`.
# https://wiki.archlinux.org/title/GnuPG#Configure_pinentry_to_use_the_correct_TTY
export GPG_TTY=${TTY:-$(tty)}
if command -v gpg-connect-agent >/dev/null; then
	gpg-connect-agent updatestartuptty /bye &>/dev/null
fi

# Automatic transparency for xterm.
# https://wiki.archlinux.org/title/Xterm#Automatic_transparency
[[ -n $XTERM_VERSION ]] && transset --id "$WINDOWID" >/dev/null

does_command_exist zoxide && eval "$(zoxide init "$SHELL_BASENAME")"

unset SHELL_BASENAME
