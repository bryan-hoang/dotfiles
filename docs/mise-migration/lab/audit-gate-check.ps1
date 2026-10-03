# Audit gate step 3: every path added, changed, or deleted in From..To must
# match exactly one approved disposition in the inventory's
# audit-gate-dispositions block. A row-ID disposition must name an existing
# root whose source is that path. Reads path names only, never contents.
# Exits 1 and lists every path without a disposition.
param([string]$From = '46df470', [string]$To = 'be51989')
$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..\..\..')
$inv = Get-Content -LiteralPath (Join-Path $PSScriptRoot '..\matrices\10-approved-enrollment-inventory.md')
$env:MISE_AUTO_INSTALL = '0'

function Block([string]$tag) {
	$s = [array]::IndexOf($inv, "<!-- ${tag}:start -->")
	$e = [array]::IndexOf($inv, "<!-- ${tag}:end -->")
	if ($s -lt 0 -or $e -lt $s) { throw "block not found: $tag" }
	$inv[($s + 1)..($e - 1)] | Where-Object { $_ -and $_ -notmatch '^```' }
}

$sources = @{}
foreach ($line in Block 'enrollment-roots' | Where-Object { $_ -match '^\|\s*`?E\d{3}`?\s' }) {
	$f = @($line.Trim().Trim('|') -split '\|' | ForEach-Object { $_.Trim().Trim('`') })
	$sources[$f[0]] = $f[1]
}
# Rule: <status letters> <path or glob> <repository-only | Ennn>
$rules = foreach ($l in Block 'audit-gate-dispositions') {
	$st, $glob, $disp = -split $l
	[pscustomobject]@{ Status = $st; Glob = $glob; Disp = $disp }
}

$diff = git -C $root diff --no-renames --name-status $From $To
if ($LASTEXITCODE) { throw "cannot diff $From $To" }
$bad = @(); $counts = @{}
foreach ($d in $diff) {
	$st, $path = $d -split "`t", 2
	$hit = @($rules | Where-Object { $_.Status.Contains($st) -and ($path -eq $_.Glob -or ($_.Glob.EndsWith('/**') -and $path.StartsWith($_.Glob.Substring(0, $_.Glob.Length - 2)))) })
	$ok = $hit.Count -eq 1 -and ($hit[0].Disp -eq 'repository-only' -or $sources[$hit[0].Disp] -eq "~/$path")
	if ($ok) { $counts[$hit[0].Disp] += 1 } else { $bad += "$st`t$path" }
}
"paths=$(@($diff).Count) " + (($counts.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join ' ')
if ($bad) { 'undisposed:'; $bad; exit 1 }
'undisposed=0'
