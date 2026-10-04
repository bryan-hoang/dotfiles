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
# ~/.config/mise/config.windows.local.toml; absent means false. Apply leaves a
# disabled unit's paths in place and reports them; only unapply removes or
# quarantines. Path kinds:
#   Link     writable file symlink, verified; no copy fallback
#   Junction writable directory junction, verified; no copy fallback
#   Copy     copy-ok: read-only replaceable copy, reapplied when the source changes
#   Render   generated read-only file: the source with each env template
#            expression replaced by that environment variable; any other
#            template syntax fails. Reapplied when the rendered bytes change.
# Dest is a string (~ and %VAR% expand) or a script block evaluated at run time.
# Requires lists commands (on the process PATH, or the persistent login PATH
# when LoginPath is set) and paths (anything with a slash) that must exist.
# Repos lists bootstrap repositories at ~/src/github.com/<owner>/<repo> that
# must be present, clean, and have the public HTTPS origin. Any unmet
# requirement fails the unit's preflight, so none of its paths change.
#
# State, quarantine, and the drift sentinel live under the excluded
# ~/.local/state/mise/windows-applications/. Validate moves a drifted path
# into quarantine, so its destination is empty. While the sentinel exists every
# exported command refuses: reconcile the quarantined paths, delete the
# sentinel, re-enable any watcher task it lists, then apply relinks. A path
# that already matched before the module recorded it is monitored, but unapply
# leaves it in place. The module declares no service and no watcher.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Startup = '%APPDATA%/Microsoft/Windows/Start Menu/Programs/Startup'
$Units = [ordered]@{
	base             = @{
		Required = $true
		Requires = @('git')
		Paths    = @(
			@{ Kind = 'Link'; Source = '~/.config/pwsh/Microsoft.PowerShell_profile.ps1'; Dest = { $PROFILE.CurrentUserCurrentHost } }
			@{ Kind = 'Junction'; Source = '~/.config/mintty'; Dest = '%APPDATA%/mintty' }
			@{ Kind = 'Link'; Source = '~/.config/bash/.bash_logout'; Dest = '~/.bash_logout' }
			@{ Kind = 'Link'; Source = '~/.config/bash/.bash_profile'; Dest = '~/.bash_profile' }
			@{ Kind = 'Link'; Source = '~/.config/bash/.bashrc'; Dest = '~/.bashrc' }
			@{ Kind = 'Link'; Source = '~/.config/login/.hushlogin'; Dest = '~/.hushlogin' }
			@{ Kind = 'Link'; Source = '~/.config/shell/.profile'; Dest = '~/.profile' }
		)
	}
	alacritty        = @{
		Requires = @('alacritty', '%ProgramFiles%/Git/bin/bash.exe', '~/.config/alacritty/alacritty.common.toml', '~/src/github.com/catppuccin/alacritty/catppuccin-mocha.toml')
		Repos    = @('catppuccin/alacritty')
		Paths    = @(
			@{ Kind = 'Render'; Source = '~/.config/mise/dotfiles/AppData/Roaming/alacritty/alacritty.toml'; Dest = '%APPDATA%/alacritty/alacritty.toml' }
		)
	}
	atuin_daemon     = @{
		Requires  = @('atuin')
		LoginPath = $true
		Paths     = @(
			@{ Kind = 'Copy'; Source = "~/.config/mise/dotfiles/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/start-atuin-daemon.vbs"; Dest = "$Startup/start-atuin-daemon.vbs" }
		)
	}
	bat              = @{
		Requires = @('bat')
		Paths    = @(@{ Kind = 'Junction'; Source = '~/.config/bat'; Dest = '%APPDATA%/bat' })
	}
	espanso          = @{
		Requires = @('espanso')
		Paths    = @(@{ Kind = 'Junction'; Source = '~/.config/espanso'; Dest = '%APPDATA%/espanso' })
	}
	harper           = @{
		Requires = @('harper-ls')
		Paths    = @(@{ Kind = 'Link'; Source = '~/.config/harper-ls/dictionary.txt'; Dest = '%APPDATA%/harper-ls/dictionary.txt' })
	}
	helix            = @{
		Requires = @('hx')
		Paths    = @(@{ Kind = 'Junction'; Source = '~/.config/helix'; Dest = '%APPDATA%/helix' })
	}
	# The source directory is excluded local authority, never enrolled.
	ncspot           = @{
		Requires = @('ncspot')
		Paths    = @(@{ Kind = 'Junction'; Source = '~/.config/ncspot'; Dest = '%APPDATA%/ncspot' })
	}
	rio              = @{
		Requires = @('rio')
		Repos    = @('catppuccin/rio')
		Paths    = @(
			@{ Kind = 'Link'; Source = '~/src/github.com/catppuccin/rio/themes/catppuccin-mocha.toml'; Dest = '~/.config/rio/themes/catppuccin-mocha.toml' }
			@{ Kind = 'Junction'; Source = '~/.config/rio'; Dest = '%LOCALAPPDATA%/rio' }
		)
	}
	rtk              = @{
		Requires = @('rtk')
		Paths    = @(@{ Kind = 'Junction'; Source = '~/.config/rtk'; Dest = '%APPDATA%/rtk' })
	}
	# The package folder exists once the matching Terminal package is installed.
	terminal_preview = @{
		Requires = @('%LOCALAPPDATA%/Packages/Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe')
		Paths    = @(@{ Kind = 'Link'; Source = '~/.config/windows/wind-term-settings.json'; Dest = '%LOCALAPPDATA%/Packages/Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe/LocalState/settings.json' })
	}
	terminal_stable  = @{
		Requires = @('%LOCALAPPDATA%/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe')
		Paths    = @(@{ Kind = 'Link'; Source = '~/.config/windows/wind-term-settings.json'; Dest = '%LOCALAPPDATA%/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json' })
	}
	topgrade         = @{
		Requires = @('topgrade')
		Paths    = @(
			@{ Kind = 'Copy'; Source = '~/.config/topgrade/topgrade.toml'; Dest = '%APPDATA%/topgrade.toml' }
		)
	}
}

# Required outputs E011 renders (Herdr, from E101); validate fails while one is missing.
$Generated = @('%APPDATA%/herdr/config.toml')

$StateDir = Join-Path $HOME '.local/state/mise/windows-applications'
$Sentinel = Join-Path $StateDir 'blocked'
$FlagFile = Join-Path $HOME '.config/mise/config.windows.local.toml'

function Expand-Path($p) {
	if ($p -is [scriptblock]) { $p = & $p }
	$p = [Environment]::ExpandEnvironmentVariables($p)
	if ($p.StartsWith('~')) { $p = $HOME + $p.Substring(1) }
	[IO.Path]::GetFullPath($p)
}

function Test-Required([string]$name) { $Units[$name]['Required'] -eq $true }

function Test-Enabled([string]$name) {
	if (Test-Required $name) { return $true }
	if (-not (Test-Path -LiteralPath $FlagFile)) { return $false }
	$o = & mise config get -f $FlagFile "vars.windows_applications.$name" 2>&1 | ForEach-Object { "$_" }
	if ($LASTEXITCODE) {
		if (($o -join "`n") -match 'Key not found') { return $false }
		throw "cannot read flag $name from $FlagFile"
	}
	switch ($o -join '') { 'true' { $true } 'false' { $false } default { throw "vars.windows_applications.$name must be a boolean" } }
}

function Assert-Unblocked {
	if (Test-Path -LiteralPath $Sentinel) { throw "blocked by drift sentinel $Sentinel; reconcile the quarantined paths, then delete it" }
}

function Get-WindowsApplicationsPathMap {
	Assert-Unblocked
	Get-PathEntries
}

function Get-PathEntries {
	foreach ($name in $Units.Keys) {
		foreach ($p in $Units[$name].Paths) {
			[pscustomobject]@{ Unit = $name; Kind = $p.Kind; Source = (Expand-Path $p.Source); Dest = (Expand-Path $p.Dest) }
		}
	}
}

function Get-Hash([string]$path) { (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash }

function Get-Rendered([string]$source) {
	$text = [IO.File]::ReadAllText($source)
	$out = [regex]::Replace($text, '\{\{\s*env\.(\w+)\s*\}\}', {
			param($m)
			$v = [Environment]::GetEnvironmentVariable($m.Groups[1].Value)
			if ($null -eq $v) { throw "$source needs unset environment variable $($m.Groups[1].Value)" }
			$v
		})
	if ($out -match '\{\{|\{%') { throw "$source has template syntax other than env expressions" }
	[Text.UTF8Encoding]::new($false).GetBytes($out)
}

# The hash a Copy or Render destination must have once applied.
function Get-ExpectedHash($e) {
	if ($e.Kind -eq 'Copy') { return Get-Hash $e.Source }
	[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData((Get-Rendered $e.Source)))
}

function Test-Command([string]$cmd, [bool]$login) {
	if (-not $login) { return [bool](Get-Command $cmd -CommandType Application -ErrorAction SilentlyContinue) }
	$dirs = (@('Machine', 'User') | ForEach-Object { [Environment]::GetEnvironmentVariable('Path', $_) }) -join ';'
	foreach ($d in $dirs -split ';' | Where-Object { $_ }) {
		foreach ($x in $env:PATHEXT -split ';') {
			if (Test-Path -LiteralPath (Join-Path ([Environment]::ExpandEnvironmentVariables($d)) "$cmd$x") -PathType Leaf) { return $true }
		}
	}
	$false
}

# Never reports the origin value: it may be private.
function Test-Repo([string]$repo) {
	$dir = Expand-Path "~/src/github.com/$repo"
	if (-not (Test-Path -LiteralPath (Join-Path $dir '.git'))) { return "missing repository $repo" }
	$url = & git -C $dir config --get remote.origin.url
	$public = 'https://github.com/' + $repo
	if ($url -notin $public, "$public.git") { return "wrong origin for repository $repo" }
	$dirty = & git -C $dir status --porcelain
	if ($LASTEXITCODE -or $dirty) { return "dirty repository $repo" }
}

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
# -Recorded compares the destination with its record only and never reads the
# source, so it works after the source is deleted or a template input is unset;
# it never reports stale.
function Get-DestState($e, $rec, [switch]$Recorded) {
	$item = Get-Item -LiteralPath $e.Dest -Force -ErrorAction SilentlyContinue
	if (-not $item) { return 'absent' }
	$target = if ($item.LinkTarget) { [IO.Path]::GetFullPath($item.LinkTarget, (Split-Path $item.FullName)) } else { $null }
	$match = switch ($e.Kind) {
		'Link' { $item.LinkType -eq 'SymbolicLink' -and -not $item.PSIsContainer -and $target -eq $e.Source }
		'Junction' { $item.LinkType -eq 'Junction' -and $target -eq $e.Source }
		default { -not $item.LinkType -and -not $item.PSIsContainer -and $item.IsReadOnly -and $rec -and (Get-Hash $e.Dest) -eq $rec.Hash }
	}
	if (-not $match) { return $(if ($rec) { 'changed' } else { 'occupied' }) }
	if (-not $Recorded -and $e.Kind -in 'Copy', 'Render' -and (Get-ExpectedHash $e) -ne $rec.Hash) { return 'stale' }
	'ok'
}

function Test-LinkCapability {
	$probe = Join-Path $StateDir "link-probe-$PID"
	try { New-Item -ItemType SymbolicLink -Path $probe -Target $PSCommandPath | Out-Null; $true }
	catch { $false }
	finally { if (Test-Path -LiteralPath $probe) { [IO.File]::Delete($probe) } }
}

# Copies the path into quarantine, or with -Move moves it there and leaves the
# destination empty. A link is recorded by its target (and moved itself).
function Save-Quarantine([string]$path, [switch]$Move) {
	$q = Join-Path $StateDir ('quarantine/' + (Get-Date -Format 'yyyyMMddHHmmssfff'))
	[IO.Directory]::CreateDirectory($q) | Out-Null
	$item = Get-Item -LiteralPath $path -Force
	$copy = Join-Path $q $item.Name
	$hash = if (-not $item.LinkType -and -not $item.PSIsContainer) { Get-Hash $path } else { '' }
	if ($item.LinkType) { Set-Content -LiteralPath "$copy.link-target" -Value $item.LinkTarget }
	if ($Move) { Move-Item -LiteralPath $path -Destination $copy }
	elseif (-not $item.LinkType) { Copy-Item -LiteralPath $path -Destination $copy -Recurse }
	Add-Content -LiteralPath (Join-Path $StateDir 'quarantine/log.tsv') -Value "$(Get-Date -Format o)`t$path`t$copy`t$hash"
	$copy
}

function Remove-Owned($rec) {
	$item = Get-Item -LiteralPath $rec.Dest -Force
	switch ($rec.Kind) {
		'Junction' { [IO.Directory]::Delete($rec.Dest, $false) }
		'Link' { [IO.File]::Delete($rec.Dest) }
		default { $item.IsReadOnly = $false; [IO.File]::Delete($rec.Dest) }
	}
}

function Result($name, $e, $state, $action) {
	[pscustomobject]@{ Unit = $name; Kind = $e.Kind; Dest = $e.Dest; State = $state; Action = $action }
}

function Invoke-UnitApply([string]$name) {
	$u = $Units[$name]
	$entries = @(Get-PathEntries | Where-Object Unit -EQ $name)
	$recs = Read-State $name
	$problems = @()
	foreach ($r in $u.Requires) {
		if ($r -match '[/\\]') { if (-not (Test-Path -LiteralPath (Expand-Path $r))) { $problems += "missing path $r" } }
		elseif (-not (Test-Command $r ([bool]$u['LoginPath']))) { $problems += "missing application $r$(if ($u['LoginPath']) { ' on the login PATH' })" }
	}
	foreach ($repo in $u['Repos']) { $problems += @(Test-Repo $repo) }
	if ('Link' -in $entries.Kind -and -not (Test-LinkCapability)) { $problems += 'symlinks not permitted (Developer Mode or link privilege required)' }
	$states = @{}
	foreach ($e in $entries) {
		$type = if ($e.Kind -eq 'Junction') { 'Container' } else { 'Leaf' }
		if (-not (Test-Path -LiteralPath $e.Source -PathType $type)) { $problems += "missing source $($e.Source)"; continue }
		try { $states[$e.Dest] = Get-DestState $e $recs[$e.Dest] }
		catch { $problems += "$($e.Source): $($_.Exception.Message)"; continue }
		if ($states[$e.Dest] -in 'changed', 'occupied') { $problems += "$($states[$e.Dest]) destination $($e.Dest)" }
	}
	if ($problems) {
		foreach ($e in $entries) { Result $name $e $states[$e.Dest] ('preflight failed: ' + ($problems -join '; ')) }
		return
	}
	foreach ($e in $entries) {
		$s = $states[$e.Dest]
		if ($s -eq 'ok') {
			# Already linked before the module recorded it: monitored by validate,
			# but not created here, so unapply leaves it in place.
			if (-not $recs[$e.Dest]) { $recs[$e.Dest] = [pscustomobject]@{ Dest = $e.Dest; Kind = $e.Kind; Source = $e.Source; Hash = ''; Adopted = $true } }
			Result $name $e $s 'none'
			continue
		}
		[IO.Directory]::CreateDirectory((Split-Path $e.Dest)) | Out-Null
		$hash = ''
		switch ($e.Kind) {
			'Link' { New-Item -ItemType SymbolicLink -Path $e.Dest -Target $e.Source | Out-Null }
			'Junction' { New-Item -ItemType Junction -Path $e.Dest -Target $e.Source | Out-Null }
			default {
				if ($s -eq 'stale') { (Get-Item -LiteralPath $e.Dest).IsReadOnly = $false }
				if ($e.Kind -eq 'Copy') { Copy-Item -LiteralPath $e.Source -Destination $e.Dest -Force }
				else { [IO.File]::WriteAllBytes($e.Dest, (Get-Rendered $e.Source)) }
				(Get-Item -LiteralPath $e.Dest).IsReadOnly = $true
				$hash = Get-Hash $e.Dest
			}
		}
		$recs[$e.Dest] = [pscustomobject]@{ Dest = $e.Dest; Kind = $e.Kind; Source = $e.Source; Hash = $hash; Adopted = $false }
		Write-State $name $recs
		$after = Get-DestState $e $recs[$e.Dest]
		if ($after -ne 'ok') { throw "$($e.Dest) did not verify as $($e.Kind) after apply ($after)" }
		Result $name $e $after $(if ($s -eq 'stale') { 'replaced' } else { 'created' })
	}
	Write-State $name $recs
}

# Apply with a unit's flag off changes nothing: it reports what the module still owns.
function Get-OwnedReport([string]$name) {
	foreach ($rec in (Read-State $name).Values) {
		Result $name $rec (Get-DestState $rec $rec -Recorded) "owned; flag off, run unapply -Unit $name to remove"
	}
}

# Removes only resources this module created and that are unchanged; holds the
# rest. Compares each destination with its record, never with the source.
function Invoke-UnitUnapply([string]$name) {
	$recs = Read-State $name
	foreach ($rec in @($recs.Values)) {
		$s = Get-DestState $rec $rec -Recorded
		if ($s -eq 'ok' -and $rec.Adopted) { $recs.Remove($rec.Dest); Result $name $rec $s 'released; left in place, not created by this module' }
		elseif ($s -eq 'ok') { Remove-Owned $rec; $recs.Remove($rec.Dest); Result $name $rec $s 'removed' }
		elseif ($s -eq 'absent') { $recs.Remove($rec.Dest); Result $name $rec $s 'forgotten' }
		else { Result $name $rec $s "held; quarantined copy $(Save-Quarantine $rec.Dest)" }
	}
	Write-State $name $recs
}

# A unit with nothing to report (flag off, nothing owned) returns no results.
function Test-Incomplete($results) { $results -and [bool]@($results | Where-Object Action -Match '^(preflight failed|held)').Count }

function Stop-HistoryWatcher {
	Set-StrictMode -Off # COM-handler task actions have no Execute or Arguments.
	$n = 0
	$tasks = @()
	foreach ($p in Get-CimInstance Win32_Process -Filter "Name LIKE 'mise%'") {
		if ($p.CommandLine -match '\b(dot|dotfiles)\s+watch\b|history-watch') { Stop-Process -Id $p.ProcessId -Force; $n++ }
	}
	foreach ($t in Get-ScheduledTask -ErrorAction SilentlyContinue) {
		if (@($t.Actions | Where-Object { "$($_.Execute) $($_.Arguments)" -match 'mise.*(\b(dot|dotfiles)\s+watch\b|history-watch)' })) {
			$t | Stop-ScheduledTask
			$t | Disable-ScheduledTask | Out-Null
			$tasks += "Enable-ScheduledTask -TaskPath '$($t.TaskPath)' -TaskName '$($t.TaskName)'"
		}
	}
	# First line: the summary; then one re-enable command per disabled task.
	if ($n -or $tasks) { "stopped $n watcher process(es), disabled $($tasks.Count) watcher task(s)" } else { 'no watcher declared or running (no-op)' }
	$tasks
}

function Invoke-Validate([string[]]$names) {
	$drift = @()
	foreach ($name in $names) {
		$recs = Read-State $name
		foreach ($rec in $recs.Values) {
			$s = Get-DestState $rec $rec -Recorded
			if ($s -eq 'changed') { $drift += "$($rec.Dest)`t$(Save-Quarantine $rec.Dest -Move)" }
			Result $name $rec $s $(if ($s -eq 'changed') { 'moved to quarantine' } else { 'none' })
		}
	}
	# Base outputs that mise renders from E011; the module only checks they exist.
	$missing = @()
	if ('base' -in $names) {
		foreach ($g in $Generated) {
			$p = Expand-Path $g
			$ok = Test-Path -LiteralPath $p -PathType Leaf
			if (-not $ok) { $missing += $p }
			Result 'base' ([pscustomobject]@{ Kind = 'Generated'; Dest = $p }) $(if ($ok) { 'ok' } else { 'absent' }) $(if ($ok) { 'none' } else { 'missing; run mise dot apply' })
		}
	}
	if (-not $drift) {
		if ($missing) { throw "missing E011 output(s): $($missing -join ', '); run mise dot apply" }
		return
	}
	# Block first so a failure while stopping the watcher still leaves the sentinel.
	Set-Content -LiteralPath $Sentinel -Value (@("drift detected $(Get-Date -Format o)") + $drift +
		'Each path above was moved into quarantine, so its destination is empty.' +
		'Reconcile it from the quarantined copy into its source or a local input, delete this file,' +
		're-enable each watcher task listed below if validate disabled it, then run apply and validate.')
	$watcher = @(Stop-HistoryWatcher)
	Add-Content -LiteralPath $Sentinel -Value (@("watcher: $($watcher[0])") + @($watcher | Select-Object -Skip 1 | ForEach-Object { "re-enable: $_" }))
	throw "drift in $($drift.Count) managed path(s); moved to quarantine, sentinel written at $Sentinel, watcher: $($watcher[0])"
}

function Invoke-WindowsApplications {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)][ValidateSet('status', 'apply', 'unapply', 'validate')][string]$Verb,
		[string[]]$Unit
	)
	Assert-Unblocked
	foreach ($n in $Unit) { if (-not $Units.Contains($n)) { throw "unknown unit $n" } }
	$names = if ($Unit) { $Unit } else { @($Units.Keys) }
	[IO.Directory]::CreateDirectory($StateDir) | Out-Null
	$failed = @()
	switch ($Verb) {
		'status' {
			foreach ($name in $names) {
				$recs = Read-State $name
				$on = Test-Enabled $name
				foreach ($e in @(Get-PathEntries | Where-Object Unit -EQ $name)) {
					[pscustomobject]@{ Unit = $name; Enabled = $on; Kind = $e.Kind; Dest = $e.Dest; State = (Get-DestState $e $recs[$e.Dest]); Source = $e.Source }
				}
			}
		}
		'apply' {
			# Required units first; a required failure stops before any optional unit.
			foreach ($name in @($names | Sort-Object { -not (Test-Required $_) })) {
				$r = if (Test-Enabled $name) { Invoke-UnitApply $name } else { Get-OwnedReport $name }
				$r
				if (Test-Incomplete $r) {
					if (Test-Required $name) { throw "required unit $name failed" }
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
