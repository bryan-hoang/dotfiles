#!/usr/bin/env bash
# Prototype Linux adoption run for the Fedora 44 WSL fixture. Adopts the
# exchange copy's setup repository with stock mise in three separate HOME
# directories, each with its own fresh history store:
#   fresh  plain adoption; checks restored streams and bootstrap repositories
#   a      differing live file, then save and pull --keep-local
#   b      differing file backed up and moved aside, adoption, then the
#          reviewed local bytes saved as a descendant
# Nothing is published. Results land in ~/lab-out/linux-adopt.txt.
set -uo pipefail

in=$HOME/lab-in
out=$HOME/lab-out
lab=$HOME/lab
base=$HOME/homes
p=$in/prototype
mkdir -p "$out" "$lab" "$base"
results=$out/linux-adopt.txt
: >"$results"
say() { printf '%s=%s\n' "$1" "$2" | tee -a "$results"; }
run() {
	local name=$1
	shift
	timeout 300 "$@" >"$out/$name.log" 2>&1
	local rc=$?
	say "${name}_exit" "$rc"
	return "$rc"
}

unset XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME XDG_CACHE_HOME
export MISE_HISTORY_SYNC=manual
export MISE_AUTO_INSTALL=0
export GIT_CONFIG_NOSYSTEM=1
export GIT_CONFIG_GLOBAL=$lab/gitconfig
export GIT_TERMINAL_PROMPT=0

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

url=https://github.com/bryan-hoang/dotfiles
tip=$(git -C "$ex/setup.git" rev-parse main)
say tip "$tip"
hist() { printf '%s/.local/state/mise/history/repo.git' "$HOME"; }
head_of() { git -C "$(hist)" rev-parse -q --verify main 2>/dev/null || echo none; }
has_tip() { git -C "$(hist)" merge-base --is-ancestor "$tip" main 2>/dev/null && echo yes || echo no; }
real_home=$HOME
target=.config/git/ignore
stream=home/.config/git/ignore

# fresh
export HOME=$base/fresh
mkdir -p "$HOME"
run fresh_adopt mise bootstrap --adopt "$url" --yes
ok=0 bad=0 win=0
while IFS=$'\t' read -r id var live strm; do
	f=$HOME/${live#\~/}
	if [[ $var == W ]]; then
		[[ -e $f ]] && win=$((win + 1))
		continue
	fi
	if [[ $id == E011 ]]; then want=$(cat "$p/dotfiles.toml"); else want="# synthetic $id $strm"; fi
	if [[ -f $f ]] && [[ "$(cat "$f")" == "$want" ]]; then ok=$((ok + 1)); else bad=$((bad + 1)); fi
done <"$p/files.tsv"
say fresh_files_restored_exact "$ok"
say fresh_files_wrong_or_missing "$bad"
say fresh_windows_files_present "$win"
say fresh_repository_only_restored "$(for f in README.md .gitmodules .bashrc .config/X11/xinitrc .config/mise/conf.d/fnox.toml; do [[ -e "$HOME/$f" ]] && printf '%s ' "$f"; done)"
c=0
while read -r repo; do
	[[ $repo != "" ]] || continue
	[[ "$(git -C "$HOME/src/github.com/$repo" rev-parse HEAD 2>/dev/null)" == "$(git -C "$ex/mirrors/$repo.git" rev-parse HEAD)" ]] && c=$((c + 1))
done <"$in/repos.txt"
say fresh_repos_at_mirror_head "$c"
say fresh_blesh_contrib_entries "$(find "$HOME/src/github.com/akinomyoga/ble.sh/contrib" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)"
say fresh_head_contains_tip "$(has_tip)"
say fresh_head_parents "$(git -C "$(hist)" log --format='%an:%s' -5 main 2>/dev/null | paste -sd'|' -)"

# a: preliminary sequence
export HOME=$base/a
mkdir -p "$HOME/$(dirname "$target")"
printf 'local edit A\n' >"$HOME/$target"
run a_adopt mise bootstrap --adopt "$url" --yes
say a_local_head_after_adopt "$(head_of)"
say a_declaration_present "$([[ -f "$HOME/.config/mise/conf.d/dotfiles.toml" ]] && echo yes || echo no)"
run a_save mise dot save "$HOME/$target"
say a_local_head_after_save "$(head_of)"
run a_keep_local mise dot pull --keep-local "$HOME/$target"
say a_local_head_after_keep_local "$(head_of)"
say a_head_contains_tip "$(has_tip)"
say a_live_bytes "$(cat "$HOME/$target")"

# b: confirmed workflow
export HOME=$base/b
mkdir -p "$HOME/$(dirname "$target")" "$lab/backup-b"
printf 'local edit B\n' >"$HOME/$target"
cp -p "$HOME/$target" "$lab/backup-b/ignore"
mv "$HOME/$target" "$lab/backup-b/ignore.aside"
run b_adopt mise bootstrap --adopt "$url" --yes
adopted=$(head_of)
say b_adopted_head_contains_tip "$(has_tip)"
say b_adopted_bytes_are_setup "$([[ "$(cat "$HOME/$target")" == "# synthetic E020 $stream" ]] && echo yes || echo no)"
cp "$lab/backup-b/ignore" "$HOME/$target"
run b_save mise dot save --description 'Reconcile reviewed local content' "$HOME/$target"
say b_save_parent_is_adopted_head "$([[ "$(git -C "$(hist)" rev-parse main^ 2>/dev/null)" == "$adopted" ]] && echo yes || echo no)"
say b_head_contains_tip "$(has_tip)"
say b_saved_stream_bytes "$(git -C "$(hist)" show "main:$stream" 2>/dev/null)"
say b_origin_tip_unchanged "$([[ "$(git -C "$ex/setup.git" rev-parse main)" == "$tip" ]] && echo yes || echo no)"

export HOME=$real_home
say 'done' yes
