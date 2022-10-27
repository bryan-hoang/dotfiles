#!/usr/bin/env sh

# "${HOME}"/.profile: executed by the command interpreter for login shells.
#
# See /usr/share/doc/bash/examples/startup-files for examples.
#
# The files are located in the bash-doc package.

# shellcheck disable=SC1091
. "$HOME"/.config/shell/exports
# shellcheck disable=SC1091
. "$HOME"/.config/shell/path

# https://wiki.archlinux.org/title/Xinit
if [ "$DISPLAY" != "" ] && [ "${XDG_VTNR:-42}" -le 2 ]; then
	# Swap Ctrl and Caps Lock.
	setxkbmap -option ctrl:swapcaps

	# https://gist.github.com/abairo/5e2ed2faeadcc7abf43cda37826b2fbc#if-you-get-an-incosistent-theme-on-some-parts-of-the-system-or-windows-try-this
	xsetroot -cursor_name left_ptr &
	xrdb -merge "$XDG_CONFIG_HOME"/X11/xresources

	# FIXME: IDK how to properly start an X session from scratch.
	# exec startx "${XINITRC}" i3 -- \
	# 	-keeptty "${XSERVERRC}" &>"${XDG_DATA_HOME}"/xorg/Xorg.log
fi
