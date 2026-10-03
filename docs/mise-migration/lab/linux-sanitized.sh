# shellcheck shell=bash disable=SC2154,SC2034 # shares variables with linux-adopt.sh
# Sourced by linux-adopt.sh (uses say, run, hist, head_of, ex, in, lab, out).
# Proves the SANITIZED sources E112 to E128 in the fresh HOME:
#   sanitized_inputs  before adoption: one synthetic application-local input
#                     per source, each carrying a random marker value
#   sanitized_checks  after adoption: every generated destination is its
#                     adopted source with the local input spliced in, mise
#                     reports a changed destination as differs, an unknown
#                     source field blocks the explicit save, and the marker
#                     reaches no history object, setup object, or lab output
s=$in/sanitized.py
mark=LOCALVALUE$(od -An -N8 -tx1 /dev/urandom | tr -d ' \n')

# One local-only field per source. Inputs append after the source; the JSONC
# input is a member list spliced before the closing brace.
local_input() {
	case $1 in
		.config/.curlrc) printf 'user = "lab:%s"\n' "$mark" ;;
		.config/bundle/config) printf 'BUNDLE_LAB__INVALID: "%s"\n' "$mark" ;;
		.config/gem/gemrc) printf ':lab_api_key: %s\n' "$mark" ;;
		.config/gh/config.yml) printf 'hosts:\n  lab.invalid:\n    user: %s\n' "$mark" ;;
		.config/litecli/config) printf '[favorite_queries]\nlab = select %s\n' "$mark" ;;
		.config/mycli/myclirc) printf '[alias_dsn]\nlab = mysql://%s@lab.invalid/db\n' "$mark" ;;
		.config/mysql/my.cnf) printf '[client]\nuser = %s\n' "$mark" ;;
		.config/npm/npmrc) printf '//registry.lab.invalid/:_authToken=%s\n' "$mark" ;;
		.config/pgcli/config) printf '[alias_dsn]\nlab = postgresql://%s@lab.invalid/db\n' "$mark" ;;
		.config/pip/pip.conf) printf 'index-url = https://%s.lab.invalid/simple\n' "$mark" ;;
		.config/pnpm/config.yaml) printf '"//registry.lab.invalid/:_authToken": %s\n' "$mark" ;;
		.config/pypoetry/config.toml) printf '[http-basic.lab]\nusername = "%s"\n' "$mark" ;;
		.config/uv/uv.toml) printf 'index-url = "https://%s.lab.invalid/simple"\n' "$mark" ;;
		.config/wget/wgetrc) printf 'header = Authorization: Bearer %s\n' "$mark" ;;
		.config/youtube-dl/config | .config/yt-dlp/config) printf -- '--username %s\n' "$mark" ;;
		.config/opencode/opencode.jsonc) printf '\t"provider": { "lab": { "options": { "apiKey": "%s" } } },\n' "$mark" ;;
		*) return 1 ;;
	esac
}

# Generated destinations; some share a path with a legacy repository-only
# file, so linux-adopt.sh skips them when it looks for restored legacy files.
rels=()
declare -A generated
while IFS=$'\t' read -r id path _; do
	[[ $id == id ]] && continue
	rels+=("${path#dotfiles/}")
	generated[${path#dotfiles/}]=1
done <"$in/sanitized-allowlist.tsv"

sanitized_inputs() {
	local r
	for r in "${rels[@]}"; do
		mkdir -p "$(dirname "$HOME/$r")"
		local_input "$r" >"$HOME/$r.local"
	done
	say sanitized_rows "${#rels[@]}"
	say sanitized_local_inputs_with_marker "$(for r in "${rels[@]}"; do grep -l "$mark" "$HOME/$r.local"; done 2>/dev/null | wc -l)"
}

# Expected destination: the source with the Tera tags of its two include lines
# replaced by nothing and by a newline plus the local input.
expected() {
	python3 - "$@" <<'EOF'
import re, sys
from pathlib import Path
src, local = sys.argv[1:]
text = re.sub(rb"\{% set local[^\n]*%\}", b"", Path(src).read_bytes())
tags = re.search(rb"\{% if local is file %\}[^\n]*\{% endif %\}", text)[0]
sys.stdout.buffer.write(text.replace(tags, b"\n" + Path(local).read_bytes()))
EOF
}

sanitized_checks() {
	local root=$HOME/.config/mise r n ok=0 parse
	n=$(for r in "${rels[@]}"; do [[ -f $HOME/$r ]] && echo; done | wc -l)
	say sanitized_destinations_after_adopt "$n"
	# Fallback if the adoption's dotfiles phase predates the restored E011.
	((n == ${#rels[@]})) || run sanitized_apply mise dot apply --yes
	for r in "${rels[@]}"; do
		if [[ -f $HOME/$r ]] && cmp -s "$HOME/$r" <(expected "$root/dotfiles/$r" "$HOME/$r.local") && [[ "$(grep -c "$mark" "$HOME/$r")" == 1 ]]; then
			ok=$((ok + 1))
		else
			printf '%s\n' "$r" >>"$out/sanitized_generated_wrong.txt"
		fi
	done
	say sanitized_generated_from_source_and_local "$ok"
	parse=$(
		python3 - "$HOME" <<'EOF'
import configparser, json, re, sys, tomllib
from pathlib import Path
h = Path(sys.argv[1], ".config")
ini = lambda f: configparser.ConfigParser(strict=True, allow_no_value=True, interpolation=None).read_string((h / f).read_text())
[ini(f) for f in ["litecli/config", "mycli/myclirc", "mysql/my.cnf", "pgcli/config", "pip/pip.conf"]]
[tomllib.loads((h / f).read_text()) for f in ["pypoetry/config.toml", "uv/uv.toml"]]
t = re.sub(r"(?m)^\s*//.*$", "", (h / "opencode/opencode.jsonc").read_text())
print(7 + ("provider" in json.loads(re.sub(r",(\s*[}\]])", r"\1", t))))
EOF
	)
	say sanitized_generated_parse_ok "$parse"
	run sanitized_status mise dot status --json
	say sanitized_status_applied "$(grep -c '"state": "applied"' "$out/sanitized_status.log")"

	# A changed destination: mise reports it differs before the next apply.
	printf '# local edit\n' >>"$HOME/.config/uv/uv.toml"
	run sanitized_status_changed mise dot status --json "$HOME/.config/uv/uv.toml"
	say sanitized_changed_destination_differs "$(grep -c '"state": "differs"' "$out/sanitized_status_changed.log")"

	# An unknown field in a sanitized source blocks the explicit save.
	local pip=$root/dotfiles/.config/pip/pip.conf before
	cp "$pip" "$lab/pip.conf.reviewed"
	printf 'proxy = http://%s.lab.invalid:3128\n' "$mark" >>"$pip"
	before=$(head_of)
	run sanitized_unknown_field_save python3 "$s" save "$root" "$pip"
	say sanitized_unknown_field_reported "$(grep -c 'E121 dotfiles/.config/pip/pip.conf: unknown field global.proxy' "$out/sanitized_unknown_field_save.log")"
	say sanitized_unknown_field_head_unchanged "$([[ "$(head_of)" == "$before" ]] && echo yes || echo no)"
	cp "$lab/pip.conf.reviewed" "$pip"
	run sanitized_reviewed_save python3 "$s" save "$root" "$pip"

	# No local-input value in history, the setup repository, or any lab output.
	say sanitized_value_in_history_objects "$(git -C "$(hist)" cat-file --batch-all-objects --batch 2>/dev/null | grep -ac "$mark")"
	say sanitized_value_in_setup_objects "$(git -C "$ex/setup.git" cat-file --batch-all-objects --batch | grep -ac "$mark")"
	say sanitized_value_in_lab_out "$(grep -rl "$mark" "$out" | wc -l)"
}
