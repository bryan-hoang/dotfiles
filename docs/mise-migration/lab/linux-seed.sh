#!/usr/bin/env bash
# Prototype seed run for the Fedora 44 WSL fixture. Materializes the synthetic
# shared and Linux files from ~/lab-in/prototype, installs the generated E011,
# lets stock mise capture the baseline, then builds an append-only conversion
# commit on the exchange copy's main. Results land in ~/lab-out, including the
# advanced setup.git for the host to fast-forward fetch.
set -uo pipefail

in=$HOME/lab-in
out=$HOME/lab-out
lab=$HOME/lab
p=$in/prototype
mkdir -p "$out" "$lab"
results=$out/linux-seed.txt
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

say mise "$(timeout 30 mise --version 2>/dev/null | cut -d' ' -f1)"
say history_sync "$(timeout 30 mise settings get history.sync 2>/dev/null)"

# Synthetic shared and Linux files; Windows rows have no stream here.
n=0
while IFS=$'\t' read -r id var live stream; do
	[[ $var == W ]] && continue
	[[ $id == E011 ]] && continue
	f=$HOME/${live#\~/}
	mkdir -p "$(dirname "$f")"
	printf '# synthetic %s %s\n' "$id" "$stream" >"$f"
	n=$((n + 1))
done <"$p/files.tsv"
mkdir -p "$HOME/.config/mise/conf.d"
cp "$p/dotfiles.toml" "$HOME/.config/mise/conf.d/dotfiles.toml"
# E102's managed destination inside the E138 directory must stay out of history.
printf '# managed copy of E102\n' >"$HOME/.config/nvim/stylua.toml"
say synthetic_files "$((n + 1))"

run paths mise dot paths --json
mapfile -t saves < <(grep -v $'^[^\t]*\tW\t' "$p/roots.tsv" | cut -f3 | sed "s|^~|$HOME|")
say save_roots "${#saves[@]}"
run save mise dot save --description 'Prototype baseline' "${saves[@]}"
run status mise dot status --json

H=$HOME/.local/state/mise/history/repo.git
say history_repo "$([[ -d $H ]] && echo present || echo missing)"
say history_commits "$(git -C "$H" rev-list --count main 2>/dev/null)"
say history_top_level "$(git -C "$H" ls-tree --name-only main 2>/dev/null | paste -sd, -)"
for d in home config home@linux config@linux home@windows config@windows; do
	say "history_files_$d" "$(git -C "$H" ls-tree -r --name-only main -- "$d" 2>/dev/null | wc -l)"
done
say history_modes "$(git -C "$H" ls-tree -r main 2>/dev/null | cut -d' ' -f1 | sort | uniq -c | while read -r k m; do printf '%s:%s\n' "$m" "$k"; done | paste -sd, -)"
say stylua_in_history "$(git -C "$H" ls-tree --name-only main -- home/.config/nvim/stylua.toml | wc -l)"
git -C "$H" show main:.mise-history/format.toml >"$out/format.toml" 2>/dev/null
git -C "$H" show main:.mise-history/manifest.json >"$out/manifest.json" 2>/dev/null
git -C "$H" ls-tree -r main >"$out/history-tree.txt" 2>/dev/null

# Append-only conversion commit: the legacy tree minus exact removals, plus
# every path of mise's checkpoint tree.
c=$lab/conv
git init -q "$c"
git -C "$c" fetch -q "$ex/setup.git" main:refs/legacy
git -C "$c" fetch -q "$H" main:refs/mise
legacy=$(git -C "$c" rev-parse refs/legacy)
export GIT_INDEX_FILE=$lab/conv.index
git -C "$c" read-tree refs/legacy
tr -d '\r' <"$p/removals.txt" | git -C "$c" update-index --force-remove --stdin
overlap=$(git -C "$c" ls-tree -r --name-only refs/mise | grep -cxFf <(git -C "$c" ls-files) || true)
say generated_legacy_overlap "$overlap"
git -C "$c" ls-tree -r --full-tree refs/mise | git -C "$c" update-index --index-info
tree=$(git -C "$c" write-tree)
unset GIT_INDEX_FILE
commit=$(git -C "$c" commit-tree "$tree" -p "$legacy" -m 'Convert main to a mise setup repository (prototype)')
run push git -C "$c" push "$ex/setup.git" "$commit:refs/heads/main"
say conversion_commit "$commit"
say conversion_parent_is_legacy_tip "$([[ "$(git -C "$ex/setup.git" rev-parse main^)" == "$legacy" ]] && echo yes || echo no)"
say conversion_entries "$(git -C "$ex/setup.git" ls-tree -r main | wc -l)"
say conversion_repository_only "$(git -C "$ex/setup.git" ls-tree -r --name-only main | grep -cvE '^(home|config)(@[a-z]+)?/|^\.mise-history/')"
say conversion_gitlinks "$(git -C "$ex/setup.git" ls-tree -r main | grep -c '^160000' || true)"
git -C "$ex/setup.git" ls-tree -r main >"$out/conversion-tree.txt"
cp -a "$ex/setup.git" "$out/setup.git"
say 'done' yes
