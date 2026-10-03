# Windows application module (E161) run for Windows Sandbox (Windows
# PowerShell 5.1, ASCII only; the module runs in the staged PowerShell 7 from
# C:\lab-in\bin\pwsh). Adopts the conversion from the exchange copy, then
# delivers the Windows sources the tip does not carry the way a Windows
# adoption does: E143 and E152 from the audited-tip blobs and E161 from
# C:\lab-in\sources, saved into history (never published). Drives the module
# from its live path through the #374 acceptance checks with filesystem checks
# made here, outside the module. Writes key=value results and logs to
# C:\lab-out; pass=yes only when every check holds.
$ErrorActionPreference = 'Stop'
$in = 'C:\lab-in'
$out = 'C:\lab-out'
$lab = 'C:\lab'
$results = Join-Path $out 'sandbox-windows-applications.txt'
$script:fails = @()
function Say([string]$k, [string]$v) { Add-Content -LiteralPath $results -Value "$k=$v" -Encoding ASCII }
function Check([string]$k, $actual, $expected) {
	Say $k "$actual"
	if ("$actual" -ne "$expected") { $script:fails += $k }
}
function Run([string]$name, [string]$exe, [string[]]$argv) {
	$ErrorActionPreference = 'Continue'
	$o = & $exe @argv 2>&1 | ForEach-Object { "$_" }
	$code = $LASTEXITCODE
	[IO.File]::WriteAllText((Join-Path $out "$name.log"), (($o -join "`n") + "`n"))
	Say "${name}_exit" $code
	$code
}
function Log([string]$name) { [IO.File]::ReadAllText((Join-Path $out "$name.log")) }
function Live([string]$tilde) { Join-Path $env:USERPROFILE ($tilde.Substring(2) -replace '/', '\') }
function Hash([string]$p) { if (Test-Path -LiteralPath $p -PathType Leaf) { (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash } else { 'missing' } }
function LinkOf([string]$p) {
	$i = Get-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue
	if (-not $i) { return 'absent' }
	if (-not $i.LinkType) { return 'plain' }
	"$($i.LinkType)->$(@($i.Target)[0])"
}
# One fresh PowerShell 7 process per module command; objects print as name=value lines.
function Mod([string]$name, [string]$cmd) {
	$fmt = ' | ForEach-Object { ($_.PSObject.Properties | ForEach-Object { $_.Name + ''='' + $_.Value }) -join '' | '' }'
	Run $name $pwsh @('-NoProfile', '-NonInteractive', '-Command', ("Import-Module '$mod'; " + $cmd + $fmt))
}
function Quarantined([string]$leaf, [string]$hash) {
	$q = Live '~/.local/state/mise/windows-applications/quarantine'
	@(Get-ChildItem -LiteralPath $q -Recurse -File -Filter $leaf -ErrorAction SilentlyContinue | Where-Object { (Hash $_.FullName) -eq $hash }).Count
}
$lf = New-Object Text.UTF8Encoding $false
try {
	Start-Transcript -LiteralPath (Join-Path $out 'transcript.txt') | Out-Null
	New-Item -ItemType Directory -Path (Join-Path $lab 'bin'), (Join-Path $lab 'stub') -Force | Out-Null
	$p1 = Start-Process -FilePath 'C:\fixture-media\vc_redist.x64.exe' -ArgumentList '/install', '/quiet', '/norestart' -Wait -PassThru
	$p2 = Start-Process -FilePath 'C:\fixture-media\Git-2.55.0.3-64-bit.exe' -ArgumentList '/VERYSILENT', '/NORESTART', '/NOCANCEL', '/SP-', '/SUPPRESSMSGBOXES' -Wait -PassThru
	Say 'installs_exit' "$($p1.ExitCode),$($p2.ExitCode)"
	$git = 'C:\Program Files\Git\cmd\git.exe'
	Copy-Item -LiteralPath (Join-Path $in 'bin\mise.exe'), (Join-Path $in 'bin\mise-shim.exe') -Destination (Join-Path $lab 'bin')
	if (-not (Test-Path -LiteralPath (Join-Path $in 'bin\pwsh\pwsh.exe'))) { throw 'PowerShell 7 media is not staged (windows-media-pwsh-<version>)' }
	Copy-Item -LiteralPath (Join-Path $in 'bin\pwsh') -Destination (Join-Path $lab 'pwsh') -Recurse
	Copy-Item -LiteralPath (Join-Path $in 'exchange') -Destination (Join-Path $lab 'exchange') -Recurse
	$mise = Join-Path $lab 'bin\mise.exe'
	$pwsh = Join-Path $lab 'pwsh\pwsh.exe'
	$env:PATH = "$lab\bin;C:\Program Files\Git\cmd;$env:PATH"
	$env:MISE_HISTORY_SYNC = 'manual'
	$env:MISE_AUTO_INSTALL = '0'
	$env:GIT_CONFIG_NOSYSTEM = '1'
	$env:GIT_CONFIG_GLOBAL = Join-Path $lab 'gitconfig'
	$env:GIT_TERMINAL_PROMPT = '0'
	Set-Location -LiteralPath $lab

	$ex = 'C:/lab/exchange'
	$gh = 'https://github.com'
	$cfg = @('[protocol]', "`tallow = never", '[protocol "file"]', "`tallow = always", '[user]', "`tname = Lab", "`temail = lab@localhost")
	$repos = @(Get-Content -LiteralPath (Join-Path $in 'repos.txt') | Where-Object { $_.Trim() })
	foreach ($repo in $repos) {
		$cfg += "[url `"$ex/mirrors/$repo.git`"]", "`tinsteadOf = $gh/$repo"
		$cfg += "[url `"$ex/mirrors/$repo.git`"]", "`tinsteadOf = $gh/$repo.git"
	}
	foreach ($origin in 'https://github.com/bryan-hoang/dotfiles', 'ssh://git@github.com/bryan-hoang/dotfiles') {
		$cfg += "[url `"$ex/setup.git`"]", "`tinsteadOf = $origin"
	}
	[IO.File]::WriteAllText($env:GIT_CONFIG_GLOBAL, (($cfg -join "`n") + "`n"), $lf)
	Run 'version' $mise @('--version') | Out-Null
	Run 'pwsh_version' $pwsh @('-NoProfile', '-Command', '$PSVersionTable.PSVersion.ToString()') | Out-Null
	Say 'pwsh' (Log 'pwsh_version').Trim()
	$seed = (& $git -C "$ex/setup.git" rev-parse main)
	$tip = (& $git -C "$ex/setup.git" rev-parse "$seed^")
	Say 'seed_tip' $seed
	Say 'audited_tip' $tip
	Check 'seed_windows_stream_files' (@(& $git -C "$ex/setup.git" ls-tree -r --name-only $seed -- 'home@windows' 'config@windows').Count) 0

	Check 'adopt_exit' (Run 'adopt' $mise @('bootstrap', '--adopt', 'https://github.com/bryan-hoang/dotfiles', '--yes', '--skip', 'tools')) 0

	# Windows sources: E143 and E152 from audited-tip blobs, E161 from lab-in.
	$sources = @(
		@{ Live = '~/.config/mintty/config'; Spec = "${tip}:.config/mintty/config" }
		@{ Live = '~/.config/pwsh/Microsoft.PowerShell_profile.ps1'; Spec = "${tip}:.config/pwsh/Microsoft.PowerShell_profile.ps1" }
	)
	foreach ($s in $sources) {
		$dest = Live $s.Live
		New-Item -ItemType Directory -Path (Split-Path $dest) -Force | Out-Null
		$p = Start-Process -FilePath $git -ArgumentList @('-C', "$ex/setup.git", 'cat-file', 'blob', $s.Spec) -RedirectStandardOutput $dest -NoNewWindow -Wait -PassThru
		Check "source_exact_$($s.Live)" ((& $git hash-object --no-filters -- $dest) -eq (& $git -C "$ex/setup.git" rev-parse $s.Spec)) 'True'
	}
	$modLive = '~/.config/mise/dotfiles/.config/windows/WindowsApplications.psm1'
	$mod = Live $modLive
	New-Item -ItemType Directory -Path (Split-Path $mod) -Force | Out-Null
	Copy-Item -LiteralPath (Join-Path $in 'sources\.config\mise\dotfiles\.config\windows\WindowsApplications.psm1') -Destination $mod
	Check 'save_windows_sources_exit' (Run 'save_windows' $mise @('dot', 'save', '--description', 'Windows sources', $mod, (Live '~/.config/mintty/config'), (Live '~/.config/pwsh/Microsoft.PowerShell_profile.ps1'))) 0
	$H = Live '~/.local/state/mise/history/repo.git'
	$histMod = (& $git -C $H rev-parse 'main:config@windows/dotfiles/.config/windows/WindowsApplications.psm1')
	Check 'history_module_blob_matches_source' ($histMod -eq (& $git hash-object --no-filters -- $mod)) 'True'

	$profileDest = (& $pwsh -NoProfile -Command '$PROFILE.CurrentUserCurrentHost')
	$minttyDest = Join-Path $env:APPDATA 'mintty'
	$topDest = Join-Path $env:APPDATA 'topgrade.toml'
	$profileSrc = Live '~/.config/pwsh/Microsoft.PowerShell_profile.ps1'
	$minttySrc = Live '~/.config/mintty'
	$topSrc = Live '~/.config/topgrade/topgrade.toml'
	$state = Live '~/.local/state/mise/windows-applications'
	$flags = Live '~/.config/mise/config.windows.local.toml'
	[IO.File]::WriteAllText($flags, "# lab-marker-374-local`n[vars.windows_applications]`ntopgrade = true`n", $lf)
	Mod 'pathmap' 'Get-WindowsApplicationsPathMap' | Out-Null

	# Criterion 2: a preflight failure changes no destination in its unit.
	New-Item -ItemType Directory -Path $minttyDest -Force | Out-Null
	[IO.File]::WriteAllText((Join-Path $minttyDest 'occupant.txt'), "unmanaged`n", $lf)
	$occ = Hash (Join-Path $minttyDest 'occupant.txt')
	Check 'c2_base_occupied_exit' (Mod 'c2_base_occupied' 'Invoke-WindowsApplications apply -Unit base') 1
	Check 'c2_base_profile_dest' (LinkOf $profileDest) 'absent'
	Check 'c2_base_mintty_dest' (LinkOf $minttyDest) 'plain'
	Check 'c2_base_occupant_unchanged' ((Hash (Join-Path $minttyDest 'occupant.txt')) -eq $occ) 'True'
	Check 'c2_base_state_written' (Test-Path -LiteralPath (Join-Path $state 'base.json')) 'False'
	Remove-Item -LiteralPath $minttyDest -Recurse -Force
	Check 'c2_app_missing_exit' (Mod 'c2_app_missing' 'Invoke-WindowsApplications apply') 1
	Check 'c2_app_missing_reported' ((Log 'c2_app_missing') -match 'missing application topgrade') 'True'
	Check 'c2_app_topgrade_dest' (LinkOf $topDest) 'absent'
	Check 'c2_app_base_still_applied' (LinkOf $profileDest) "SymbolicLink->$profileSrc"

	# Criterion 1: base then application create verified links/junctions and a copy-ok copy.
	Copy-Item -LiteralPath "$env:WINDIR\System32\whoami.exe" -Destination (Join-Path $lab 'stub\topgrade.exe')
	$env:PATH = "$lab\stub;$env:PATH"
	Check 'c1_apply_exit' (Mod 'c1_apply' 'Invoke-WindowsApplications apply') 0
	Check 'c1_status_exit' (Mod 'c1_status' 'Invoke-WindowsApplications status') 0
	Check 'c1_status_ok_rows' ([regex]::Matches((Log 'c1_status'), 'State=ok').Count) 3
	Check 'c1_profile_link' (LinkOf $profileDest) "SymbolicLink->$profileSrc"
	Check 'c1_mintty_junction' (LinkOf $minttyDest) "Junction->$minttySrc"
	Check 'c1_mintty_through_junction' ((Hash (Join-Path $minttyDest 'config')) -eq (Hash (Join-Path $minttySrc 'config'))) 'True'
	Check 'c1_topgrade_copy' (LinkOf $topDest) 'plain'
	Check 'c1_topgrade_readonly' (Get-Item -LiteralPath $topDest).IsReadOnly 'True'
	Check 'c1_topgrade_bytes' ((Hash $topDest) -eq (Hash $topSrc)) 'True'
	Check 'c1_reapply_exit' (Mod 'c1_reapply' 'Invoke-WindowsApplications apply') 0
	Check 'c1_reapply_noop_rows' ([regex]::Matches((Log 'c1_reapply'), 'Action=none').Count) 3

	# Flag off: apply reports owned paths and changes none, even a changed one; no quarantine.
	[IO.File]::WriteAllText($flags, "# lab-marker-374-local`n[vars.windows_applications]`ntopgrade = false`n", $lf)
	$topHash = Hash $topDest
	Check 'f_off_apply_exit' (Mod 'f_off_apply' 'Invoke-WindowsApplications apply') 0
	Check 'f_off_reported' ([regex]::Matches((Log 'f_off_apply'), 'Unit=topgrade .*State=ok .*Action=owned; flag off').Count) 1
	Check 'f_off_kept' ((LinkOf $topDest) + ':' + (Get-Item -LiteralPath $topDest).IsReadOnly + ':' + ((Hash $topDest) -eq $topHash)) 'plain:True:True'
	(Get-Item -LiteralPath $topDest).IsReadOnly = $false
	[IO.File]::AppendAllText($topDest, "# local edit while off`n")
	$offChanged = Hash $topDest
	Check 'f_off_changed_apply_exit' (Mod 'f_off_changed_apply' 'Invoke-WindowsApplications apply') 0
	Check 'f_off_changed_reported' ([regex]::Matches((Log 'f_off_changed_apply'), 'Unit=topgrade .*State=changed .*Action=owned; flag off').Count) 1
	Check 'f_off_changed_kept' ((Hash $topDest) -eq $offChanged) 'True'
	Check 'f_off_quarantine_entries' (@(Get-ChildItem -LiteralPath (Join-Path $state 'quarantine') -Recurse -File -ErrorAction SilentlyContinue).Count) 0
	Copy-Item -LiteralPath $topSrc -Destination $topDest -Force
	(Get-Item -LiteralPath $topDest).IsReadOnly = $true
	[IO.File]::WriteAllText($flags, "# lab-marker-374-local`n[vars.windows_applications]`ntopgrade = true`n", $lf)
	Mod 'f_on_status' 'Invoke-WindowsApplications status' | Out-Null
	Check 'f_on_status_ok_rows' ([regex]::Matches((Log 'f_on_status'), 'State=ok').Count) 3

	# Criterion 3: a replaced managed link makes validate quarantine, block, stop the watcher, exit nonzero.
	[IO.File]::Delete($profileDest)
	[IO.File]::WriteAllText($profileDest, "# replaced by the lab`n", $lf)
	$drift = Hash $profileDest
	$w = Start-Process -FilePath $mise -ArgumentList 'dot', 'watch' -PassThru -RedirectStandardOutput (Join-Path $out 'watch.log') -RedirectStandardError (Join-Path $out 'watch.err.log')
	Start-Sleep -Seconds 8
	Say 'c3_watcher_running_before' (-not $w.HasExited)
	Check 'c3_validate_exit' (Mod 'c3_validate' 'Invoke-WindowsApplications validate') 1
	Check 'c3_sentinel' (Test-Path -LiteralPath (Join-Path $state 'blocked')) 'True'
	Check 'c3_quarantined_copy' (Quarantined 'Microsoft.PowerShell_profile.ps1' $drift) 1
	Check 'c3_native_path_kept' ((LinkOf $profileDest) + ':' + ((Hash $profileDest) -eq $drift)) 'plain:True'
	Start-Sleep -Seconds 2
	Check 'c3_watcher_stopped' $w.HasExited 'True'
	Say 'c3_validate_watcher_message' ([regex]::Match((Log 'c3_validate'), 'watcher: [^\r\n]*').Value)
	foreach ($v in 'status', 'apply', 'unapply', 'validate') {
		Check "c3_blocked_${v}_exit" (Mod "c3_blocked_$v" "Invoke-WindowsApplications $v") 1
		Check "c3_blocked_${v}_refused" ((Log "c3_blocked_$v") -match 'blocked by drift sentinel') 'True'
	}
	[IO.File]::Copy((Join-Path $state 'blocked'), (Join-Path $out 'sentinel.txt'))
	[IO.File]::Delete($profileDest)
	[IO.File]::Delete((Join-Path $state 'blocked'))
	Check 'c3_resolved_apply_exit' (Mod 'c3_resolved_apply' 'Invoke-WindowsApplications apply -Unit base') 0
	Check 'c3_resolved_validate_exit' (Mod 'c3_resolved_validate' 'Invoke-WindowsApplications validate') 0

	# Criterion 4: unapply removes owned unchanged resources and holds a changed one.
	$heads = @($repos | ForEach-Object { & $git -C (Live "~/src/github.com/$_") rev-parse HEAD }) -join ','
	$histHead = (& $git -C $H rev-parse main)
	$srcHashes = (Hash $profileSrc) + (Hash (Join-Path $minttySrc 'config')) + (Hash $topSrc)
	(Get-Item -LiteralPath $topDest).IsReadOnly = $false
	[IO.File]::AppendAllText($topDest, "# local edit`n")
	$changed = Hash $topDest
	Check 'c4_unapply_changed_exit' (Mod 'c4_unapply_changed' 'Invoke-WindowsApplications unapply -Unit topgrade') 1
	Check 'c4_changed_held' ((Hash $topDest) -eq $changed) 'True'
	Check 'c4_changed_quarantined_copy' (Quarantined 'topgrade.toml' $changed) 1
	Check 'c4_unapply_owned_exit' (Mod 'c4_unapply_owned' 'Invoke-WindowsApplications unapply -Unit base') 0
	Check 'c4_profile_removed' (LinkOf $profileDest) 'absent'
	Check 'c4_mintty_removed' (LinkOf $minttyDest) 'absent'
	Check 'c4_sources_unchanged' (((Hash $profileSrc) + (Hash (Join-Path $minttySrc 'config')) + (Hash $topSrc)) -eq $srcHashes) 'True'
	Check 'c4_git_still_installed' (Test-Path -LiteralPath $git) 'True'
	Check 'c4_app_still_installed' (Test-Path -LiteralPath (Join-Path $lab 'stub\topgrade.exe')) 'True'
	Check 'c4_repos_not_rewound' ((@($repos | ForEach-Object { & $git -C (Live "~/src/github.com/$_") rev-parse HEAD }) -join ',') -eq $heads) 'True'
	Check 'c4_history_not_rewound' ((& $git -C $H rev-parse main) -eq $histHead) 'True'

	# Criterion 5: no watcher declared; no local input or module state reaches history.
	Check 'c5_module_declares_service' ([IO.File]::ReadAllText($mod) -match '\[bootstrap\.services') 'False'
	Run 'c5_services' $mise @('bootstrap', 'services', 'status') | Out-Null
	Check 'c5_final_save_exit' (Run 'c5_final_save' $mise @('dot', 'save', '--description', 'Lab final')) 0
	Check 'c5_history_local_paths' (@(& $git -C $H log --all --name-only --format= | Where-Object { $_ -match 'windows-applications|config\.windows\.local|quarantine' }).Count) 0
	Check 'c5_history_marker_commits' (@(& $git -C $H log --all -S 'lab-marker-374-local' --format=%H).Count) 0
	Run 'c5_status' $mise @('dot', 'status', '--json') | Out-Null
	Check 'c5_status_mentions_local' ((Log 'c5_status') -match 'windows-applications|config\.windows\.local') 'False'
	Copy-Item -LiteralPath (Join-Path $state 'quarantine\log.tsv') -Destination (Join-Path $out 'quarantine-log.tsv')
	Say 'done' 'yes'
}
catch {
	Say 'error' $_.Exception.Message
	$script:fails += 'error'
}
finally {
	Say 'failed_checks' $(if ($script:fails.Count) { $script:fails -join ',' } else { 'none' })
	Say 'pass' $(if ($script:fails.Count) { 'no' } else { 'yes' })
	try { Stop-Transcript | Out-Null } catch { }
	shutdown.exe /s /t 5
}
