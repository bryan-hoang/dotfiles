#!/usr/bin/env bash
#
# vi: set filetype=sh

if [[ -n "${SSH_CONNECTION}" ]]; then
	# shellcheck disable=SC1091
	. "${ZDOTDIR}"/.zprofile
fi

# Uncomment the following line to disable auto-setting terminal title.
# shellcheck disable=SC2034
DISABLE_AUTO_TITLE="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)a
# Add wisely, as too many plugins slow down shell startup.
# shellcheck disable=SC2034
plugins=(
	command-not-found
	gitfast
	systemd
	# Completions
	docker
	docker-compose
	asdf
)

custom_plugins=(
	zsh-autosuggestions
	zsh-syntax-highlighting
	zsh-hist
	pyvenv-activate
)

declare ZSH_CUSTOM_PLUGINS_DIR="${ZSH}"/custom/plugins

for plugin in "${custom_plugins[@]}"; do
	[[ -d "${ZSH_CUSTOM_PLUGINS_DIR}"/"${plugin}" ]] \
		&& plugins+=("${plugin}")
done

# shellcheck disable=SC1091
[[ -s "${ZSH}"/oh-my-zsh.sh ]] && . "${ZSH}"/oh-my-zsh.sh

# Loaded after framework is loaded to preserve personal aliases.
# shellcheck disable=SC1091
. "${XDG_CONFIG_HOME}"/shell/common

# region Completions

mkdir -p "${XDG_CACHE_HOME}"/zsh
compinit -d "${XDG_CACHE_HOME}"/zsh/zcompdump-"${ZSH_VERSION}"
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME}"/zsh/zcompcache

ZSH_FPATH="${XDG_DATA_HOME}"/zsh/site-functions

does_program_exist compdef && compdef dot='git'

fpath+=${ZSH_CUSTOM_PLUGINS_DIR}/zsh-completions/src
fpath+=${ZSH_FPATH}

# For enabling autocompletion of privileged environments in privileged commands
# (e.g. if you complete a command starting with sudo, completion scripts will
# also try to determine your completions with sudo).
#
# Source: https://wiki.archlinux.org/title/zsh#Command_completion
zstyle ':completion::complete:*' gain-privileges 1

# https://wiki.archlinux.org/title/zsh#Persistent_rehash
zstyle ':completion:*' rehash true

# bun completions
#
# shellcheck disable=SC1091
[ -s "${HOME}"/.bun/_bun ] && source "${HOME}"/.bun/_bun

# tmuxinator completions.
[[ -s "${ZSH_FPATH}"/_tmuxinator ]] \
	|| wget https://raw.githubusercontent.com/tmuxinator/tmuxinator/master/completion/tmuxinator.zsh \
		-O "${ZSH_FPATH}"/_tmuxinator

# shellcheck disable=SC1091
. "${ZSH_FPATH}"/_tmuxinator

# endregion Completions

# Make `mapfile` available in `zsh`
zmodload zsh/mapfile

# Remove function defined in ohmyzsh conflicting with `title` command.
does_function_exist title && unfunction title

does_program_exist pyvenv_auto_activate_enable && pyvenv_auto_activate_enable

# Options
# Disabling Zsh's nomatch option
# http://zsh.sourceforge.net/Doc/Release/Options.html#Expansion-and-Globbing
setopt +o nomatch

# Save each command's beginning timestamp (in seconds since the epoch) and the
# duration (in seconds) to the history file. The format of this prefixed data
# is:
#
# ': <beginning time>:<elapsed seconds>;<command>'.
unsetopt EXTENDED_HISTORY

# If a new command line being added to the history list duplicates an older
# one, the older command is removed from the list (even if it is not the
# previous event).
setopt HIST_IGNORE_ALL_DUPS

# Do not enter command lines into the history list if they are duplicates of
# the previous event.
setopt HIST_IGNORE_DUPS

# Remove command lines from the history list when the first character on the
# line is a space, or when one of the expanded aliases contains a leading
# space. Only normal aliases (not global or suffix aliases) have this
# behaviour. Note that the command lingers in the internal history until the
# next command is entered before it vanishes, allowing you to briefly reuse or
# edit the line. If you want to make it vanish right away without entering
# another command, type a space and press return.
setopt HIST_IGNORE_SPACE

# When writing out the history file, older commands that duplicate newer ones
# are omitted.
setopt HIST_SAVE_NO_DUPS

# This option works like APPEND_HISTORY except that new history lines are added
# to the $HISTFILE incrementally (as soon as they are entered), rather than
# waiting until the shell exits. The file will still be periodically re-written
# to trim it when the number of lines grows 20% beyond the value specified by
# $SAVEHIST (see also the HIST_SAVE_BY_COPY option).
unsetopt INC_APPEND_HISTORY

# This option is a variant of INC_APPEND_HISTORY in which, where possible, the
# history entry is written out to the file after the command is finished, so
# that the time taken by the command is recorded correctly in the history file
# in EXTENDED_HISTORY format. This means that the history entry will not be
# available immediately from other instances of the shell that are using the
# same history file.
#
# This option is only useful if INC_APPEND_HISTORY and SHARE_HISTORY are turned
# off. The three options should be considered mutually exclusive.
setopt INC_APPEND_HISTORY_TIME

# This option both imports new commands from the history file, and also causes
# your typed commands to be appended to the history file (the latter is like
# specifying INC_APPEND_HISTORY, which should be turned off if this option is
# in effect). The history lines are also output with timestamps ala
# EXTENDED_HISTORY (which makes it easier to find the spot where we left off
# reading the file after it gets re-written).
#
# By default, history movement commands visit the imported lines as well as the
# local lines, but you can toggle this on and off with the set-local-history
# zle binding. It is also possible to create a zle widget that will make some
# commands ignore imported commands, and some include them.
#
# If you find that you want more control over when commands get imported, you
# may wish to turn SHARE_HISTORY off, INC_APPEND_HISTORY or
# INC_APPEND_HISTORY_TIME (see above) on, and then manually import commands
# whenever you need them using `fc -RI`.
unsetopt SHARE_HISTORY

# shellcheck disable=SC1091
[[ -s "${HOME}"/.asdf/plugins/java/set-java-home.zsh ]] \
	&& . "${HOME}"/.asdf/plugins/java/set-java-home.zsh

does_program_exist starship && eval "$(starship init zsh)"
does_program_exist mcfly && eval "$(mcfly init zsh)"
does_program_exist navi && eval "$(navi widget zsh)"
does_program_exist zoxide && eval "$(zoxide init zsh)"
does_program_exist pipenv \
	&& generate_completions zsh pipenv env _PIPENV_COMPLETE=zsh_source pipenv
does_program_exist broot && eval "$(broot --print-shell-function zsh)"

# shellcheck disable=SC1091
if [[ -f "${XDG_CONFIG_HOME:-${HOME}/.config}/asdf-direnv/zshrc" ]]; then
	# shellcheck disable=SC2250
	source "${XDG_CONFIG_HOME:-$HOME/.config}/asdf-direnv/zshrc"
fi

# tabtab source for packages (e.g., pnpm).
# shellcheck disable=SC1091
[[ -f "${HOME}"/.config/tabtab/zsh/__tabtab.zsh ]] \
	&& . "${HOME}"/.config/tabtab/zsh/__tabtab.zsh

# Update PATH for the Google Cloud SDK.
if [ -f "${XDG_DATA_HOME}"/google-cloud-sdk/path.zsh.inc ]; then
	# shellcheck disable=SC1091
	. "${XDG_DATA_HOME}"/google-cloud-sdk/path.zsh.inc
fi

# Enable shell command completion for gcloud.
if [ -f "${XDG_DATA_HOME}"/google-cloud-sdk/completion.zsh.inc ]; then
	# shellcheck disable=SC1091
	. "${XDG_DATA_HOME}"/google-cloud-sdk/completion.zsh.inc
fi
