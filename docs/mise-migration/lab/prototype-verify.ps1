# Verifies the prototype setup tip in the canonical exchange against the plan
# generated from the approved inventory and the legacy tree at the audited tip.
# Read-only for the exchange; prints key=value results.
param([Parameter(Mandatory)][string]$IntakeRoot, [string]$Legacy = '46df470')
$ErrorActionPreference = 'Stop'
$repo = Join-Path ([IO.Path]::GetFullPath($IntakeRoot)) 'exchange\setup.git'
$p = Join-Path $PSScriptRoot 'prototype'
$inv = Join-Path $PSScriptRoot '..\matrices\10-approved-enrollment-inventory.md'
function G { $o = & git -C $repo @args; if ($LASTEXITCODE) { throw "git $args failed" }; $o }
function Say([string]$k, $v) { "$k=$v" }
function Tree([string]$rev) {
	$h = @{}
	foreach ($l in (G ls-tree -r --full-tree $rev)) { $meta, $path = $l -split "`t", 2; $m, $null, $o = $meta -split ' '; $h[$path] = "$m $o" }
	$h
}

$tip = (G rev-parse main)
$legacyFull = (G rev-parse $Legacy)
Say tip $tip
& git -C $repo merge-base --is-ancestor $legacyFull $tip
Say legacy_tip_is_ancestor $(if ($LASTEXITCODE -eq 0) { 'yes' } else { 'no' })
$chain = @(G log --first-parent --format='%H %P' "$legacyFull..$tip")
Say new_commits $chain.Count
Say new_merge_commits @($chain | Where-Object { ($_ -split ' ').Count -gt 2 }).Count
Say new_commit_authors ((G log --format='%an' "$legacyFull..$tip" | Group-Object | ForEach-Object { "$($_.Name):$($_.Count)" }) -join ',')

$t = Tree $tip
$old = Tree $legacyFull
$files = Get-Content -LiteralPath (Join-Path $p 'files.tsv') | ForEach-Object { $f = $_ -split "`t"; [pscustomobject]@{ Id = $f[0]; Var = $f[1]; Live = $f[2]; Stream = $f[3] } }
$streamRe = '^(home|config)(@[a-z]+)?/'
$actual = @($t.Keys | Where-Object { $_ -match $streamRe })
$expected = @($files.Stream)
Say stream_files $actual.Count
Say stream_missing @($expected | Where-Object { -not $t.ContainsKey($_) }).Count
Say stream_unexpected @($actual | Where-Object { $expected -notcontains $_ }).Count
Say stream_by_root (($actual | Group-Object { ($_ -split '/')[0] } | Sort-Object Name | ForEach-Object { "$($_.Name):$($_.Count)" }) -join ',')
Say stream_modes (($actual | Group-Object { ($t[$_] -split ' ')[0] } | ForEach-Object { "$($_.Name):$($_.Count)" }) -join ',')
$e011 = [IO.File]::ReadAllText((Join-Path $p 'dotfiles.toml'))
$badBytes = @(foreach ($f in $files) {
		if (-not $t.ContainsKey($f.Stream)) { continue }
		$want = if ($f.Id -eq 'E011') { $e011 } else { "# synthetic $($f.Id) $($f.Stream)`n" }
		$got = (& git -C $repo cat-file blob ($t[$f.Stream] -split ' ')[1]) -join "`n"
		if ("$got`n" -ne $want) { $f.Id }
	})
Say stream_bytes_mismatch $(if ($badBytes.Count) { ($badBytes | Select-Object -Unique) -join ',' } else { 0 })
Say managed_stylua_in_history @($t.Keys | Where-Object { $_ -match '/\.config/nvim/stylua\.toml$' }).Count

$lines = Get-Content -LiteralPath $inv
$s = [array]::IndexOf($lines, '<!-- enrollment-roots:start -->'); $e = [array]::IndexOf($lines, '<!-- enrollment-roots:end -->')
$roots = $lines[($s + 1)..($e - 1)] | Where-Object { $_ -match '^\|\s*`?E\d{3}`?\s' } | ForEach-Object { $f = @($_.Trim().Trim('|') -split '\|' | ForEach-Object { $_.Trim().Trim('`') }); [pscustomobject]@{ Id = $f[0]; Source = $f[1]; Enroll = $f[2]; Variant = $f[5]; Autosave = $f[6] } }
$m = (G show "${tip}:.mise-history/manifest.json") -join "`n" | ConvertFrom-Json
Say format_marker (((G show "${tip}:.mise-history/format.toml") | Where-Object { $_ -match '^format' }) -join '')
Say manifest_entries $m.enrollment.Count
$os = @{ S = ''; W = 'windows'; L = 'linux' }
$mm = @(foreach ($r in $roots) {
		$x = @($m.enrollment | Where-Object path -eq $r.Enroll)
		if ($x.Count -ne 1 -or $x[0].autosave -ne ($r.Autosave -eq 'on') -or $x[0].encrypt -or ((@($x[0].variants | ForEach-Object { $_.os }) -join ',') -ne $os[$r.Variant])) { $r.Id }
	})
Say manifest_row_mismatches $(if ($mm.Count) { $mm -join ',' } else { 0 })
Say manifest_duplicate_paths @($m.enrollment.path | Group-Object | Where-Object Count -gt 1).Count
Say manifest_recipients $m.recipients.Count
Say manifest_exclude ($m.exclude -join ',')
Say e006_in_manifest @($m.enrollment | Where-Object path -eq 'config/config.toml').Count
Say e006_in_legacy_tree $(if ($old.ContainsKey('.config/mise/config.toml')) { 'yes' } else { 'no' })

$removals = @(Get-Content -LiteralPath (Join-Path $p 'removals.txt') | Where-Object { $_ })
$kept = @($old.Keys | Where-Object { $removals -notcontains $_ })
Say legacy_entries $old.Count
Say legacy_kept $kept.Count
Say legacy_kept_changed @($kept | Where-Object { $t[$_] -ne $old[$_] }).Count
Say legacy_removed_still_present @($removals | Where-Object { $t.ContainsKey($_) }).Count
Say repository_only_in_tip @($t.Keys | Where-Object { $_ -notmatch $streamRe -and $_ -notlike '.mise-history/*' }).Count
Say gitlinks_in_tip @($t.Values | Where-Object { $_ -like '160000 *' }).Count

$s = [array]::IndexOf($lines, '<!-- deferred-x11-sources:start -->'); $e = [array]::IndexOf($lines, '<!-- deferred-x11-sources:end -->')
$x11 = @($lines[($s + 1)..($e - 1)] | Where-Object { $_ -and $_ -notmatch '^```' })
Say x11_sources_repository_only_unchanged @($x11 | Where-Object { $t[$_] -and $t[$_] -eq $old[$_] }).Count
Say x11_in_manifest @($m.enrollment.path | Where-Object { $p2 = $_; @($x11 | Where-Object { $p2 -like "*/$_" }).Count }).Count
Say x11_in_e011 @(@($x11) + 'xresources', 'dunst', 'dracula/gtk', 'dracula/rofi' | Where-Object { $e011.Contains($_) }).Count
