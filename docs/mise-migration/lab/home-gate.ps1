#Requires -Version 7.0
# Home gate (#358 gate 1 and the WSL peer gate). Rerunnable and read-mostly:
# its key=value output is the evidence, and it never prints a local-input or
# identity value. Exit 0 only when every check passes. In order:
#   1. history: watcher not-declared, sync manual, 0 conflicts, and the local
#      head contains -ConversionCommit;
#   2. the core local inputs (config.local.toml, machine.gitconfig, and on
#      Windows config.windows.local.toml) exist and no history ref touches
#      their paths;
#   2b. the E178 check (~/.config/mise/sanitized.ps1) finds no unknown field,
#      unreviewed pinned value, or broken include in a sanitized source;
#   3. Windows: E161 `Invoke-WindowsApplications validate` exits 0 and no drift
#      sentinel exists. Linux: a systemd user session answers
#      (-AllowNoSystemdUser reports an unavailable one without failing);
#   4. test edit, only when 1-3 pass: a comment line appended to -TestPath (an
#      autosave-on Windows-variant root, or Linux-variant on Linux) and saved
#      with a name creates a checkpoint in home@<os>; `rollback -n` changes
#      nothing, `rollback` restores the pre-gate hash, `undo` restores the
#      edit's hash, and a final rollback and save leave the pre-gate hash live
#      and in the head. The checkpoints stay in history;
#   5. `mise dot status --json` and `mise doctor --json` report no history
#      problem;
#   6. identity: machine.gitconfig selects the public identity (E013), or with
#      -Identity work a valid identity that is not the public one and whose
#      email no history ref contains.
param(
	[Parameter(Mandatory)][string]$ConversionCommit,
	[ValidateSet('public', 'work')][string]$Identity = 'public',
	[string]$TestPath,
	[switch]$AllowNoSystemdUser
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = $OutputEncoding = [Text.UTF8Encoding]::new($false)
$failed = [Collections.Generic.List[string]]::new()
function Say([string]$k, $v) { Write-Output "$k=$v" }
function Check([string]$k, [bool]$ok, $v) {
	Say $k $v
	if (-not $ok) { $failed.Add($k) }
}
function YesNo([bool]$b) { if ($b) { 'yes' } else { 'no' } }
# Runs a native command; stdout only, stderr dropped so no value leaks.
function Native([string]$exe, [string[]]$argv) {
	$ErrorActionPreference = 'Continue'
	$o = & $exe @argv 2>$null
	[pscustomobject]@{ Code = $LASTEXITCODE; Out = (@($o) -join "`n") }
}
function Live([string]$tilde) { Join-Path $HOME $tilde.Substring(2) }
function Blob([string]$path) { (Native git @('hash-object', '--no-filters', '--', $path)).Out }
function Status { Native mise @('dot', 'status', '--json') }

$os = if ($IsWindows) { 'windows' } else { 'linux' }
$stateHome = if (-not $IsWindows -and $env:XDG_STATE_HOME) { $env:XDG_STATE_HOME } else { Join-Path $HOME '.local/state' }
$hist = Join-Path $stateHome 'mise/history/repo.git'
Say 'os' $os
Say 'mise' ((Native mise @('--version')).Out -split ' ')[0]

# 1. History state.
$s = Status
$h = if ($s.Code -eq 0) { ($s.Out | ConvertFrom-Json).history } else { $null }
Check 'status_exit' ($s.Code -eq 0) $s.Code
Check 'watcher' ($h -and $h.watcher -eq 'not-declared') $(if ($h) { $h.watcher } else { 'unknown' })
Check 'sync_mode' ($h -and $h.sync.mode -eq 'manual') $(if ($h) { $h.sync.mode } else { 'unknown' })
$conflicts = if ($h) { @($h.sync.conflicts).Count } else { -1 }
Check 'conflicts' ($conflicts -eq 0) $conflicts
$contains = (Test-Path -LiteralPath $hist) -and
	(Native git @('-C', $hist, 'cat-file', '-e', "$ConversionCommit^{commit}")).Code -eq 0 -and
	(Native git @('-C', $hist, 'merge-base', '--is-ancestor', $ConversionCommit, 'main')).Code -eq 0
Check 'head_contains_conversion' $contains (YesNo $contains)

# 2. Core local inputs: present, and no commit on any history ref touches them.
$inputs = [ordered]@{
	config_local_toml = '~/.config/mise/config.local.toml'
	machine_gitconfig = '~/.config/git/machine.gitconfig'
}
if ($IsWindows) { $inputs.config_windows_local_toml = '~/.config/mise/config.windows.local.toml' }
foreach ($k in $inputs.Keys) {
	$present = Test-Path -LiteralPath (Live $inputs[$k]) -PathType Leaf
	Check "local_input_$k" $present $(if ($present) { 'present' } else { 'missing' })
	$leaf = Split-Path $inputs[$k] -Leaf
	$n = @((Native git @('-C', $hist, 'log', '--all', '--format=%H', '--', ":(glob)**/$leaf")).Out -split "`n" | Where-Object { $_ }).Count
	Check "local_input_${k}_history_commits" ($n -eq 0) $n
}

# 2b. Sanitized sources: the E178 check prints row, path, and problem class
# only, never a field name or value.
$sanitizer = Live '~/.config/mise/sanitized.ps1'
if (Test-Path -LiteralPath $sanitizer -PathType Leaf) {
	$c = Native (Get-Process -Id $PID).Path @('-NoProfile', '-NonInteractive', '-File', $sanitizer, 'check')
	$problems = @($c.Out -split "`n" | Where-Object { $_ -match '^E\d{3} \S+: [a-z-]+$' })
	foreach ($p in $problems) { Say 'sanitized_problem' $p }
	Check 'sanitized_check_exit' ($c.Code -eq 0) $c.Code
	Check 'sanitized_problems' ($c.Code -eq 0 -and $problems.Count -eq 0) $problems.Count
}
else { Check 'sanitized_check' $false 'missing' }

# 3. Platform control.
if ($IsWindows) {
	$sentinel = Live '~/.local/state/mise/windows-applications/blocked'
	Check 'e161_sentinel_before' (-not (Test-Path -LiteralPath $sentinel)) $(if (Test-Path -LiteralPath $sentinel) { 'present' } else { 'absent' })
	$module = Live '~/.config/mise/dotfiles/.config/windows/WindowsApplications.psm1'
	# Single-quoted literal with apostrophes doubled, so any HOME path is safe.
	$v = Native (Get-Process -Id $PID).Path @('-NoProfile', '-NonInteractive', '-Command',
		"Import-Module '$($module -replace "'", "''")'; Invoke-WindowsApplications validate | Out-Null")
	Check 'e161_validate_exit' ($v.Code -eq 0) $v.Code
	Check 'e161_sentinel' (-not (Test-Path -LiteralPath $sentinel)) $(if (Test-Path -LiteralPath $sentinel) { 'present' } else { 'absent' })
}
else {
	$u = if (Get-Command systemctl -ErrorAction SilentlyContinue) { (Native systemctl @('--user', 'is-system-running')).Out.Trim() } else { '' }
	$state = if ($u -in 'running', 'degraded', 'starting', 'initializing', 'maintenance', 'stopping') { $u } else { 'unavailable' }
	Check 'systemd_user' ($state -ne 'unavailable' -or $AllowNoSystemdUser) $state
	if ($state -eq 'unavailable' -and $AllowNoSystemdUser) { Say 'systemd_user_unavailable_allowed' 'yes' }
}

# 4. Test edit on an autosave-on root of this platform's variant.
if (-not $TestPath) { $TestPath = if ($IsWindows) { '~/.config/mintty/config' } else { '~/.config/zsh/.zshrc' } }
$file = if ($TestPath.StartsWith('~')) { Live $TestPath } else { $TestPath }
$rel = [IO.Path]::GetRelativePath($HOME, $file) -replace '\\', '/'
$stream = if ($rel.StartsWith('.config/mise/')) { "config@$os/" + $rel.Substring(13) } else { "home@$os/$rel" }
Say 'test_stream_root' "$($stream.Split('/')[0])"
if ($failed.Count) { Say 'test_edit' 'skipped' }
elseif (-not (Test-Path -LiteralPath $file -PathType Leaf)) { Check 'test_edit' $false 'missing-root' }
else {
	$pre = Blob $file
	$orig = [IO.File]::ReadAllBytes($file)
	$headBlob = { (Native git @('-C', $hist, 'rev-parse', '-q', '--verify', "main:$stream")).Out }
	Check 'test_root_saved' ((& $headBlob) -eq $pre) (YesNo ((& $headBlob) -eq $pre))
	if (-not $failed.Count) {
		try {
			$before = ($(Status).Out | ConvertFrom-Json).history.latest.id
			$stamp = Get-Date -Format 'yyyyMMddHHmmss'
			[IO.File]::AppendAllText($file, "`n# home-gate test edit $stamp`n")
			$edit = Blob $file
			$r = Native mise @('dot', 'save', '--description', 'home-gate test edit', '--label', "home-gate-$stamp", $file)
			Check 'test_save_exit' ($r.Code -eq 0) $r.Code
			$after = ($(Status).Out | ConvertFrom-Json).history.latest.id
			Check 'test_checkpoint_created' ($after -gt $before) (YesNo ($after -gt $before))
			Check 'test_checkpoint_in_stream' ((& $headBlob) -eq $edit) (YesNo ((& $headBlob) -eq $edit))
			$r = Native mise @('dot', 'rollback', '-n', $file)
			Check 'rollback_dry_run_exit' ($r.Code -eq 0) $r.Code
			Check 'rollback_dry_run_unchanged' ((Blob $file) -eq $edit) (YesNo ((Blob $file) -eq $edit))
			$r = Native mise @('dot', 'rollback', '--yes', $file)
			Check 'rollback_exit' ($r.Code -eq 0) $r.Code
			Check 'rollback_restores_pre_gate_hash' ((Blob $file) -eq $pre) (YesNo ((Blob $file) -eq $pre))
			$r = Native mise @('dot', 'undo', '--yes')
			Check 'undo_exit' ($r.Code -eq 0) $r.Code
			Check 'undo_restores_edit_hash' ((Blob $file) -eq $edit) (YesNo ((Blob $file) -eq $edit))
			$r = Native mise @('dot', 'rollback', '--yes', $file)
			Check 'remove_edit_exit' ($r.Code -eq 0) $r.Code
			$r = Native mise @('dot', 'save', '--description', 'home-gate test edit removed', $file)
			Check 'remove_edit_save_exit' ($r.Code -eq 0) $r.Code
		}
		finally {
			# Never leave the test edit behind, even after a failed step.
			if ((Blob $file) -ne $pre) { [IO.File]::WriteAllBytes($file, $orig); Check 'test_restored_by_gate' $false 'yes' }
		}
		Check 'test_final_hash_is_pre_gate' ((Blob $file) -eq $pre) (YesNo ((Blob $file) -eq $pre))
		Check 'test_head_is_pre_gate' ((& $headBlob) -eq $pre) (YesNo ((& $headBlob) -eq $pre))
	}
}

# 5. Status and doctor report no history problem.
$s = Status
$h = if ($s.Code -eq 0) { ($s.Out | ConvertFrom-Json).history } else { $null }
$problems = if (-not $h) { -1 } else {
	@($h.sync.conflicts).Count + @($h.sync.pending_applications).Count +
	@($h.unavailable, $h.sync.last_error, $h.sync.validation_error, $h.sync.application_failure | Where-Object { $null -ne $_ }).Count
}
Check 'status_history_problems' ($problems -eq 0) $problems
$d = Native mise @('doctor', '--json')
$doc = try { $d.Out | ConvertFrom-Json } catch { $null }
$dp = if (-not $doc -or -not $doc.PSObject.Properties['dotfiles']) { -1 } else {
	$msgs = @(foreach ($n in 'errors', 'warnings') { if ($doc.PSObject.Properties[$n]) { $doc.$n } })
	$df = $doc.dotfiles
	@($msgs | Where-Object { "$_" -like 'dotfiles:*' }).Count + @($df.sync_conflicts).Count + [int][bool]$df.stale +
	@($df.unavailable, $df.last_error, $df.sync_error | Where-Object { $null -ne $_ }).Count
}
Check 'doctor_history_problems' ($dp -eq 0) $dp

# 6. Identity selected by machine.gitconfig; values are compared, never printed.
Say 'identity_mode' $Identity
$machine = Live '~/.config/git/machine.gitconfig'
$personal = Live '~/.config/mise/dotfiles/.config/git/personal.gitconfig'
function GitGet([string]$f, [string]$key) { if (Test-Path -LiteralPath $f) { (Native git @('config', '--file', $f, '--includes', '--get', $key)).Out } else { '' } }
$email = GitGet $machine 'user.email'
$name = GitGet $machine 'user.name'
$valid = $email -match '^[^@\s]+@[^@\s]+\.[^@\s]+$' -and $name.Trim()
Check 'identity_valid' $valid (YesNo $valid)
$isPublic = $valid -and $email -eq (GitGet $personal 'user.email') -and $name -eq (GitGet $personal 'user.name')
if ($Identity -eq 'public') { Check 'identity_selects_public' $isPublic (YesNo $isPublic) }
else {
	Check 'identity_selects_work' ($valid -and -not $isPublic) (YesNo ($valid -and -not $isPublic))
	$n = if ($valid) { @((Native git @('-C', $hist, 'log', '--all', '--format=%H', "-S$email")).Out -split "`n" | Where-Object { $_ }).Count } else { -1 }
	Check 'identity_history_commits' ($n -eq 0) $n
}

Say 'failed_checks' $(if ($failed.Count) { $failed -join ',' } else { 'none' })
Say 'gate' $(if ($failed.Count) { 'fail' } else { 'pass' })
exit [int][bool]$failed.Count
