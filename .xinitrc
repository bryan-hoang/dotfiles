#!/usr/bin/env sh

. "${HOME}"/.functions

xmodmap .Xmodmap

# https://gist.github.com/abairo/5e2ed2faeadcc7abf43cda37826b2fbc#if-you-get-an-incosistent-theme-on-some-parts-of-the-system-or-windows-try-this
xsetroot -cursor_name left_ptr &

# https://wiki.archlinux.org/title/Flameshot#Troubleshooting
does_program_exist i3 && exec dbus-launch i3
