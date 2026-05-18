#!/bin/sh

readonly POWERSHELL=/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe

if uname -a | grep -q -E 'WSL' && [ -f "$POWERSHELL" ]; then
	$POWERSHELL -Command "Start-Process '$*'"
else
	echo 'Only run this script in a WSL instance.' >&2
	exit 1
fi
