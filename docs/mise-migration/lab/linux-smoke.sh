#!/usr/bin/env bash
# Lab smoke test for the Fedora 44 WSL fixture. The host runner starts it as
# the fixture user inside `unshare --user --map-current-user --net`, with
# ~/lab-in holding these scripts and a copy of the exchange. It writes
# key=value results to ~/lab-out/linux-smoke.txt and creates no setup history.
set -euo pipefail

in=$HOME/lab-in
out=$HOME/lab-out
lab=$HOME/lab
mkdir -p "$out" "$lab"/{config,data,state,cache,tmp}
results=$out/linux-smoke.txt
: >"$results"
say() { printf '%s=%s\n' "$1" "$2" | tee -a "$results"; }

touch "$lab/.start"

export MISE_CONFIG_DIR=$lab/config
export MISE_GLOBAL_CONFIG_FILE=$lab/config/config.toml
export MISE_DATA_DIR=$lab/data
export MISE_STATE_DIR=$lab/state
export MISE_CACHE_DIR=$lab/cache
export MISE_TMP_DIR=$lab/tmp
export TMPDIR=$lab/tmp
export MISE_HISTORY_SYNC=manual
export MISE_AUTO_INSTALL=0
export GIT_CONFIG_NOSYSTEM=1
export GIT_CONFIG_GLOBAL=$lab/gitconfig
export GIT_TERMINAL_PROMPT=0

ex=$in/exchange

gh=https://github.com
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

say uid "$(id -u)"
say links "$(ip -o link | cut -d: -f2 | tr -d ' ' | paste -sd, -)"
if timeout 5 bash -c 'exec 3<>/dev/tcp/1.1.1.1/443' 2>/dev/null; then say outbound reachable; else say outbound blocked; fi
say git "$(git --version | cut -d' ' -f3)"
say mise "$(timeout 30 mise --version 2>/dev/null | cut -d' ' -f1)"
say history_sync "$(timeout 30 mise settings get history.sync 2>/dev/null)"

want=$(git -C "$ex/mirrors/dracula/git.git" rev-parse HEAD)
got=$(timeout 30 git ls-remote https://github.com/dracula/git HEAD | cut -f1 || true)
say approved_url_resolves_to_mirror "$([[ $got == "$want" ]] && echo yes || echo no)"

got=$(timeout 30 git ls-remote ssh://git@github.com/bryan-hoang/dotfiles refs/heads/main | cut -f1 || true)
say origin_resolves_to_setup_remote "$([[ $got == "$(git -C "$ex/setup.git" rev-parse main)" ]] && echo yes || echo no)"

err=$(timeout 30 git ls-remote "$gh/example/not-approved" 2>&1 || true)
case "$err" in
*"transport 'https' not allowed"*) say unapproved_url refused ;;
*) say unapproved_url "unexpected: ${err:0:120}" ;;
esac

stray=$(find "$HOME" -xdev -newer "$lab/.start" -not -path "$lab/*" -not -path "$lab" \
	-not -path "$out/*" -not -path "$out" -not -path "$in/*" -not -path "$in" -print 2>/dev/null | head -n 5 | paste -sd, -)
say writes_outside_lab_roots "${stray:-none}"
say history_repo_present "$([[ -e "$lab/state/history" ]] && echo yes || echo no)"
say 'done' yes
