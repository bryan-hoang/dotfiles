#!/usr/bin/env bash
# Home gate (#376) run for the Fedora 44 WSL fixture. Stage the gate with the
# runner's -Bin <lab>/home-gate.ps1; the runner stages PowerShell 7 as
# ~/lab-in/pwsh.tar.gz. Adopts the exchange copy in a fresh HOME, writes lab
# local inputs, then runs the gate: clean (pass, exact pre-gate hash), each
# injected fault (a missing core local input, a local-input path in history,
# an unknown field in a sanitized source, no systemd user session, a
# conflict), and the work identity. The drift
# sentinel is Windows-only (E161). No gate output may contain a local-input or
# identity value. Results land in ~/lab-out/linux-home-gate.txt; pass=yes only
# when every check holds.
set -uo pipefail

in=$HOME/lab-in
out=$HOME/lab-out
lab=$HOME/lab
mkdir -p "$out" "$lab"
results=$out/linux-home-gate.txt
: >"$results"
fails=()
say() { printf '%s=%s\n' "$1" "$2" | tee -a "$results"; }
check() {
	say "$1" "$2"
	[[ $2 == "$3" ]] || fails+=("$1")
}
finish() {
	say failed_checks "$(if ((${#fails[@]})); then
		IFS=,
		printf '%s' "${fails[*]}"
	else printf none; fi)"
	say pass "$( ((${#fails[@]})) && echo no || echo yes)"
	exit 0
}
run() {
	local name=$1
	shift
	timeout 900 "$@" >"$out/$name.log" 2>&1
}
val() { sed -n "s/^$2=//p" "$out/$1.log" | head -n1; }
blob() { git hash-object --no-filters -- "$1"; }

unset XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME XDG_CACHE_HOME
export MISE_HISTORY_SYNC=manual
export MISE_AUTO_INSTALL=0
export GIT_CONFIG_NOSYSTEM=1
export GIT_CONFIG_GLOBAL=$lab/gitconfig
export GIT_TERMINAL_PROMPT=0
export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
export POWERSHELL_TELEMETRY_OPTOUT=1
export POWERSHELL_UPDATECHECK=Off
chmod +x "$in"/bin/*
export PATH=$in/bin:$PATH

if [[ ! -f $in/pwsh.tar.gz ]]; then
	say error pwsh-media-not-staged
	fails+=(error)
	finish
fi
mkdir -p "$lab/pwsh"
tar -xzf "$in/pwsh.tar.gz" -C "$lab/pwsh"
chmod +x "$lab/pwsh/pwsh"
pwsh=$lab/pwsh/pwsh
cp "$in/bin/home-gate.ps1" "$lab/home-gate.ps1"
say pwsh "$(timeout 60 "$pwsh" -NoProfile -NonInteractive -Command "\$PSVersionTable.PSVersion.ToString()" 2>/dev/null)"

ex=$lab/exchange
gh=https://github.com
cp -a "$in/exchange" "$ex"
{
	printf '[protocol]\n\tallow = never\n[protocol "file"]\n\tallow = always\n'
	printf '[user]\n\tname = Lab\n\temail = lab@localhost\n'
	while read -r repo; do
		[[ $repo != "" ]] || continue
		printf '[url "%s"]\n\tinsteadOf = %s/%s\n' "$ex/mirrors/$repo.git" "$gh" "$repo"
		printf '[url "%s"]\n\tinsteadOf = %s/%s.git\n' "$ex/mirrors/$repo.git" "$gh" "$repo"
	done <"$in/repos.txt"
	for origin in https://github.com/bryan-hoang/dotfiles ssh://git@github.com/bryan-hoang/dotfiles; do
		printf '[url "%s"]\n\tinsteadOf = %s\n' "$ex/setup.git" "$origin"
	done
} >"$GIT_CONFIG_GLOBAL"
say mise "$(timeout 30 mise --version 2>/dev/null | cut -d' ' -f1)"
seed=$(git -C "$ex/setup.git" rev-parse main)
say conversion_commit "$seed"

real_home=$HOME
export HOME=$lab/home
mkdir -p "$HOME/.config/mise" "$HOME/.config/git"
printf 'env = ["wsl"]\n' >"$HOME/.config/mise/miserc.local.toml"
run adopt mise bootstrap --adopt https://github.com/bryan-hoang/dotfiles --yes --skip tools
check adopt_exit "$?" 0

# Lab local inputs (synthetic values; the marker and identities must never
# appear in gate output). Fresh per run and built from parts, so no committed
# file or past commit holds them.
run_id=$(od -An -N6 -tx1 /dev/urandom | tr -d ' \n')
marker=lab-marker-376-$run_id
work_name="Lab Work $run_id"
work_email=lab-work-$run_id'@'example.invalid
proxy_host=lab-proxy-$run_id.invalid
local_toml=$HOME/.config/mise/config.local.toml
machine=$HOME/.config/git/machine.gitconfig
personal=$HOME/.config/mise/dotfiles/.config/git/personal.gitconfig
printf '# %s\n[settings.history]\nsync = "manual"\n' "$marker" >"$local_toml"
public_git=$(printf '# %s\n[include]\n\tpath = %s\n' "$marker" "$personal")
printf '%s\n' "$public_git" >"$machine"
{
	printf '%s\n' "$marker" "$work_name" "$work_email" "$proxy_host"
	git config --file "$personal" --get user.name
	git config --file "$personal" --get user.email
} | sed '/^$/d' >"$lab/secrets.txt"
check secrets_listed "$(wc -l <"$lab/secrets.txt")" 6

# gate <name> [args...]: runs the gate, records its result, and checks its
# output for leaked values and lines that are not key=value. Returns its exit.
# gate_env prefixes the gate command (an env invocation).
gate_env=(env)
gate() {
	local name=$1 rc
	shift
	run "$name" "${gate_env[@]}" "$pwsh" -NoProfile -NonInteractive -File "$lab/home-gate.ps1" -ConversionCommit "$seed" "$@"
	rc=$?
	say "${name}_result" "$(val "$name" gate)"
	say "${name}_failed" "$(val "$name" failed_checks)"
	check "${name}_leaks" "$(grep -cF -f "$lab/secrets.txt" "$out/$name.log")" 0
	check "${name}_non_kv_lines" "$(grep -cvE '^([a-z0-9_]+=.*)?$' "$out/$name.log")" 0
	return "$rc"
}
H=$HOME/.local/state/mise/history/repo.git
test_file=$HOME/.config/zsh/.zshrc
test_stream=home@linux/.config/zsh/.zshrc

# Clean home: passes and leaves the exact pre-gate hash, live and in the head.
pre=$(blob "$test_file")
count=$(git -C "$H" rev-list --count main)
gate clean
check clean_exit "$?" 0
check clean_final_hash_is_pre_gate "$([[ "$(blob "$test_file")" == "$pre" ]] && echo yes || echo no)" yes
check clean_head_blob_is_pre_gate "$([[ "$(git -C "$H" rev-parse "main:$test_stream")" == "$pre" ]] && echo yes || echo no)" yes
check clean_checkpoints_added "$(($(git -C "$H" rev-list --count main) > count))" 1
check clean_test_stream_root "$(val clean test_stream_root)" home@linux
for k in watcher sync_mode conflicts head_contains_conversion systemd_user test_checkpoint_created test_checkpoint_in_stream rollback_dry_run_unchanged rollback_restores_pre_gate_hash undo_restores_edit_hash status_history_problems doctor_history_problems identity_selects_public sanitized_problems; do
	say "clean_$k" "$(val clean "$k")"
done

# Fault: each missing core local input.
for f in config_local_toml:"$local_toml" machine_gitconfig:"$machine"; do
	k=${f%%:*}
	p=${f#*:}
	mv "$p" "$p.aside"
	gate "missing_$k"
	check "missing_${k}_exit" "$?" 1
	check "missing_${k}_reported" "$(val "missing_$k" "local_input_$k")" missing
	check "missing_${k}_test_edit" "$(val "missing_$k" test_edit)" skipped
	mv "$p.aside" "$p"
done

# Fault: a local-input path in history (a ref holding a checkpoint with it).
printf 'synthetic\n' >"$lab/fault-blob.txt"
fault_blob=$(git -C "$H" hash-object -w --no-filters "$lab/fault-blob.txt")
GIT_INDEX_FILE=$lab/fault.index git -C "$H" read-tree main
GIT_INDEX_FILE=$lab/fault.index git -C "$H" update-index --add --cacheinfo "100644,$fault_blob,home/.config/git/machine.gitconfig"
tree=$(GIT_INDEX_FILE=$lab/fault.index git -C "$H" write-tree)
git -C "$H" update-ref refs/heads/lab-fault "$(git -C "$H" commit-tree -p main -m 'lab fault' "$tree")"
gate history_path
check history_path_exit "$?" 1
check history_path_reported "$(val history_path local_input_machine_gitconfig_history_commits)" 1
git -C "$H" update-ref -d refs/heads/lab-fault
gate history_path_cleared
check history_path_cleared_exit "$?" 0

# Fault: an unknown field in a sanitized source (the E178 check). The gate
# names the row, path, and class only, never the field name or value.
pip=$HOME/.config/mise/dotfiles/.config/pip/pip.conf
cp "$pip" "$lab/pip.conf.reviewed"
printf 'proxy = http://%s:3128\n' "$proxy_host" >>"$pip"
gate sanitized_unknown
check sanitized_unknown_exit "$?" 1
check sanitized_unknown_reported "$(val sanitized_unknown sanitized_problem)" 'E121 dotfiles/.config/pip/pip.conf: unknown-field'
check sanitized_unknown_name_printed "$(grep -c proxy "$out/sanitized_unknown.log")" 0
check sanitized_unknown_test_edit "$(val sanitized_unknown test_edit)" skipped
cp "$lab/pip.conf.reviewed" "$pip"

# Fault: no systemd user session (no runtime directory or bus address). The
# gate fails, and -AllowNoSystemdUser reports it without failing.
check systemd_user_in_fixture "$(val clean systemd_user)" degraded
gate_env=(env -u XDG_RUNTIME_DIR -u DBUS_SESSION_BUS_ADDRESS)
gate no_systemd_user
check no_systemd_user_exit "$?" 1
check no_systemd_user_reported "$(val no_systemd_user systemd_user)" unavailable
check no_systemd_user_test_edit "$(val no_systemd_user test_edit)" skipped
gate no_systemd_user_allowed -AllowNoSystemdUser
check no_systemd_user_allowed_exit "$?" 0
check no_systemd_user_allowed_reported "$(val no_systemd_user_allowed systemd_user_unavailable_allowed)" yes
gate_env=(env)

# Identity: a work identity passes in work mode and fails in public mode.
printf '# %s\n[user]\n\tname = %s\n\temail = %s\n' "$marker" "$work_name" "$work_email" >"$machine"
gate work -Identity work
check work_exit "$?" 0
check work_history_commits "$(val work identity_history_commits)" 0
gate work_as_public
check work_as_public_exit "$?" 1
check work_as_public_reported "$(val work_as_public identity_selects_public)" no
printf '%s\n' "$public_git" >"$machine"

# Fault: a conflict. A peer publishes an edit of a shared file; this home
# saves a competing edit and syncs.
peer=$lab/peer
git clone -q "$ex/setup.git" "$peer"
printf 'peer edit\n' >>"$peer/home/.config/git/ignore"
git -C "$peer" commit -q -am 'peer edit'
run peer_push git -C "$peer" push -q origin main
check peer_push_exit "$?" 0
printf 'local edit\n' >>"$HOME/.config/git/ignore"
run conflict_save mise dot save "$HOME/.config/git/ignore"
say conflict_save_exit "$?"
run conflict_sync mise dot sync
say conflict_sync_exit "$?"
gate conflict
check conflict_exit "$?" 1
check conflict_reported "$(val conflict conflicts)" 1
check conflict_test_edit "$(val conflict test_edit)" skipped
check final_hash_is_pre_gate "$([[ "$(blob "$test_file")" == "$pre" ]] && echo yes || echo no)" yes

export HOME=$real_home
say 'done' yes
finish
