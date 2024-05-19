#!/usr/bin/env sh
#
# shellcheck disable=SC1091,SC2154

if [ "${USER:-}" = "" ]; then
	USER="$(id -un 2>/dev/null)"
	export USER
fi

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
export RYE_HOME="$XDG_DATA_HOME"/rye
export WASMER_DIR="$XDG_DATA_HOME"/wasmer
export WASMER_CACHE_DIR="$XDG_CACHE_HOME"/wasmer
# [ -s "$WASMER_DIR"/wasmer.sh ] && . "$WASMER_DIR"/wasmer.sh

prepend_to_path() {
	for folder in "$@"; do
		# https://stackoverflow.com/a/20460402/8714233
		case "$PATH" in
			*"$folder"*) ;;
			*) [ -d "$folder" ] && export PATH="$folder":"$PATH" ;;
		esac
	done
}

prepend_brew_to_path() {
	for brew_prefix in "$@"; do
		# https://stackoverflow.com/a/20460402/8714233
		case "$PATH" in
			# Do nothing if it's already added.
			*"$brew_prefix"*) ;;
			*)
				[ -s "$brew_prefix"/bin/brew ] \
					&& eval "$("$brew_prefix"/bin/brew shellenv)"
				;;
		esac
	done
}

# Searched last

# mise
# prepend_to_path "$XDG_DATA_HOME"/mise/shims
# Brew
prepend_brew_to_path /home/linuxbrew/.linuxbrew
prepend_brew_to_path "$HOME"/.linuxbrew
# Misc.
prepend_to_path "$XDG_CONFIG_HOME"/rofi/scripts
prepend_to_path "$XDG_DATA_HOME"/google-cloud-sdk/bin
prepend_to_path "$XDG_DATA_HOME"/omnisharp
# Doom Emacs.
prepend_to_path "$XDG_CONFIG_HOME"/emacs/bin
# Neovim managed by bob (MordechaiHadad/bob).
prepend_to_path "$XDG_DATA_HOME"/bob/nvim-bin
# shellcheck disable=SC2154
prepend_to_path "$LOCALAPPDATA"/bob/nvim-bin
# JS eCoSyTeM
prepend_to_path "$PNPM_HOME"
prepend_to_path "$WASMER_DIR"/bin
prepend_to_path "$DENO_INSTALL"/bin
prepend_to_path "$BUN_INSTALL"/bin
# Go
prepend_to_path "$GOPATH"/bin
# Python managed by rye
[ -s "$RYE_HOME"/env ] && . "$RYE_HOME"/env
# Rust
[ -s "$CARGO_HOME"/env ] && . "$CARGO_HOME"/env
# Personal
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

# Increase history size.
export HISTFILESIZE=8192
# From bash, default is 500 (see `man bash`).
export HISTSIZE="$HISTFILESIZE"
# From zsh (see `man zshparam`).
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
export NODE_COMPILE_CACHE="$XDG_CACHE_HOME"/node/compile

export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME"/npm/npmrc

export RUBY_DEBUG_HISTORY_FILE="$XDG_STATE_HOME"/rdbg/history
mkdir -p "$(dirname "$RUBY_DEBUG_HISTORY_FILE")"
export RUBY_YJIT_ENABLE=1

# Colors

# -F|--quit-if-one-screen - makes less quit if the entire output can be
# displayed on one screen.
#
# -R|--RAW-CONTROL-CHARS - displays ANSI color escape sequences in "raw" form.
#
# -I|--IGNORE-CASE
#
# -X|--no-init - leaves file contents on the screen when less exits.
#
# -xn|--tabs=n Sets tab stops.
export LESS='-FIRXx2'
# https://force-color.org/
export FORCE_COLOR=1
command -v vivid >/dev/null \
	&& LS_COLORS="$(vivid generate dracula)" \
	&& export LS_COLORS
case ${TERM} in
	# WSL in windows Terminal colour support.
	xterm-256color | wezterm)
		export COLORTERM=truecolor
		;;
	*) ;;
esac
export FZF_DEFAULT_OPTS='--color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9 --color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9 --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6 --color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4'

# Hide the "default interactive shell is now zsh" warning on macOS.
export BASH_SILENCE_DEPRECATION_WARNING=1

# Locale
export LC_ALL=C.UTF-8

export SHELLCHECK_OPTS='-x'
export GHQ_ROOT="$HOME"/src

export WEZTERM_CONFIG_FILE="$XDG_CONFIG_HOME"/wezterm/wezterm.lua

# `exa` options

# Sets how to format the time used in the long view's time column.
export TIME_STYLE=long-iso
# Enables strict mode, which will make exa error when two command-line options
# are incompatible.
export EXA_STRICT=true

# Make Python use UTF-8 encoding for output to stdin, stdout, and stderr.
export PYTHONIOENCODING=UTF-8

# Don't set PYTHONUSERBASE to avoid issues with asdf installing python.
export PYTHONSTARTUP="$XDG_CONFIG_HOME"/python/pythonrc.py
export PYTHON_HISTORY="$XDG_STATE_HOME"/python/history
export PYTHONPYCACHEPREFIX="$XDG_CACHE_HOME"/python

# https://wiki.archlinux.org/title/XDG_Base_Directory#Specification

. "$XDG_CONFIG_HOME"/zsh/.zshenv
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
export DOCKER_CONFIG="$XDG_CONFIG_HOME"/docker
export GNUPGHOME="$XDG_DATA_HOME"/gnupg
mkdir -p "$GNUPGHOME" "$GNUPGHOME"/private-keys-v1.d
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

export NVIM_APPNAME=nvim

# Don't set on git bash.
if ! uname -a | grep -q 'Msys'; then
	# https://blog.joren.ga/vim-xdg#viminit-environmental-variable
	export VIMINIT="if has('nvim') | so \$XDG_CONFIG_HOME/\$NVIM_APPNAME/init.lua | else | set nocp | so \$XDG_CONFIG_HOME/vim/vimrc | endif"
fi

export VSCODE_PORTABLE="$XDG_DATA_HOME"/vscode
mkdir -p "$VSCODE_PORTABLE"
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
export BACKUPS_DIR="$XDG_DATA_HOME"/backups
export SRC_DIR="$HOME"/src/localhost
mkdir -p "$SRC_DIR"
export BASH_COMPLETION_USER_DIR="$XDG_DATA_HOME"/bash-completion
mkdir -p "$BASH_COMPLETION_USER_DIR"/completions
export COMPOSER_HOME="$XDG_CONFIG_HOME"/composer
# shellcheck disable=SC2154
export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR}/ssh-agent.socket"
export TERMINFO="$XDG_DATA_HOME"/terminfo
export TERMINFO_DIRS="$XDG_DATA_HOME"/terminfo:/usr/share/terminfo
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
# Enable the generation of `compile_commands.json` by default.
# https://clangd.llvm.org/installation#project-setup
export CMAKE_EXPORT_COMPILE_COMMANDS=1
# https://doc.rust-lang.org/stable/cargo/reference/environment-variables.html#environment-variables-cargo-sets-for-build-scripts
NUM_JOBS="$(nproc)"
export NUM_JOBS
export MAKEFLAGS="--jobs $NUM_JOBS"
export CARGO_MAKEFLAGS="$MAKEFLAGS"
# https://blog.rust-lang.org/2023/11/09/parallel-rustc.html
export RUSTFLAGS="-Z threads=8"
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
export DOTNET_CLI_HOME="$XDG_DATA_HOME"/dotnet
export SHELDON_DATA_DIR="$XDG_DATA_HOME"/sheldon
export DCP_HOMEDIR="$XDG_DATA_HOME"
# Make Emscripten XDG Base Directory sped compliant.
export EM_CONFIG="$XDG_CONFIG_HOME"/emscripten/config
export EM_CACHE="$XDG_CACHE_HOME"/emscripten/cache
export EM_PORTS="$XDG_DATA_HOME"/emscripten/cache
# Make mozbuild tooling comply w/ XDG sped.
export MOZBUILD_STATE_PATH="$XDG_DATA_HOME"/mozbuild
# https://www.haskell.org/ghcup/guide/#xdg-support
export GHCUP_USE_XDG_DIRS=1
# Preferred over GNU screen's default of `~/.screenrc`.
export SCREENRC="$XDG_CONFIG_HOME"/screen/screenrc
export BOB_CONFIG="$XDG_CONFIG_HOME"/bob/config.toml
export TAPLO_CONFIG="$XDG_CONFIG_HOME"/taplo/.taplo.toml
# Hide messages from npm installing.
export DISABLE_OPENCOLLECTIVE=1
export ADBLOCK=1
export SUPPRESS_SUPPORT=1
export WARP_THEMES_DIR="$XDG_DATA_HOME"/warp-terminal/themes
# PostgreSQL
export PSQLRC="$XDG_CONFIG_HOME/pg/psqlrc"
export PSQL_HISTORY="$XDG_STATE_HOME/pg/history"
export PGPASSFILE="$XDG_CONFIG_HOME/pg/pgpass"
export PGSERVICEFILE="$XDG_CONFIG_HOME/pg/pg_service.conf"
mkdir -p "$(dirname "$PSQLRC")"
mkdir -p "$(dirname "$PSQL_HISTORY")"
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
export FONT_MONO='BerkeleyMono Nerd Font Mono'
