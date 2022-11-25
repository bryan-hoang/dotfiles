#!/usr/bin/env bash

export XDG_LOCAL_HOME="$HOME"/.local
export XDG_BIN_HOME="$XDG_LOCAL_HOME"/bin
export XDG_DATA_HOME="$XDG_LOCAL_HOME"/share
export XDG_STATE_HOME="$XDG_LOCAL_HOME"/state
export XDG_CONFIG_HOME="$HOME"/.config
export XDG_CACHE_HOME="$HOME"/.cache

export XCURSOR_PATH="$XDG_DATA_HOME"/icons
export XCURSOR_THEME=Dracula-cursors
export XCURSOR_DISCOVER=1

# Default editor.
if command -v nvim &>/dev/null || [[ -f ${XDG_BIN_HOME}/nvim ]]; then
	export EDITOR=nvim
	export VISUAL=${EDITOR}
	export SUDO_EDITOR=${EDITOR}
elif command -v vim &>/dev/null; then
	export EDITOR=vim
	export VISUAL=${EDITOR}
	export SUDO_EDITOR=${EDITOR}
fi

# Make Python use UTF-8 encoding for output to stdin, stdout, and stderr.
export PYTHONIOENCODING=UTF-8

# Increase history size. The default is 500.
export HISTSIZE=32768
export HISTFILESIZE=${HISTSIZE}
export SAVEHIST=${HISTSIZE}

# Omit duplicates and commands that begin with a space from history.
export HISTCONTROL='ignoreboth:erasedups'

# Pager settings
export PAGER=less

# Using Neovim as the man pager to make copying and following links easier.
command -v nvim &>/dev/null \
	&& export MANPAGER='nvim +Man!'

# Enable persistent REPL history for `node`.
mkdir -p "$XDG_STATE_HOME"/node
export NODE_REPL_HISTORY="$XDG_STATE_HOME"/node/node_repl_history

# Allow 32^3 entries; the default is 1000.
export NODE_REPL_HISTORY_SIZE=${HISTSIZE}

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

# Avoid issues with `gpg` as installed via Homebrew.
# https://stackoverflow.com/a/42265848/96656
export GPG_TTY=${TTY}

# Hide the "default interactive shell is now zsh" warning on macOS.
export BASH_SILENCE_DEPRECATION_WARNING=1

# Locale
export LC_ALL=C.UTF-8

export FORCE_COLOR=true
export SHELLCHECK_OPTS='-x'
export GHQ_ROOT="$HOME"/src

case ${TERM} in
	# WSL in windows Terminal colour support.
	xterm-256color)
		export COLORTERM=truecolor
		;;
	*) ;;
esac

export TERMINAL=wezterm
export WEZTERM_CONFIG_FILE="$XDG_CONFIG_HOME"/wezterm/wezterm.lua

# `exa` options

# Sets how to format the time used in the long view's time column.
export TIME_STYLE=long-iso
# Enables strict mode, which will make exa error when two command-line options
# are incompatible.
export EXA_STRICT=true

export MCFLY_KEY_SCHEME=vim
export MCFLY_RESULTS_SORT=LAST_RUN
export MCFLY_HISTORY_LIMIT=${HISTSIZE}
export MCFLY_RESULTS=20
export MCFLY_INTERFACE_VIEW=BOTTOM
export MCFLY_FUZZY=2

# Don't set PYTHONUSERBASE to avoid issues with asdf installing python.
export PYTHONPYCACHEPREFIX="$XDG_CACHE_HOME"/python

# https://wiki.archlinux.org/title/XDG_Base_Directory#Specification

mkdir -p "$XDG_STATE_HOME"/shell
export HISTFILE="$XDG_STATE_HOME"/shell/history
export TEXMFHOME="$XDG_DATA_HOME"/texmf
export TEXMFVAR="$XDG_CACHE_HOME"/texlive/texmf-var
export TEXMFCONFIG="$XDG_CONFIG_HOME"/texlive/texmf-config
export PNPM_HOME="$XDG_DATA_HOME"/pnpm
export CONDARC="$XDG_CONFIG_HOME"/conda/condarc
export DOCKER_CONFIG="$XDG_CONFIG_HOME"/docker
chmod 600 "$HOME"/.gnupg/*
chmod 700 "$HOME"/.gnupg
export GNUPGHOME="$HOME"/.gnupg
export PASSWORD_STORE_DIR="$XDG_DATA_HOME"/pass
export INPUTRC="$XDG_CONFIG_HOME"/readline/inputrc
export RIPGREP_CONFIG_PATH=${XDG_CONFIG_HOME}/ripgrep/config
export STARSHIP_CONFIG="$XDG_CONFIG_HOME"/starship.toml
export STARSHIP_CACHE="$XDG_CACHE_HOME"/starship
mkdir -p "$XDG_CONFIG_HOME"/wakatime
export WAKATIME_HOME="$XDG_CONFIG_HOME"/wakatime
mkdir -p "$XDG_STATE_HOME"/mysql
export MYSQL_HISTFILE="$XDG_STATE_HOME"/mysql/history
mkdir -p "$XDG_STATE_HOME"/sqlite
export SQLITE_HISTORY=${XDG_STATE_HOME}/sqlite/history
export WGETRC="$XDG_CONFIG_HOME"/wget/wgetrc

# Separate the repo from the data files to make fixing submodule issues less of
# a hassle.
export ASDF_DIR="$HOME"/src/github.com/asdf-vm/asdf
export ASDF_DATA_DIR="$XDG_DATA_HOME"/asdf
export ASDF_CONFIG_FILE="$XDG_CONFIG_HOME"/asdf/asdfrc
export CARGO_HOME="$XDG_DATA_HOME"/cargo
export RUSTUP_HOME="$XDG_DATA_HOME"/rustup
export _JAVA_OPTIONS=-Djava.util.prefs.userRoot="$XDG_CONFIG_HOME"/java
export GTK_RC_FILES="$XDG_CONFIG_HOME"/gtk-1.0/gtkrc
export GTK2_RC_FILES="$XDG_CONFIG_HOME"/gtk-2.0/gtkrc

# startx doesn't respect the following variables.
export XINITRC="$XDG_CONFIG_HOME"/X11/xinitrc
export XSERVERRC="$XDG_CONFIG_HOME"/X11/xserverrc

# Don't set on git bash.
if ! uname -a | grep -q 'Msys'; then
	export VIMINIT="let \$MYVIMRC = has(\"nvim\") ? \"${XDG_CONFIG_HOME}/nvim/init.lua\" : \"${XDG_CONFIG_HOME}/vim/vimrc\" | so \$MYVIMRC"
fi

export VSCODE_PORTABLE="$XDG_DATA_HOME"/vscode
export PYTHONSTARTUP="$XDG_CONFIG_HOME"/python/pythonrc.py
export PYLINTRC="$XDG_CONFIG_HOME"/pylint/pylintrc
mkdir -p "$XDG_STATE_HOME"/calc
export CALCHISTFILE="$XDG_STATE_HOME"/calc/history

# FIXME: Makes login fail :/
# export XAUTHORITY="${XDG_CACHE_HOME}"/Xauthority
export ICEAUTHORITY="$XDG_CACHE_HOME"/ICEauthority
export DENO_INSTALL="$XDG_DATA_HOME"/deno
export BUN_INSTALL="$XDG_DATA_HOME"/bun
export KDEHOME="$XDG_CONFIG_HOME"/kde
export OSH="$XDG_CONFIG_HOME"/oh-my-bash
. "$HOME"/.zshenv
export ZSH="$XDG_CONFIG_HOME"/ohmyzsh
export ZSH_USER_FPATH="$XDG_DATA_HOME"/zsh/completions
mkdir -p "$ZSH_USER_FPATH"
export TMUX_PLUGIN_MANAGER_PATH="$XDG_CONFIG_HOME"/tmux/plugins
mkdir -p "$XDG_DATA_HOME"/wineprefixes
export WINEPREFIX="$XDG_DATA_HOME"/wineprefixes/default

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