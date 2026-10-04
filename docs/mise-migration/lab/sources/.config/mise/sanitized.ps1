#Requires -Version 7.0
# Sanitized sources check (E178; review code SANITIZED, E112 to E128).
#
# Each source under <this directory>/dotfiles/<HOME-relative path> may hold
# only the fields its row below allows, plus one include (two comment lines).
# The source is a mise template: E011 renders it to HOME/<HOME-relative path>,
# and the include splices in the excluded application-local input
# HOME/<HOME-relative path>.local when it exists. Output names the row, the
# source path, and the problem class only, never a field name or value: an
# unknown field name can itself be private (a host or token key).
#
#   pwsh -File sanitized.ps1 check            exit 1 on any problem
#   pwsh -File sanitized.ps1 save ARGS...     check, then mise dot save ARGS
#   ... | pwsh -File sanitized.ps1 topgrade   prints true when stdin is true
#                                             and the check passes, else false
#
# The home gate runs check; the E092 Topgrade status check pipes its verdict
# through topgrade. Problem classes: missing, include, template, unknown-field,
# unparsed, unreviewed-pinned-value.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# id, path, format, allowed fields, pinned FIELD=VALUE pairs (every value of a
# pinned field must be listed), and what stays in the local input.
$Allowlist = @'
id	path	format	allow	pin	local
E112	dotfiles/.config/.curlrc	line	location referer		user, proxy, header, cookie, url, cert, and netrc options
E113	dotfiles/.config/bundle/config	yaml	BUNDLE_IGNORE_FUNDING_REQUESTS		registry mirrors and BUNDLE_<host> credentials
E114	dotfiles/.config/gem/gemrc	yaml	gem update_sources sources bulk_threshold benchmark	sources=http://rubygems.org/	authenticated or private sources and API keys
E115	dotfiles/.config/gh/config.yml	yaml	version git_protocol		hosts, users, and tokens
E116	dotfiles/.config/litecli/config	ini	main.multi_line main.destructive_warning main.log_file main.log_level main.table_format main.syntax_style main.key_bindings main.wider_completion_menu main.autocompletion main.prompt main.prompt_continuation main.show_bottom_toolbar main.less_chatty main.login_path_as_host main.auto_vertical_output main.keyword_casing main.enable_pager colors.*		favorite_queries section
E117	dotfiles/.config/mycli/myclirc	ini	main.smart_completion main.multi_line main.destructive_warning main.log_file main.log_level main.timing main.table_format main.syntax_style main.key_bindings main.wider_completion_menu main.prompt_continuation main.less_chatty main.login_path_as_host main.auto_vertical_output main.keyword_casing main.enable_pager colors.*		favorite_queries and alias_dsn sections; hosts, users, and passwords
E118	dotfiles/.config/mysql/my.cnf	ini	mysql.prompt mysql.auto-rehash mysql.binary-as-hex mysql.default-character-set mysql.silent		client section: user, password, host, port, socket
E119	dotfiles/.config/npm/npmrc	ini	cache color fund init-module init-version logs-dir min-release-age prefix preid save-exact sign-git-commit sign-git-tag		init-author-email, init-author-name, init-author-url; registry, scoped registries, and auth tokens
E120	dotfiles/.config/pgcli/config	ini	main.smart_completion main.wider_completion_menu main.multi_line main.multi_line_mode main.destructive_warning main.expand main.auto_expand main.generate_aliases main.log_file main.keyword_casing main.casing_file main.generate_casing_file main.case_column_headers main.history_file main.log_level main.asterisk_column_order main.qualify_columns main.search_path_filter main.timing main.show_bottom_toolbar main.table_format main.syntax_style main.vi main.on_error main.row_limit main.max_field_width main.less_chatty main.prompt main.min_num_menu_lines main.multiline_continuation_char main.null_string main.enable_pager main.keyring colors.* data_formats.decimal data_formats.float		named queries and alias_dsn sections
E121	dotfiles/.config/pip/pip.conf	ini	global.break-system-packages		index-url, extra-index-url, trusted-host, proxy, cert, client-cert
E122	dotfiles/.config/pnpm/config.yaml	yaml	enableGlobalVirtualStore savePrefix trustPolicy updateNotifier		registry, scoped registries, auth tokens, proxies
E123	dotfiles/.config/pypoetry/config.toml	toml	virtualenvs.in-project virtualenvs.prefer-active-python		repositories, http-basic, pypi-token, certificates
E124	dotfiles/.config/uv/uv.toml	toml	exclude-newer preview		index, index-url, extra-index-url, find-links, allow-insecure-host, proxies
E125	dotfiles/.config/wget/wgetrc	ini	timestamping prefer_family localencoding remoteencoding httpsonly progress quiet no_parent timeout tries retry_connrefused follow_ftp adjust_extension robots server_response content_disposition		header (identity and every other header), hsts-file; user, password, proxies, cookies
E126	dotfiles/.config/youtube-dl/config	args	external-downloader output restrict-filenames format write-sub write-auto-sub sub-format sub-lang add-metadata		username, password, netrc, cookies, proxy, private output paths
E127	dotfiles/.config/yt-dlp/config	args	external-downloader output restrict-filenames		username, password, netrc, cookies, cookies-from-browser, proxy, private output paths
E128	dotfiles/.config/opencode/opencode.jsonc	jsonc	$schema autoupdate lsp formatter.*.command formatter.*.extensions mcp.*.type mcp.*.command mcp.*.url mcp.*.enabled plugin permission.bash.* permission.external_directory.* websearch.provider	mcp.*.url=https://mcp.exa.ai/mcp mcp.*.url=https://mcp.mdn.mozilla.net/	provider, model, small_model, enterprise, mcp headers, oauth, and environment
'@

$Tera = '{{', '{%', '{#'

# A field is a path of segments; ,@(...) keeps one array from unrolling.
function Split-Field([string]$s) { , [string[]]($s -split '\.') }

function Get-Row {
	foreach ($line in ($Allowlist -split "`n" | Select-Object -Skip 1)) {
		$id, $path, $fmt, $allow, $pin, $null = $line -split "`t"
		$pins = [ordered]@{}
		foreach ($p in -split $pin) {
			$field, $value = $p -split '=', 2
			if (-not $pins.Contains($field)) { $pins[$field] = [Collections.Generic.HashSet[string]]::new() }
			$null = $pins[$field].Add($value)
		}
		[pscustomobject]@{ Id = $id; Path = $path; Format = $fmt; Allow = @(foreach ($a in -split $allow) { Split-Field $a }); Pins = $pins }
	}
}

# Two comment lines, so the source still parses; they render as two empty
# comments followed by the local input on its own lines.
function Get-Include([string]$path, [string]$fmt) {
	$c = if ($fmt -eq 'jsonc') { "`t// " } else { '# ' }
	$local = '/' + $path.Substring('dotfiles/'.Length) + '.local'
	"$c{% set local = env.HOME ~ `"$local`" %}`n" +
	"$c{% if local is file %}{{ `"\n`" ~ read_file(path=local) }}{% endif %}`n"
}

# Every JSONC object key as a path, with the offset just past the key; array
# elements add a "[]" segment. Throws on unbalanced or unterminated input.
function Get-JsoncKey([string]$text) {
	$i = 0
	$stack = [Collections.Generic.List[char]]::new()
	$path = [Collections.Generic.List[string]]::new()
	$expect = $false
	while ($i -lt $text.Length) {
		$c = $text[$i]
		if ($c -eq '"') {
			$j = $i + 1
			while ($true) {
				if ($j -ge $text.Length) { throw 'unterminated string' }
				if ($text[$j] -eq '"') { break }
				$j += if ($text[$j] -eq '\') { 2 } else { 1 }
			}
			if ($stack.Count -and $stack[$stack.Count - 1] -eq '{' -and $expect) {
				$path[$path.Count - 1] = $text.Substring($i + 1, $j - $i - 1)
				$expect = $false
				[pscustomobject]@{ Field = [string[]]$path.ToArray(); End = $j + 1 }
			}
			$i = $j + 1
			continue
		}
		if ([string]::CompareOrdinal($text, $i, '//', 0, 2) -eq 0) {
			$i = $text.IndexOf("`n", $i)
			if ($i -lt 0) { break }
			continue
		}
		if ([string]::CompareOrdinal($text, $i, '/*', 0, 2) -eq 0) {
			$k = $text.IndexOf('*/', $i)
			if ($k -lt 0) { throw 'unterminated comment' }
			$i = $k + 2
			continue
		}
		if ($c -in '{', '[') {
			$stack.Add($c)
			$path.Add($(if ($c -eq '[') { '[]' } else { $null }))
			$expect = $c -eq '{'
		}
		elseif ($c -in '}', ']') {
			if (-not $stack.Count) { throw 'unbalanced' }
			$stack.RemoveAt($stack.Count - 1)
			$path.RemoveAt($path.Count - 1)
		}
		elseif ($c -eq ',') {
			if (-not $stack.Count) { throw 'unbalanced' }
			$expect = $stack[$stack.Count - 1] -eq '{'
		}
		$i++
	}
}

function Get-Line([string]$text) { $text -split '\r?\n|\r' }

# Field paths in source order. Unparsable lines are fields too, so they fail
# closed.
function Get-Field([string]$fmt, [string]$text) {
	$unparsed = Split-Field '<unparsed>'
	if ($fmt -eq 'jsonc') {
		try { foreach ($k in @(Get-JsoncKey $text)) { , $k.Field } }
		catch { , $unparsed }
		return
	}
	$n = 0
	$section = $null
	foreach ($raw in Get-Line $text) {
		$s = $raw.Trim()
		if (-not $s -or $s[0] -eq '#' -or ($fmt -eq 'ini' -and $s[0] -eq ';')) { continue }
		if ($fmt -eq 'yaml' -and $s -eq '---') { continue }
		if ($fmt -eq 'yaml' -and $raw[0] -in ' ', "`t", '-') {
			# Nested or list lines belong to the field above; leading ones fail.
			if (-not $n) { $n++; , $unparsed }
			continue
		}
		$n++
		if ($fmt -in 'line', 'args') { , [string[]]@(($s.TrimStart('-') -split '[\s=:]', 2)[0]) }
		elseif ($fmt -eq 'yaml') {
			if ($raw -match '^([^:#]+):(\s|$)') { , [string[]]@($Matches[1].Trim().Trim("'", '"')) } else { , $unparsed }
		}
		elseif ($s.StartsWith('[')) {
			$section = $s.Trim('[', ']').Trim()
			, [string[]]@($section)
		}
		else {
			$key = ($s -split $(if ($fmt -eq 'ini') { '[=:]' } else { '=' }), 2)[0].Trim()
			if ($null -eq $section) { , [string[]]@($key) } else { , [string[]]@($section, $key) }
		}
	}
}

# A field shorter than a matching pattern is a container on its way there.
function Test-Allowed([string[]]$field, $patterns) {
	foreach ($p in $patterns) {
		if ($field.Count -gt $p.Count) { continue }
		$ok = $true
		for ($k = 0; $k -lt $field.Count; $k++) {
			if ($p[$k] -cne '*' -and $p[$k] -cne $field[$k]) { $ok = $false; break }
		}
		if ($ok) { return $true }
	}
	$false
}

function Test-Match([string[]]$field, [string[]]$pattern) { $field.Count -eq $pattern.Count -and (Test-Allowed $field @(, $pattern)) }

# Every value of the fields matching pattern. Anything that is not a plain
# string (JSONC) or a scalar list item (YAML) is $null, so it fails closed.
function Get-Value([string]$fmt, [string]$text, [string[]]$pattern) {
	if ($fmt -eq 'jsonc') {
		$re = [regex]'\G\s*:\s*"((?:[^"\\]|\\.)*)"'
		try {
			foreach ($k in @(Get-JsoncKey $text)) {
				if (Test-Match $k.Field $pattern) {
					$m = $re.Match($text, $k.End)
					if ($m.Success) { $m.Groups[1].Value } else { $null }
				}
			}
		}
		catch { $null }
		return
	}
	$inside = $false
	foreach ($raw in Get-Line $text) {
		$s = $raw.Trim()
		if (-not $s -or $s[0] -eq '#' -or $s -eq '---') { continue }
		if ($raw[0] -notin ' ', "`t", '-') {
			$key, $tail = $raw -split ':', 2
			$inside = Test-Match ([string[]]@($key.Trim().Trim("'", '"'))) $pattern
			if ($inside -and $tail -and $tail.Trim()) { $tail.Trim().Trim("'", '"') }
		}
		elseif ($inside) {
			if ($raw -match '^\s*-\s+(\S+)\s*$') { $Matches[1].Trim("'", '"') } else { $null }
		}
	}
}

function Get-Problem($row, [string]$text) {
	$inc = Get-Include $row.Path $row.Format
	$parts = $text -csplit [regex]::Escape($inc)
	if ($parts.Count -ne 2) { 'include' }
	$body = $parts -join ''
	if (@($Tera | Where-Object { $body.Contains($_) }).Count) { 'template' }
	foreach ($f in @(Get-Field $row.Format $body)) {
		if ($f.Count -eq 1 -and $f[0] -ceq '<unparsed>') { 'unparsed' }
		elseif (-not (Test-Allowed $f $row.Allow)) { 'unknown-field' }
	}
	foreach ($field in $row.Pins.Keys) {
		foreach ($v in @(Get-Value $row.Format $body (Split-Field $field))) {
			if ($null -eq $v -or -not $row.Pins[$field].Contains($v)) { 'unreviewed-pinned-value' }
		}
	}
}

# Prints one line per problem and a summary; returns $true when clean.
function Test-Sanitized {
	$bad = 0
	$rows = @(Get-Row)
	foreach ($row in $rows) {
		$src = Join-Path $PSScriptRoot $row.Path
		$found = @(if (Test-Path -LiteralPath $src -PathType Leaf) { Get-Problem $row ([IO.File]::ReadAllText($src)) } else { 'missing' })
		foreach ($p in $found) { "$($row.Id) $($row.Path): $p" }
		$bad += $found.Count
	}
	"sanitized_sources=$($rows.Count) problems=$bad"
	$bad -eq 0
}

$verb = $args | Select-Object -First 1
$rest = @($args | Select-Object -Skip 1)
switch ($verb) {
	'check' {
		$r = @(Test-Sanitized)
		$r | Select-Object -SkipLast 1
		exit [int](-not $r[-1])
	}
	'save' {
		$r = @(Test-Sanitized)
		$r | Select-Object -SkipLast 1
		if (-not $r[-1]) { 'save blocked: a sanitized source has a problem'; exit 1 }
		& mise dot save @rest
		exit $LASTEXITCODE
	}
	'topgrade' {
		$ok = $false
		try {
			# Letters only: drops a byte order mark, line ends, and any encoding
			# padding a Windows PowerShell pipe adds.
			$stdin = [Console]::In.ReadToEnd() -creplace '[^a-z]', ''
			$ok = $stdin -ceq 'true' -and (@(Test-Sanitized)[-1])
		}
		catch { $ok = $false }
		if ($ok) { 'true'; exit 0 } else { 'false'; exit 1 }
	}
	default { throw 'usage: sanitized.ps1 check | save ARGS... | topgrade' }
}
