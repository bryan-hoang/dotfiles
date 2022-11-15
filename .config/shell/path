#!/usr/bin/env sh

# Searched last

[ -d "$XDG_CONFIG_HOME"/rofi/scripts ] \
	&& export PATH="$XDG_CONFIG_HOME"/rofi/scripts:"$PATH"
[ -d "$XDG_DATA_HOME"/google-cloud-sdk/bin ] \
	&& export PATH="$XDG_DATA_HOME"/google-cloud-sdk/bin:"$PATH"

# Brew
[ -s /home/linuxbrew/.linuxbrew/bin/brew ] \
	&& eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
[ -s "$HOME"/.linuxbrew/bin/brew ] \
	&& eval "$("$HOME"/.linuxbrew/bin/brew shellenv)"

# JS eCoSyTeM
[ -d "$BUN_INSTALL"/bin ] \
	&& export PATH="$BUN_INSTALL"/bin:"$PATH"
[ -d "$DENO_INSTALL"/bin ] \
	&& export PATH="$DENO_INSTALL"/bin:"$PATH"
[ -d "$PNPM_HOME" ] \
	&& export PATH="$PNPM_HOME":"$PATH"

# shellcheck disable=SC1091
[ -s "$CARGO_HOME"/env ] && . "$CARGO_HOME"/env

[ -d "$ASDF_DIR"/bin ] \
	&& export PATH="$ASDF_DIR"/bin:"$PATH"
export PATH="$XDG_BIN_HOME":"$PATH"

# Searched first
