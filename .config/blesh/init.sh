#!/usr/bin/env sh

# Change to match `zsh-autosuggestions`.
ble-face -s auto_complete fg=008

# Disable error exit marker like "[ble: exit %d]"
bleopt exec_errexit_mark=
# Disable exit marker like "[ble: exit]"
bleopt exec_exit_mark=
# Disable elapsed-time marker like "[ble: elapsed 1.203s (CPU 0.4%)]"
bleopt exec_elapsed_mark=
# Change EOF marker from "[ble: EOF]"
bleopt prompt_eol_mark='⏎'
# Disable auto-complete on windows due to perf issues searching PATH.
if [ "$(uname -o)" = 'Msys' ]; then
	bleopt complete_auto_complete=
fi
