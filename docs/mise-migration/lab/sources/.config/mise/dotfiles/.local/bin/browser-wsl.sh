#!/bin/sh

# Opens each argument with the Windows default handler from WSL. The value
# reaches PowerShell through WSLENV as data, never as command text.
powershell=/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe

if [ "${WSL_DISTRO_NAME:-}" = "" ] || [ ! -x "$powershell" ]; then
	echo 'browser-wsl.sh: run this script in a WSL instance.' >&2
	exit 1
fi

for target; do
	# shellcheck disable=SC2016 # PowerShell, not sh, expands the variable.
	BROWSER_WSL_TARGET=$target WSLENV=BROWSER_WSL_TARGET${WSLENV:+:$WSLENV} \
		"$powershell" -NoProfile -NonInteractive -Command \
		'Start-Process -FilePath $env:BROWSER_WSL_TARGET' || exit
done
