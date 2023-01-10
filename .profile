#!/usr/bin/env sh

# "${HOME}"/.profile: executed by the command interpreter for login shells.
#
# See /usr/share/doc/bash/examples/startup-files for examples.
#
# The files are located in the bash-doc package.

# shellcheck disable=SC1091
. "$HOME"/.config/shell/env.sh

# Determine if we're in a Linux desktop environment.
# https://wiki.archlinux.org/title/Xinit
if [ "$DISPLAY" != "" ] && ! uname -a | grep -q -E 'Msys'; then
	# Swap Ctrl and Caps Lock.
	setxkbmap -option ctrl:swapcaps

	xrdb -merge "$XDG_CONFIG_HOME"/X11/xresources

	# FIXME: IDK how to properly start an X session from scratch.
	# exec startx "$XINITRC" i3 -- \
	# 	-keeptty "$XSERVERRC" >"$XDG_DATA_HOME"/xorg/Xorg.log 2>&1
fi
