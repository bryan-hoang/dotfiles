#Requires -Version 7.0
# Windows application module (E161). Owns the Windows destinations that mise
# dotfile declarations cannot express. Usage:
#
#   Import-Module ~/.config/mise/dotfiles/.config/windows/WindowsApplications.psm1
#   Invoke-WindowsApplications status|apply|unapply|validate [-Unit <name>...]
#   Get-WindowsApplicationsPathMap
#
# A unit is one entry in $Units. Optional units are enabled by a boolean of the
# same name under [vars.windows_applications] in the excluded
# ~/.config/mise/config.windows.local.toml; absent means false. Path kinds:
#   Link     writable file symlink, verified; no copy fallback
#   Junction writable directory junction, verified; no copy fallback
#   Copy     copy-ok: read-only replaceable copy, reapplied when the source changes
# Dest is a string (~ and %VAR% expand) or a script block evaluated at run time.
#
# State, quarantine, and the drift sentinel live under the excluded
# ~/.local/state/mise/windows-applications/. While the sentinel exists every
# command refuses: reconcile the quarantined paths, then delete the sentinel.
# The module declares no service and no watcher.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Units = [ordered]@{
	base     = @{
		Required = $true
		Requires = @('git')
		Paths    = @(
			@{ Kind = 'Link'; Source = '~/.config/pwsh/Microsoft.PowerShell_profile.ps1'; Dest = { $PROFILE.CurrentUserCurrentHost } }
			@{ Kind = 'Junction'; Source = '~/.config/mintty'; Dest = '%APPDATA%/mintty' }
		)
	}
	topgrade = @{
		Requires = @('topgrade')
		Paths    = @(
			@{ Kind = 'Copy'; Source = '~/.config/topgrade/topgrade.toml'; Dest = '%APPDATA%/topgrade.toml' }
		)
	}
}

$StateDir = Join-Path $HOME '.local/state/mise/windows-applications'
$Sentinel = Join-Path $StateDir 'blocked'
$FlagFile = Join-Path $HOME '.config/mise/config.windows.local.toml'

function Expand-Path($p) {
	if ($p -is [scriptblock]) { $p = & $p }
	$p = [Environment]::ExpandEnvironmentVariables($p)
	if ($p.StartsWith('~')) { $p = $HOME + $p.Substring(1) }
	[IO.Path]::GetFullPath($p)
}

function Test-Enabled([string]$name) {
	if ($Units[$name].ContainsKey('Required')) { return $true }
	if (-not (Test-Path -LiteralPath $FlagFile)) { return $false }
	$o = & mise config get -f $FlagFile "vars.windows_applications.$name" 2>&1 | ForEach-Object { "$_" }
	if ($LASTEXITCODE) {
		if (($o -join "`n") -match 'Key not found') { return $false }
		throw "cannot read flag $name from $FlagFile"
	}
	switch ($o -join '') { 'true' { $true } 'false' { $false } default { throw "vars.windows_applications.$name must be a boolean" } }
}

function Get-WindowsApplicationsPathMap {
	foreach ($name in $Units.Keys) {
		foreach ($p in $Units[$name].Paths) {
			[pscustomobject]@{ Unit = $name; Kind = $p.Kind; Source = (Expand-Path $p.Source); Dest = (Expand-Path $p.Dest) }
		}
	}
}

function Get-Hash([string]$path) { (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash }

function Read-State([string]$name) {
	$f = Join-Path $StateDir "$name.json"
	$h = @{}
	if (Test-Path -LiteralPath $f) { foreach ($r in @(Get-Content -LiteralPath $f -Raw | ConvertFrom-Json)) { $h[$r.Dest] = $r } }
	$h
}

function Write-State([string]$name, [hashtable]$recs) {
	$f = Join-Path $StateDir "$name.json"
	if ($recs.Count) { @($recs.Values) | ConvertTo-Json -AsArray | Set-Content -LiteralPath $f }
	elseif (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f }
}

# absent | ok | stale (owned copy of an older source) | changed (owned, diverged) | occupied (not owned)
function Get-DestState($e, $rec) {
	$item = Get-Item -LiteralPath $e.Dest -Force -ErrorAction SilentlyContinue
	if (-not $item) { return 'absent' }
	$target = if ($item.LinkTarget) { [IO.Path]::GetFullPath($item.LinkTarget, (Split-Path $item.FullName)) } else { $null }
	$match = switch ($e.Kind) {
		'Link' { $item.LinkType -eq 'SymbolicLink' -and -not $item.PSIsContainer -and $target -eq $e.Source }
		'Junction' { $item.LinkType -eq 'Junction' -and $target -eq $e.Source }
		'Copy' { -not $item.LinkType -and -not $item.PSIsContainer -and $item.IsReadOnly -and $rec -and (Get-Hash $e.Dest) -eq $rec.Hash }
	}
	if (-not $match) { return $(if ($rec) { 'changed' } else { 'occupied' }) }
	if ($e.Kind -eq 'Copy' -and (Get-Hash $e.Source) -ne $rec.Hash) { return 'stale' }
	'ok'
}

function Test-LinkCapability {
	$probe = Join-Path $StateDir "link-probe-$PID"
	try { New-Item -ItemType SymbolicLink -Path $probe -Target $PSCommandPath | Out-Null; $true }
	catch { $false }
	finally { if (Test-Path -LiteralPath $probe) { [IO.File]::Delete($probe) } }
}

function Save-Quarantine([string]$path) {
	$q = Join-Path $StateDir ('quarantine/' + (Get-Date -Format 'yyyyMMddHHmmssfff'))
	[IO.Directory]::CreateDirectory($q) | Out-Null
	$item = Get-Item -LiteralPath $path -Force
	$copy = Join-Path $q $item.Name
	$hash = ''
	if ($item.LinkType) { Set-Content -LiteralPath "$copy.link-target" -Value $item.LinkTarget }
	else {
		Copy-Item -LiteralPath $path -Destination $copy -Recurse
		if (-not $item.PSIsContainer) { $hash = Get-Hash $path }
	}
	Add-Content -LiteralPath (Join-Path $StateDir 'quarantine/log.tsv') -Value "$(Get-Date -Format o)`t$path`t$copy`t$hash"
	$copy
}

function Remove-Owned($rec) {
	$item = Get-Item -LiteralPath $rec.Dest -Force
	switch ($rec.Kind) {
		'Junction' { [IO.Directory]::Delete($rec.Dest, $false) }
		'Copy' { $item.IsReadOnly = $false; [IO.File]::Delete($rec.Dest) }
		default { [IO.File]::Delete($rec.Dest) }
	}
}

function Result($name, $e, $state, $action) {
	[pscustomobject]@{ Unit = $name; Kind = $e.Kind; Dest = $e.Dest; State = $state; Action = $action }
}

function Invoke-UnitApply([string]$name) {
	$u = $Units[$name]
	$entries = @(Get-WindowsApplicationsPathMap | Where-Object Unit -EQ $name)
	$recs = Read-State $name
	$problems = @()
	foreach ($cmd in $u.Requires) {
		if (-not (Get-Command $cmd -CommandType Application -ErrorAction SilentlyContinue)) { $problems += "missing application $cmd" }
	}
	if ('Link' -in $entries.Kind -and -not (Test-LinkCapability)) { $problems += 'symlinks not permitted (Developer Mode or link privilege required)' }
	$states = @{}
	foreach ($e in $entries) {
		$type = if ($e.Kind -eq 'Junction') { 'Container' } else { 'Leaf' }
		if (-not (Test-Path -LiteralPath $e.Source -PathType $type)) { $problems += "missing source $($e.Source)" }
		$states[$e.Dest] = Get-DestState $e $recs[$e.Dest]
		if ($states[$e.Dest] -in 'changed', 'occupied') { $problems += "$($states[$e.Dest]) destination $($e.Dest)" }
	}
	if ($problems) {
		foreach ($e in $entries) { Result $name $e $states[$e.Dest] ('preflight failed: ' + ($problems -join '; ')) }
		return
	}
	foreach ($e in $entries) {
		$s = $states[$e.Dest]
		if ($s -eq 'ok') {
			if (-not $recs[$e.Dest]) { $recs[$e.Dest] = [pscustomobject]@{ Dest = $e.Dest; Kind = $e.Kind; Source = $e.Source; Hash = '' } }
			Result $name $e $s 'none'
			continue
		}
		[IO.Directory]::CreateDirectory((Split-Path $e.Dest)) | Out-Null
		$hash = ''
		switch ($e.Kind) {
			'Link' { New-Item -ItemType SymbolicLink -Path $e.Dest -Target $e.Source | Out-Null }
			'Junction' { New-Item -ItemType Junction -Path $e.Dest -Target $e.Source | Out-Null }
			'Copy' {
				if ($s -eq 'stale') { (Get-Item -LiteralPath $e.Dest).IsReadOnly = $false }
				Copy-Item -LiteralPath $e.Source -Destination $e.Dest -Force
				(Get-Item -LiteralPath $e.Dest).IsReadOnly = $true
				$hash = Get-Hash $e.Dest
			}
		}
		$recs[$e.Dest] = [pscustomobject]@{ Dest = $e.Dest; Kind = $e.Kind; Source = $e.Source; Hash = $hash }
		Write-State $name $recs
		$after = Get-DestState $e $recs[$e.Dest]
		if ($after -ne 'ok') { throw "$($e.Dest) did not verify as $($e.Kind) after apply ($after)" }
		Result $name $e $after $(if ($s -eq 'stale') { 'replaced' } else { 'created' })
	}
	Write-State $name $recs
}

# Removes only resources this module recorded and that are unchanged; holds the rest.
function Invoke-UnitUnapply([string]$name) {
	$recs = Read-State $name
	foreach ($rec in @($recs.Values)) {
		$s = Get-DestState $rec $rec
		if ($s -in 'ok', 'stale') { Remove-Owned $rec; $recs.Remove($rec.Dest); Result $name $rec $s 'removed' }
		elseif ($s -eq 'absent') { $recs.Remove($rec.Dest); Result $name $rec $s 'forgotten' }
		else { Result $name $rec $s "held; quarantined copy $(Save-Quarantine $rec.Dest)" }
	}
	Write-State $name $recs
}

function Test-Incomplete($results) { [bool]@($results | Where-Object Action -Match '^(preflight failed|held)').Count }

function Stop-HistoryWatcher {
	Set-StrictMode -Off # COM-handler task actions have no Execute or Arguments.
	$n = 0
	foreach ($p in Get-CimInstance Win32_Process -Filter "Name LIKE 'mise%'") {
		if ($p.CommandLine -match '\b(dot|dotfiles)\s+watch\b|history-watch') { Stop-Process -Id $p.ProcessId -Force; $n++ }
	}
	foreach ($t in Get-ScheduledTask -ErrorAction SilentlyContinue) {
		if (@($t.Actions | Where-Object { "$($_.Execute) $($_.Arguments)" -match 'mise.*(\b(dot|dotfiles)\s+watch\b|history-watch)' })) {
			$t | Stop-ScheduledTask
			$t | Disable-ScheduledTask | Out-Null
			$n++
		}
	}
	if ($n) { "stopped $n watcher process or task(s)" } else { 'no watcher declared or running (no-op)' }
}

function Invoke-Validate([string[]]$names) {
	$drift = @()
	foreach ($name in $names) {
		$recs = Read-State $name
		foreach ($rec in $recs.Values) {
			$s = Get-DestState $rec $rec
			if ($s -eq 'changed') { $drift += "$($rec.Dest)`t$(Save-Quarantine $rec.Dest)" }
			Result $name $rec $s $(if ($s -eq 'changed') { 'quarantined' } else { 'none' })
		}
	}
	if (-not $drift) { return }
	# Block first so a failure while stopping the watcher still leaves the sentinel.
	Set-Content -LiteralPath $Sentinel -Value (@("drift detected $(Get-Date -Format o)") + $drift +
		'Reconcile each path from its quarantined copy, delete this file, then run validate.')
	$watcher = Stop-HistoryWatcher
	Add-Content -LiteralPath $Sentinel -Value "watcher: $watcher"
	throw "drift in $($drift.Count) managed path(s); quarantined, sentinel written at $Sentinel, watcher: $watcher"
}

function Invoke-WindowsApplications {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)][ValidateSet('status', 'apply', 'unapply', 'validate')][string]$Verb,
		[string[]]$Unit
	)
	if (Test-Path -LiteralPath $Sentinel) { throw "blocked by drift sentinel $Sentinel; reconcile the quarantined paths, then delete it" }
	foreach ($n in $Unit) { if (-not $Units.Contains($n)) { throw "unknown unit $n" } }
	$names = if ($Unit) { $Unit } else { @($Units.Keys) }
	[IO.Directory]::CreateDirectory($StateDir) | Out-Null
	$failed = @()
	switch ($Verb) {
		'status' {
			foreach ($name in $names) {
				$recs = Read-State $name
				$on = Test-Enabled $name
				foreach ($e in @(Get-WindowsApplicationsPathMap | Where-Object Unit -EQ $name)) {
					[pscustomobject]@{ Unit = $name; Enabled = $on; Kind = $e.Kind; Dest = $e.Dest; State = (Get-DestState $e $recs[$e.Dest]); Source = $e.Source }
				}
			}
		}
		'apply' {
			# Required units first; a required failure stops before any optional unit.
			foreach ($name in @($names | Sort-Object { -not $Units[$_].ContainsKey('Required') })) {
				$r = if (Test-Enabled $name) { Invoke-UnitApply $name } else { Invoke-UnitUnapply $name }
				$r
				if (Test-Incomplete $r) {
					if ($Units[$name].ContainsKey('Required')) { throw "required unit $name failed" }
					$failed += $name
				}
			}
		}
		'unapply' {
			foreach ($name in $names) {
				$r = Invoke-UnitUnapply $name
				$r
				if (Test-Incomplete $r) { $failed += $name }
			}
		}
		'validate' { Invoke-Validate $names }
	}
	if ($failed) { throw "$Verb did not complete for: $($failed -join ', ')" }
}

Export-ModuleMember -Function Invoke-WindowsApplications, Get-WindowsApplicationsPathMap
