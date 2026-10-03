# Expands the approved enrollment inventory into the prototype's plan files.
# Reads only inventory rows and Git path names at the audited tip, never file
# contents. Writes to lab\prototype\:
#   roots.tsv              id, variant, live root (one per enrollment root)
#   files.tsv              id, variant, live file, selected stream path
#   dotfiles.toml          E011: track declarations, history exclude, repos
#   removals.txt           legacy tip paths the conversion commit drops
param([Parameter(Mandatory)][string]$Tip)
$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..\..\..')
$inv = Join-Path $PSScriptRoot '..\matrices\10-approved-enrollment-inventory.md'
$out = Join-Path $PSScriptRoot 'prototype'
New-Item -ItemType Directory -Path $out -Force | Out-Null
$env:MISE_AUTO_INSTALL = '0'

function Block([string]$tag) {
	$lines = Get-Content -LiteralPath $inv
	$s = [array]::IndexOf($lines, "<!-- ${tag}:start -->")
	$e = [array]::IndexOf($lines, "<!-- ${tag}:end -->")
	if ($s -lt 0 -or $e -lt $s) { throw "block not found: $tag" }
	$lines[($s + 1)..($e - 1)] | Where-Object { $_ -and $_ -notmatch '^```' }
}

$legacy = git -C $root ls-tree -r --full-tree $Tip
if ($LASTEXITCODE) { throw "cannot list $Tip" }
$roots = foreach ($line in Block 'enrollment-roots' | Where-Object { $_ -match '^\|\s*`?E\d{3}`?\s' }) {
	$f = @($line.Trim().Trim('|') -split '\|' | ForEach-Object { $_.Trim().Trim('`') })
	if ($f.Count -ne 12) { throw "bad row: $line" }
	[pscustomobject]@{ Id = $f[0]; Source = $f[1]; Enroll = $f[2]; Stream = $f[3]; Kind = $f[4]; Variant = $f[5]; Autosave = $f[6]; Destination = $f[8]; Review = $f[9] }
}

$files = foreach ($r in $roots) {
	if ($r.Kind -eq 'exact') { [pscustomobject]@{ Id = $r.Id; Variant = $r.Variant; Live = $r.Source; Stream = $r.Stream }; continue }
	# Directory roots: descendants are the legacy regular files below the same
	# HOME-relative path; the managed Stylua link is excluded (E102).
	$rel = $r.Source.Substring(2)
	foreach ($l in $legacy) {
		$mode, $null, $null = ($l -split "`t")[0] -split ' '
		$p = ($l -split "`t", 2)[1]
		if ($p.StartsWith("$rel/") -and $mode -eq '100644') {
			[pscustomobject]@{ Id = $r.Id; Variant = $r.Variant; Live = "~/$p"; Stream = $r.Stream + $p.Substring($rel.Length) }
		}
	}
}

$lf = New-Object Text.UTF8Encoding $false
function Save([string]$name, [string[]]$lines) { [IO.File]::WriteAllText((Join-Path $out $name), (($lines -join "`n") + "`n"), $lf) }

Save 'roots.tsv' ($roots | ForEach-Object { "$($_.Id)`t$($_.Variant)`t$($_.Source)" })
Save 'files.tsv' ($files | ForEach-Object { "$($_.Id)`t$($_.Variant)`t$($_.Live)`t$($_.Stream)" })

$sel = @{ S = ''; W = ', variants = [{ os = "windows" }]'; L = ', variants = [{ os = "linux" }]' }
$toml = @(
	'# E011 prototype control file, generated from the approved enrollment inventory.'
	'[history]'
	'exclude = ["~/.config/nvim/stylua.toml"]'
	''
	'[dotfiles]'
)
$toml += $roots | ForEach-Object {
	$a = if ($_.Autosave -eq 'off') { ', autosave = false' } else { '' }
	"`"$($_.Source)`" = { mode = `"track`"$a$($sel[$_.Variant]) }"
}
# Linux managed destinations, per the inventory's Linux Managed Destinations
# section: one declaration per home destination of a shared or Linux row, gated
# to Linux and, for rows in the capability block, to that capability. SANITIZED
# rows (#372) render as templates, whose include lines add the excluded
# application-local input.
$gates = @{}
foreach ($l in Block 'linux-capability-gates') { $id, $cap = -split $l; $gates[$id] = $cap }
$linux = foreach ($r in $roots | Where-Object Variant -NE 'W') {
	foreach ($item in $r.Destination.Replace('`', '') -split ';') {
		$item = $item.Trim()
		if ($item -match 'AppData|%APPDATA%|setup-root|selected include|systemd|/etc/' -or $item -notmatch '(~/\S+)') { continue }
		$target = $Matches[1]
		$kind, $perm = if ($item -match '^generated ') { $(if ($r.Source -like '*.tmpl' -or $r.Review -eq 'SANITIZED') { 'template' } else { 'copy' }), '0644' }
		elseif ($item -match 'mode 0755') { 'copy', '0755' }
		elseif ($item -match '^copy-ok ') { 'copy', '0644' }
		else { 'symlink', $null }
		$prof = if ($gates[$r.Id]) { ", profile = `"$($gates[$r.Id])`"" } else { '' }
		$perms = if ($perm) { ", permissions = `"$perm`"" } else { '' }
		"`"$target`" = { source = `"$($r.Source)`", mode = `"$kind`"$perms, variants = [{ os = `"linux`"$prof }] }"
	}
}
$toml += '', '# Linux managed destinations (not enrollment roots).'
$toml += $linux
$toml += '', '[bootstrap.repos]'
$gh = 'https://github.com'
$toml += Get-Content -LiteralPath (Join-Path $PSScriptRoot 'repos.txt') | Where-Object { $_.Trim() } | ForEach-Object {
	"`"~/src/github.com/$_`" = { url = `"$gh/$_`" }"
}
Save 'dotfiles.toml' $toml

$removals = @('.gitmodules') + @($legacy | Where-Object { $_ -match '^160000 ' } | ForEach-Object { ($_ -split "`t", 2)[1] }) + @(Block 'removed-legacy-paths') + @(Block 'deferred-x11-links')
Save 'removals.txt' $removals

$byVar = $files | Group-Object Variant | ForEach-Object { "$($_.Name)=$($_.Count)" }
$streams = @($files.Stream | Sort-Object -Unique).Count
$dupLive = @($files.Live | Group-Object | Where-Object Count -gt 1).Count
"roots=$($roots.Count) exact=$(@($roots | Where-Object Kind -eq 'exact').Count) dir=$(@($roots | Where-Object Kind -eq 'directory').Count)"
"roots_by_variant=$(($roots | Group-Object Variant | ForEach-Object { "$($_.Name)=$($_.Count)" }) -join ',') autosave_off=$(@($roots | Where-Object Autosave -eq 'off').Count)"
"files=$($files.Count) by_variant=$($byVar -join ',') unique_streams=$streams duplicate_live=$dupLive"
"nvim=$(@($files | Where-Object Id -eq 'E138').Count) texmf=$(@($files | Where-Object Id -eq 'E139').Count)"
"linux_destinations=$(@($linux).Count) gated=$(@($linux | Where-Object { $_ -match 'profile = ' }).Count)"
"removals=$($removals.Count) gitlinks=$(@($legacy | Where-Object { $_ -match '^160000 ' }).Count)"
"missing_removals=$(@($removals | Where-Object { $p = $_; -not ($legacy | Where-Object { $_.EndsWith("`t$p") }) }).Count)"
