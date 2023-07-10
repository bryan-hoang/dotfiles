#!/usr/bin/env sh

export XDG_LOCAL_HOME="$HOME"/.local
export XDG_BIN_HOME="$XDG_LOCAL_HOME"/bin
export XDG_DATA_HOME="$XDG_LOCAL_HOME"/share
export XDG_STATE_HOME="$XDG_LOCAL_HOME"/state
export XDG_CONFIG_HOME="$HOME"/.config
export XDG_CACHE_HOME="$HOME"/.cache

export BUN_INSTALL="$XDG_DATA_HOME"/bun
export DENO_INSTALL="$XDG_DATA_HOME"/deno
export PNPM_HOME="$XDG_DATA_HOME"/pnpm
export CARGO_HOME="$XDG_DATA_HOME"/cargo
export RUSTUP_HOME="$XDG_DATA_HOME"/rustup
export GOPATH="$XDG_DATA_HOME"/go

prepend_to_path() {
	# https://stackoverflow.com/a/20460402/8714233
	case "$PATH" in
		*"$1"*) ;;
		*) [ -d "$1" ] && export PATH="$1":"$PATH" ;;
	esac
}

# Searched last

prepend_to_path "$XDG_CONFIG_HOME"/rofi/scripts
prepend_to_path "$XDG_DATA_HOME"/google-cloud-sdk/bin
prepend_to_path "$XDG_DATA_HOME"/omnisharp
# Doom Emacs.
prepend_to_path "$XDG_CONFIG_HOME"/emacs/bin
# Brew
[ -s /home/linuxbrew/.linuxbrew/bin/brew ] \
	&& eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
[ -s "$HOME"/.linuxbrew/bin/brew ] \
	&& eval "$("$HOME"/.linuxbrew/bin/brew shellenv)"
# JS eCoSyTeM
prepend_to_path "$PNPM_HOME"
prepend_to_path "$DENO_INSTALL"/bin
prepend_to_path "$BUN_INSTALL"/bin
prepend_to_path "$GOPATH"/bin
# shellcheck disable=SC1091
[ -s "$CARGO_HOME"/env ] && . "$CARGO_HOME"/env
prepend_to_path "$XDG_BIN_HOME"

# Searched first

export XCURSOR_PATH="$XDG_DATA_HOME"/icons
export XCURSOR_THEME=Dracula-cursors
export XCURSOR_DISCOVER=1

# Default editor.
if
	command -v nvim >/dev/null
then
	export EDITOR=nvim
elif
	command -v vim >/dev/null
then
	export EDITOR=vim
fi

export VISUAL="$EDITOR"
export SUDO_EDITOR="$EDITOR"

export GOMODCACHE="$XDG_CACHE_HOME"/go

# Make Python use UTF-8 encoding for output to stdin, stdout, and stderr.
export PYTHONIOENCODING=UTF-8

# Increase history size. The default is 500.
export HISTFILESIZE=8192
export HISTSIZE="$HISTFILESIZE"
export SAVEHIST="$HISTFILESIZE"

# Omit duplicates and commands that begin with a space from history.
export HISTCONTROL='ignoreboth:erasedups'

# Pager settings
export PAGER=less

# Using Neovim as the man pager to make copying and following links easier.
command -v nvim >/dev/null \
	&& export MANPAGER='nvim +Man!'

# Remove linuxbrew man pages by default.
unset MANPATH
mkdir -p "$XDG_DATA_HOME"/man/man1

# Enable persistent REPL history for `node`.
export NODE_REPL_HISTORY="$XDG_STATE_HOME"/node/history
mkdir -p "$(dirname "$NODE_REPL_HISTORY")"

# Allow 32^3 entries; the default is 1000.
export NODE_REPL_HISTORY_SIZE="$HISTFILESIZE"

# Use sloppy mode by default, matching web browsers.
export NODE_REPL_MODE=sloppy
export NODE_INSPECT_RESUME_ON_START=1

export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME"/npm/npmrc

# -X leaves file contents on the screen when less exits.
#
# -F makes less quit if the entire output can be displayed on one screen.
#
# -R displays ANSI color escape sequences in "raw" form.
#
# -x Sets tab stops.
export LESS='-XFR -x 2'

# Hide the "default interactive shell is now zsh" warning on macOS.
export BASH_SILENCE_DEPRECATION_WARNING=1

# Locale
export LC_ALL=C.UTF-8

export FORCE_COLOR=true
export SHELLCHECK_OPTS='-x'
export GHQ_ROOT="$HOME"/src

command -v wezterm >/dev/null \
	&& export TERMINAL=wezterm

case ${TERM} in
	# WSL in windows Terminal colour support.
	xterm-256color | wezterm)
		export COLORTERM=truecolor
		;;
	*) ;;
esac

command -v vivid >/dev/null \
	&& LS_COLORS="$(vivid generate dracula)" \
	&& export LS_COLORS

export WEZTERM_CONFIG_FILE="$XDG_CONFIG_HOME"/wezterm/wezterm.lua

# `exa` options

# Sets how to format the time used in the long view's time column.
export TIME_STYLE=long-iso
# Enables strict mode, which will make exa error when two command-line options
# are incompatible.
export EXA_STRICT=true

# Don't set PYTHONUSERBASE to avoid issues with asdf installing python.
export PYTHONPYCACHEPREFIX="$XDG_CACHE_HOME"/python

# https://wiki.archlinux.org/title/XDG_Base_Directory#Specification

# shellcheck disable=SC1091,SC2154
. "$XDG_CONFIG_HOME"/zsh/.zshenv
# shellcheck disable=SC2154
export ZSH="$ZDOTDIR"/ohmyzsh
export ZSH_USER_FPATH="$XDG_DATA_HOME"/zsh/completions
mkdir -p "$ZSH_USER_FPATH"
export ZSH_CACHE_DIR="$XDG_CACHE_HOME"/zsh
export ZSH_COMPDUMP="$ZSH_CACHE_DIR"/.zcompdump
export HISTFILE="$XDG_STATE_HOME"/shell/history
mkdir -p "$(dirname "$HISTFILE")"
export TEXMFHOME="$XDG_DATA_HOME"/texmf
export TEXMFVAR="$XDG_CACHE_HOME"/texlive/texmf-var
export TEXMFCONFIG="$XDG_CONFIG_HOME"/texlive/texmf-config
export CONDARC="$XDG_CONFIG_HOME"/conda/condarc
export DOCKER_CONFIG="$XDG_CONFIG_HOME"/docker
export GNUPGHOME="$XDG_DATA_HOME"/gnupg
chmod 600 "$GNUPGHOME"/*
chmod 700 "$GNUPGHOME" "$GNUPGHOME"/private-keys-v1.d
export PASSWORD_STORE_DIR="$XDG_DATA_HOME"/pass
export INPUTRC="$XDG_CONFIG_HOME"/readline/inputrc
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME"/ripgrep/config
export STARSHIP_CONFIG="$XDG_CONFIG_HOME"/starship.toml
export STARSHIP_CACHE="$XDG_CACHE_HOME"/starship
export WAKATIME_HOME="$XDG_CONFIG_HOME"/wakatime
mkdir -p "$WAKATIME_HOME"
export MYSQL_HISTFILE="$XDG_STATE_HOME"/mysql/history
mkdir -p "$(dirname "$MYSQL_HISTFILE")"
export MYSQL_HOME="$XDG_CONFIG_HOME"/mysql
export SQLITE_HISTORY="$XDG_STATE_HOME"/sqlite/history
mkdir -p "$(dirname "$SQLITE_HISTORY")"
export WGETRC="$XDG_CONFIG_HOME"/wget/wgetrc

# Separate the repo from the data files to make fixing submodule issues less of
# a hassle.
export _JAVA_OPTIONS=-Djava.util.prefs.userRoot="$XDG_CONFIG_HOME"/java
export GTK_RC_FILES="$XDG_CONFIG_HOME"/gtk-1.0/gtkrc
export GTK2_RC_FILES="$XDG_CONFIG_HOME"/gtk-2.0/gtkrc

# startx doesn't respect the following variables.
export XINITRC="$XDG_CONFIG_HOME"/X11/xinitrc
export XSERVERRC="$XDG_CONFIG_HOME"/X11/xserverrc

# Don't set on git bash.
if ! uname -a | grep -q 'Msys'; then
	# https://blog.joren.ga/vim-xdg#viminit-environmental-variable
	export VIMINIT="if has('nvim') | so ${XDG_CONFIG_HOME}/nvim/init.lua | else | set nocp | so ${XDG_CONFIG_HOME}/vim/vimrc | endif"
fi

export VSCODE_PORTABLE="$XDG_DATA_HOME"/vscode
mkdir -p "$VSCODE_PORTABLE"
export PYTHONSTARTUP="$XDG_CONFIG_HOME"/python/pythonrc.py
export PYLINTRC="$XDG_CONFIG_HOME"/pylint/pylintrc
export CALCHISTFILE="$XDG_STATE_HOME"/calc/history
mkdir -p "$(dirname "$CALCHISTFILE")"

# FIXME: Changing the default causes a login loop in Ubuntu :(
#
# export XAUTHORITY="$HOME"/.Xauthority
export ICEAUTHORITY="$XDG_CACHE_HOME"/ICEauthority
export KDEHOME="$XDG_CONFIG_HOME"/kde
export OSH="$XDG_CONFIG_HOME"/oh-my-bash
export TMUX_PLUGIN_MANAGER_PATH="$XDG_DATA_HOME"/tmux/plugins
export WINEPREFIX="$XDG_DATA_HOME"/wineprefixes/default
mkdir -p "$(dirname "$WINEPREFIX")"

# Avoid hard coded ~/.osh-update from oh-my-bash.
export DISABLE_AUTO_UPDATE=true
export CLOUDSDK_CONFIG="$XDG_CONFIG_HOME"/gcloud
export JULIA_DEPOT_PATH="$XDG_DATA_HOME"/julia:"$JULIA_DEPOT_PATH"
export MINIKUBE_HOME="$XDG_DATA_HOME"/minikube
export MYPY_CACHE_DIR="$XDG_CACHE_HOME"/mypy
export CUDA_CACHE_PATH="$XDG_CACHE_HOME"/nv
export KOMOREBI_CONFIG_HOME="$XDG_CONFIG_HOME"/komorebi
export BACKUPS_DIR="$XDG_DATA_HOME"/backups
export SRC_DIR="$HOME"/src/localhost
mkdir -p "$SRC_DIR"
export BASH_COMPLETION_USER_DIR="$XDG_DATA_HOME"/bash-completion
mkdir -p "$BASH_COMPLETION_USER_DIR"/completions
export COMPOSER_HOME="$XDG_CONFIG_HOME"/composer
export FZF_DEFAULT_OPTS='--color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9 --color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9 --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6 --color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4'
# shellcheck disable=SC2154
export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR}/ssh-agent.socket"
export TERMINFO="$XDG_DATA_HOME"/terminfo
export TERMINFO_DIRS="$XDG_DATA_HOME"/terminfo:/usr/share/terminfo
export RUBY_DEBUG_HISTORY_FILE="$XDG_STATE_HOME"/rdbg/history
mkdir -p "$(dirname "$RUBY_DEBUG_HISTORY_FILE")"
export BUNDLE_USER_CACHE="$XDG_CACHE_HOME"/bundle
export BUNDLE_USER_CONFIG="$XDG_CONFIG_HOME"/bundle/config
export PIPX_HOME="$XDG_DATA_HOME"/pipx
export SDIRS="$XDG_STATE_HOME"/bashmarks/sdirs
mkdir -p "$(dirname "$SDIRS")"
# https://github.com/mozilla/sccache#usage
if command -v sccache >/dev/null; then
	export RUSTC_WRAPPER=sccache
	export CMAKE_C_COMPILER_LAUNCHER="$RUSTC_WRAPPER"
	export CMAKE_CXX_COMPILER_LAUNCHER="$RUSTC_WRAPPER"
fi
# https://doc.rust-lang.org/stable/cargo/reference/environment-variables.html#environment-variables-cargo-sets-for-build-scripts
NUM_JOBS="$(nproc)"
export NUM_JOBS
export MAKEFLAGS="--jobs $NUM_JOBS"
export CARGO_MAKEFLAGS="$MAKEFLAGS"
# https://github.com/jdxcode/rtx#rtx_use_toml
export RTX_USE_TOML=1
export RTX_SHIMS_DIR="$XDG_DATA_HOME"/rtx/shims
export SUDO_PROMPT='[sudo] password for %p@%H to run as %U: '
export STARSHIP_CONFIG="$XDG_CONFIG_HOME"/starship/starship.toml
# https://wiki.archlinux.org/title/Alacritty#Different_font_size_on_multiple_monitors
export WINIT_X11_SCALE_FACTOR=1
# https://github.com/jD91mZM2/xidlehook#configuring-via-systemd
export XIDLEHOOK_SOCK="$XDG_RUNTIME_DIR"/xidlehook.socket
export CARGO_REGISTRIES_CRATES_IO_PROTOCOL=sparse
# Default Brewfile location. See `brew bundle --help`.
export HOMEBREW_BUNDLE_FILE="$XDG_CONFIG_HOME"/brewfile/Brewfile
# Disable marksman crashing due to missing icu dependency.
# https://learn.microsoft.com/en-us/dotnet/core/runtime-config/globalization#invariant-mode
# https://stackoverflow.com/questions/59119904/process-terminated-couldnt-find-a-valid-icu-package-installed-on-the-system-in
export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
export SHELDON_DATA_DIR="$XDG_DATA_HOME"/sheldon
