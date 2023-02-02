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
	(
		# Avoid triggering the starship prompt module in tmux server started by
		# systemd. Remove lingering SSH env vars.
		unset SHLVL SSH_CONNECTION SSH_CLIENT SSH_TTY
		dbus-update-activation-environment --systemd --all
		systemctl --user start tmux.service
	)
fi

# Determine if we're in a Linux desktop environment.
# https://wiki.archlinux.org/title/Xinit
if [ "$DISPLAY" != "" ] && ! uname -a | grep -q -E 'Msys'; then
	setxkbmap -option ctrl:swapcaps
	setxkbmap -option compose:rctrl

	xrdb -merge "$XDG_CONFIG_HOME"/X11/xresources

	# FIXME: IDK how to properly start an X session from scratch.
	# exec startx "$XINITRC" i3 -- \
	# 	-keeptty "$XSERVERRC" >"$XDG_DATA_HOME"/xorg/Xorg.log 2>&1
fi
