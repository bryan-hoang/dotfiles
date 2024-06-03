#!/usr/bin/env sh

# "${HOME}"/.profile: executed by the command interpreter for login shells.
#
# See /usr/share/doc/bash/examples/startup-files for examples.
#
# The files are located in the bash-doc package.

# shellcheck disable=SC1091
. "$HOME"/.config/shell/env.sh
[ -s "$HOME"/.config/shell/extra.sh ] && . "$HOME"/.config/shell/extra.sh

# https://wiki.archlinux.org/title/Systemd/User#Environment_variables
if command -v dbus-update-activation-environment >/dev/null \
	&& command -v systemctl >/dev/null; then
	update_tmux_env() {
		(
			unset SHLVL SSH_CONNECTION SSH_CLIENT SSH_TTY TMUX

			# Avoid triggering the starship prompt module in tmux server started by
			# systemd. Remove lingering SSH env vars.
			dbus-update-activation-environment --systemd --all >/dev/null 2>&1 \
				|| awk 'BEGIN{for(v in ENVIRON) print v}' | grep -iv -e awk -e lua -e ^_ \
				| xargs systemctl --user import-environment
			systemctl --user unset-environment SHLVL SSH_CONNECTION SSH_CLIENT SSH_TTY TMUX
			systemctl --user daemon-reload
			systemctl --user start tmux.service
		)
	}

	update_tmux_env

	# Only run the lemonade server when not over ssh and with a desktop environment.
	# shellcheck disable=2154
	if [ "$SSH_CONNECTION" = "" ] && command -v i3 >/dev/null; then
		systemctl --user start lemonade.service
	fi
fi
