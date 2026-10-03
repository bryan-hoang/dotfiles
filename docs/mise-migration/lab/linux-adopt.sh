#!/usr/bin/env bash
# Linux adoption run for the Fedora 44 WSL fixture, on the pinned mise in
# ~/lab-in/bin. Adopts the exchange copy's setup repository in three separate
# HOME directories, each with its own fresh history store:
#   fresh  plain adoption; checks held paths, restored streams byte for byte,
#          repository-only paths, and bootstrap repositories, then the
#          sanitized sources (linux-sanitized.sh)
#   a      differing live file, then save and pull --keep-local
#   b      differing file backed up and moved aside, adoption, then the
#          reviewed local bytes saved as a descendant
# Tools are skipped: the offline lab cannot install the restored tool list.
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
chmod +x "$in/bin/mise"
export PATH=$in/bin:$PATH

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
url=https://github.com/bryan-hoang/dotfiles
adopt=(mise bootstrap --adopt "$url" --yes --skip tools)
tip=$(git -C "$ex/setup.git" rev-parse main)
say tip "$tip"
hist() { printf '%s/.local/state/mise/history/repo.git' "$HOME"; }
head_of() { git -C "$(hist)" rev-parse -q --verify main 2>/dev/null || echo none; }
has_tip() { git -C "$(hist)" merge-base --is-ancestor "$tip" main 2>/dev/null && echo yes || echo no; }
real_home=$HOME
target=.config/git/ignore
stream=home/.config/git/ignore

# E011's Linux managed destinations (#371): one line per declaration with a
# source, "target|source|mode|permissions|profile", joining wrapped lines.
toml_entries() {
	local line e=
	while IFS= read -r line; do
		if [[ $line == '"'* ]]; then
			[[ -n $e ]] && printf '%s\n' "$e"
			e=$line
		elif [[ -n $e && ($line == ' '* || $line == ']'*) ]]; then
			e="$e $line"
		else
			[[ -n $e ]] && printf '%s\n' "$e"
			e=
		fi
	done <"$p/dotfiles.toml"
	[[ -z $e ]] || printf '%s\n' "$e"
}
re='^"~/([^"]+)".* source = "~/([^"]+)", mode = "([a-z-]+)"(, permissions = "([0-7]+)")?.*os = "linux"(, profile = "([a-z-]+)")?'
while IFS= read -r e; do
	[[ $e =~ $re ]] && printf '%s|%s|%s|%s|%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" "${BASH_REMATCH[5]}" "${BASH_REMATCH[7]}"
done < <(toml_entries) >"$lab/destinations.tsv"
declare -A dest=()
while IFS='|' read -r d _; do dest[$d]=1; done <"$lab/destinations.tsv"
say destinations_declared "$(wc -l <"$lab/destinations.tsv")"
same_bytes() { [[ "$(git hash-object --no-filters "$1")" == "$(git hash-object --no-filters "$2")" ]]; }
# dest_ok <file> <source> <mode> <permissions>: approved type, link target,
# mode, and copied bytes.
dest_ok() {
	case $3 in
	symlink) [[ -L $1 && "$(readlink "$1")" == "$HOME/$2" ]] ;;
	copy) [[ -f $1 && ! -L $1 && "$(stat -c %a "$1")" == "${4#0}" ]] && same_bytes "$1" "$HOME/$2" ;;
	template) [[ -f $1 && ! -L $1 && "$(stat -c %a "$1")" == "${4#0}" ]] ;;
	*) false ;;
	esac
}
# check_destinations <label> <capability...>: each declaration selected by the
# capabilities is dest_ok, the others are absent, and no destination is in the
# history head.
check_destinations() {
	local label=$1 ok=0 bad=0 absent=0 stray=0 inhist=0 d s m perm prof f
	shift
	while IFS='|' read -r d s m perm prof; do
		f=$HOME/$d
		if [[ -n $prof && " $* " != *" $prof "* ]]; then
			if [[ -e $f || -L $f ]]; then stray=$((stray + 1)); else absent=$((absent + 1)); fi
		elif dest_ok "$f" "$s" "$m" "$perm"; then
			ok=$((ok + 1))
		else
			bad=$((bad + 1))
			printf '%s\t%s\n' "$label" "$d" >>"$out/destinations_bad.txt"
		fi
		git -C "$(hist)" cat-file -e "main:home/$d" 2>/dev/null && inhist=$((inhist + 1))
		git -C "$(hist)" cat-file -e "main:home@linux/$d" 2>/dev/null && inhist=$((inhist + 1))
	done <"$lab/destinations.tsv"
	say "${label}_destinations_ok" "$ok"
	say "${label}_destinations_wrong" "$bad"
	say "${label}_destinations_gated_absent" "$absent"
	say "${label}_destinations_gated_present" "$stray"
	say "${label}_destinations_in_history" "$inhist"
}
# shellcheck source=/dev/null
source "$in/linux-sanitized.sh"

# fresh
export HOME=$base/fresh
mkdir -p "$HOME/.config/mise"
# Local capabilities, in the excluded input the inventory names.
printf 'env = ["wsl", "vscode-remote"]\n' >"$HOME/.config/mise/miserc.local.toml"
sanitized_inputs
run fresh_adopt "${adopt[@]}"
say fresh_held_paths "$(grep -c 'held:' "$out/fresh_adopt.log")"
ok=0 bad=0 win=0
declare -A live
while IFS=$'\t' read -r _ var l strm; do
	f=$HOME/${l#\~/}
	if [[ $var == W ]]; then
		[[ -e $f ]] && win=$((win + 1))
		continue
	fi
	live[${l#\~/}]=1
	if [[ -f $f && ! -L $f && "$(git hash-object --no-filters "$f")" == "$(git -C "$ex/setup.git" rev-parse "$tip:$strm")" ]]; then ok=$((ok + 1)); else bad=$((bad + 1)); fi
done <"$p/files.tsv"
say fresh_files_restored_exact "$ok"
say fresh_files_wrong_or_missing "$bad"
say fresh_windows_files_present "$win"
restored=0 checked=0
while IFS= read -r path; do
	[[ $path =~ ^(home|config)(@[a-z]+)?/|^\.mise-history/ ]] && continue
	[[ -n ${live[$path]:-} ]] && continue
	[[ -n ${dest[$path]:-} ]] && continue
	[[ -n ${generated[$path]:-} ]] && continue
	checked=$((checked + 1))
	[[ -e $HOME/$path || -L $HOME/$path ]] && restored=$((restored + 1)) && printf '%s\n' "$path" >>"$out/fresh_repository_only_restored.txt"
done < <(git -C "$ex/setup.git" ls-tree -r --name-only "$tip")
say fresh_repository_only_checked "$checked"
say fresh_repository_only_restored "$restored"
c=0
while read -r repo; do
	[[ $repo != "" ]] || continue
	[[ "$(git -C "$HOME/src/github.com/$repo" rev-parse HEAD 2>/dev/null)" == "$(git -C "$ex/mirrors/$repo.git" rev-parse HEAD)" ]] && c=$((c + 1))
done <"$in/repos.txt"
say fresh_repos_at_mirror_head "$c"
say fresh_blesh_contrib_entries "$(find "$HOME/src/github.com/akinomyoga/ble.sh/contrib" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)"
say fresh_head_contains_tip "$(has_tip)"
say fresh_head_parents "$(git -C "$(hist)" log --format='%an:%s' -5 main 2>/dev/null | paste -sd'|' -)"
check_destinations fresh wsl vscode-remote
# Recorded limit: status reports a changed generated output as differs, and
# the next apply overwrites it.
printf 'local edit\n' >>"$HOME/package.json"
run fresh_changed_status mise dot status "$HOME/package.json"
say fresh_changed_generated_status "$(grep -q differs "$out/fresh_changed_status.log" && echo differs || echo other)"
run fresh_changed_apply mise dot apply --yes "$HOME/package.json"
say fresh_changed_generated_after_apply "$(same_bytes "$HOME/package.json" "$HOME/.config/mise/dotfiles/package.json" && echo overwritten || echo kept)"
# E030 (#389): the GnuPG key identifier comes from the guarded local input
# ~/.config/shell/extra.sh; without it the helper refuses to run gpg.
mkdir -p "$HOME/.config/shell"
printf 'export GPG_KEY_ID=lab-key-id\n' >"$HOME/.config/shell/extra.sh"
# shellcheck disable=SC2016
gpg_args=$(timeout 30 bash -c '. "$HOME"/.config/shell/extra.sh; . "$HOME"/.config/shell/functions.sh; gpg() { printf "%s " "$@"; }; import_gpg_key' 2>&1)
say fresh_e030_key_from_local_input "$([[ $gpg_args == *'--edit-key lab-key-id trust'* ]] && echo yes || echo no)"
rm "$HOME/.config/shell/extra.sh"
# shellcheck disable=SC2016
timeout 30 env -u GPG_KEY_ID bash -c '. "$HOME"/.config/shell/functions.sh; gpg() { printf "%s " "$@"; }; import_gpg_key' >"$out/fresh_e030_unset.log" 2>&1
say fresh_e030_unset_key_exit "$?"
say fresh_e030_unset_key_ran_edit "$(grep -c -- '--edit-key' "$out/fresh_e030_unset.log")"
sanitized_checks

# a: preliminary sequence
export HOME=$base/a
mkdir -p "$HOME/$(dirname "$target")"
printf 'local edit A\n' >"$HOME/$target"
run a_adopt "${adopt[@]}"
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
run b_adopt "${adopt[@]}"
adopted=$(head_of)
say b_adopted_head_contains_tip "$(has_tip)"
check_destinations b
say b_adopted_bytes_are_setup "$([[ "$(git hash-object --no-filters "$HOME/$target")" == "$(git -C "$ex/setup.git" rev-parse "$tip:$stream")" ]] && echo yes || echo no)"
cp "$lab/backup-b/ignore" "$HOME/$target"
run b_save mise dot save --description 'Reconcile reviewed local content' "$HOME/$target"
say b_save_parent_is_adopted_head "$([[ "$(git -C "$(hist)" rev-parse main^ 2>/dev/null)" == "$adopted" ]] && echo yes || echo no)"
say b_head_contains_tip "$(has_tip)"
say b_saved_stream_bytes "$(git -C "$(hist)" show "main:$stream" 2>/dev/null)"
say b_origin_tip_unchanged "$([[ "$(git -C "$ex/setup.git" rev-parse main)" == "$tip" ]] && echo yes || echo no)"

export HOME=$real_home
say 'done' yes
