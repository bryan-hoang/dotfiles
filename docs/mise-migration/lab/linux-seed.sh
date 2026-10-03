#!/usr/bin/env bash
# Conversion seed run for the Fedora 44 WSL fixture, on the pinned mise in
# ~/lab-in/bin. Writes the shared and Linux files from the audited-tip blobs
# (synthetic placeholders for canonical sources not written yet), installs the
# generated E011, lets mise capture the baseline, then builds the conversion
# commit on the exchange copy's main: the audited-tip tree minus the removals,
# executables normalized to 100644, the reviewed README and rewrites, plus mise's
# checkpoint tree. Results land in ~/lab-out, including the advanced
# setup.git for the host to fast-forward fetch.
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

say mise_path "$(command -v mise)"
say mise "$(timeout 30 mise --version 2>/dev/null | cut -d' ' -f1)"
say history_sync "$(timeout 30 mise settings get history.sync 2>/dev/null)"
legacy=$(git -C "$ex/setup.git" rev-parse main)
say audited_tip "$legacy"

# Shared and Linux files; Windows rows have no stream in the tip. A source
# that is a regular file at the audited tip takes that blob, written 0644.
declare -A blob
while IFS=$'\t' read -r meta path; do
	read -r mode _ oid <<<"$meta"
	[[ $mode == 100644 || $mode == 100755 ]] && blob[$path]=$oid
done < <(git -C "$ex/setup.git" ls-tree -r --full-tree main)
n=0 real=0
while IFS=$'\t' read -r id var live stream; do
	[[ $var == W ]] && continue
	[[ $id == E011 ]] && continue
	rel=${live#\~/}
	f=$HOME/$rel
	mkdir -p "$(dirname "$f")"
	if [[ -n ${blob[$rel]:-} ]]; then
		git -C "$ex/setup.git" cat-file blob "${blob[$rel]}" >"$f"
		real=$((real + 1))
	else
		printf '# synthetic %s %s\n' "$id" "$stream" >"$f"
	fi
	chmod 0644 "$f"
	n=$((n + 1))
done <"$p/files.tsv"
mkdir -p "$HOME/.config/mise/conf.d"
cp "$p/dotfiles.toml" "$HOME/.config/mise/conf.d/dotfiles.toml"
# E102's managed destination inside the E138 directory must stay out of history.
printf '# managed copy of E102\n' >"$HOME/.config/nvim/stylua.toml"
say seeded_files "$((n + 1))"
say seeded_from_audited_tip "$real"
say seeded_placeholders "$((n - real))"

run paths mise dot paths --json
mapfile -t saves < <(grep -v $'^[^\t]*\tW\t' "$p/roots.tsv" | cut -f3 | sed "s|^~|$HOME|")
say save_roots "${#saves[@]}"
run save mise dot save --description 'Conversion baseline' "${saves[@]}"
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

# Conversion commit with the audited tip as its only parent: the legacy tree
# minus the removals, legacy executables stored 100644, the reviewed README
# and the reviewed rewrites of repository-only files (lab/rewrites/<path>.rewrite
# for setup-root <path>), plus every path of mise's checkpoint tree.
c=$lab/conv
git init -q "$c"
git -C "$c" fetch -q "$ex/setup.git" main:refs/legacy
git -C "$c" fetch -q "$H" main:refs/mise
export GIT_INDEX_FILE=$lab/conv.index
git -C "$c" read-tree refs/legacy
tr -d '\r' <"$p/removals.txt" | git -C "$c" update-index --force-remove --stdin
git -C "$c" ls-files -s | sed -n 's/^100755 /100644 /p' >"$lab/executables.txt"
say legacy_executables_normalized "$(wc -l <"$lab/executables.txt")"
git -C "$c" update-index --index-info <"$lab/executables.txt"
git -C "$c" update-index --cacheinfo "100644,$(git -C "$c" hash-object -w --no-filters "$in/README.md"),README.md"
n=0
while IFS= read -r -d '' f; do
	rel=${f#"$in/rewrites/"}
	git -C "$c" update-index --cacheinfo "100644,$(git -C "$c" hash-object -w --no-filters "$f"),${rel%.rewrite}"
	n=$((n + 1))
done < <(find "$in/rewrites" -type f -name '*.rewrite' -print0)
say legacy_rewrites "$n"
overlap=$(git -C "$c" ls-tree -r --name-only refs/mise | grep -cxFf <(git -C "$c" ls-files) || true)
say generated_legacy_overlap "$overlap"
git -C "$c" ls-tree -r --full-tree refs/mise | git -C "$c" update-index --index-info
tree=$(git -C "$c" write-tree)
unset GIT_INDEX_FILE
commit=$(git -C "$c" commit-tree "$tree" -p "$legacy" -m 'Convert main to a mise setup repository')
run push git -C "$c" push "$ex/setup.git" "$commit:refs/heads/main"
say conversion_commit "$commit"
read -ra parents <<<"$(git -C "$ex/setup.git" rev-list --parents -n 1 main)"
say conversion_parents "$((${#parents[@]} - 1))"
say conversion_parent_is_audited_tip "$([[ "$(git -C "$ex/setup.git" rev-parse main^)" == "$legacy" ]] && echo yes || echo no)"
say conversion_entries "$(git -C "$ex/setup.git" ls-tree -r main | wc -l)"
say conversion_repository_only "$(git -C "$ex/setup.git" ls-tree -r --name-only main | grep -cvE '^(home|config)(@[a-z]+)?/|^\.mise-history/')"
say conversion_gitlinks "$(git -C "$ex/setup.git" ls-tree -r main | grep -c '^160000' || true)"
git -C "$ex/setup.git" ls-tree -r main >"$out/conversion-tree.txt"
cp -a "$ex/setup.git" "$out/setup.git"
say 'done' yes
