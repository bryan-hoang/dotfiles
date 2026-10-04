# Home gate (#376) run for Windows Sandbox (Windows PowerShell 5.1, ASCII only;
# the gate runs in the staged PowerShell 7 from C:\lab-in\bin\pwsh). Stage the
# gate with the runner's -Bin <lab>\home-gate.ps1. Adopts the conversion from
# the exchange copy, captures the Windows roots the tip does not carry (E143,
# E152 from audited-tip blobs, E161 from C:\lab-in\sources) with a named save,
# writes lab local inputs, applies the E161 base unit, then runs the gate:
# clean (pass, exact pre-gate hash), each injected fault (a missing core local
# input, a local-input path in history, an unknown field in a sanitized source,
# drift with its sentinel, a conflict),
# and the work identity. No gate output may contain a local-input or identity
# value. Writes key=value results and logs to C:\lab-out; pass=yes only when
# every check holds. A run takes about 50 minutes (each passing gate about 6):
# give the runner -TimeoutMinutes 90.
$ErrorActionPreference = 'Stop'
$in = 'C:\lab-in'
$out = 'C:\lab-out'
$lab = 'C:\lab'
$results = Join-Path $out 'sandbox-home-gate.txt'
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
function Blob([string]$p) { (& $git hash-object --no-filters -- $p) }
$lf = New-Object Text.UTF8Encoding $false
# Values the gate must never print.
$secrets = @('lab-marker-376-local', 'lab-work-376@example.invalid', 'Lab Work 376', 'lab-proxy-376.invalid', 'bryan@bryanhoang.dev', 'Bryan Hoang')
# Runs the gate; returns its exit code and records gate, failed_checks, and leaks.
function Gate([string]$name, [string[]]$extra) {
	$code = Run $name $pwsh (@('-NoProfile', '-NonInteractive', '-File', (Join-Path $lab 'home-gate.ps1'), '-ConversionCommit', $seed) + $extra)
	$text = Log $name
	Say "${name}_result" ([regex]::Match($text, '(?m)^gate=(.*)$').Groups[1].Value.Trim())
	Say "${name}_failed" ([regex]::Match($text, '(?m)^failed_checks=(.*)$').Groups[1].Value.Trim())
	Check "${name}_leaks" (@($secrets | Where-Object { $text.Contains($_) }).Count) 0
	Check "${name}_non_kv_lines" (@($text -split "`n" | Where-Object { $_ -and $_ -notmatch '^[a-z0-9_]+=' }).Count) 0
	$code
}
function Value([string]$name, [string]$key) { [regex]::Match((Log $name), "(?m)^$key=(.*)$").Groups[1].Value.Trim() }
function Mod([string]$name, [string]$cmd) {
	Run $name $pwsh @('-NoProfile', '-NonInteractive', '-Command', "Import-Module '$mod'; $cmd | Out-Null")
}
try {
	Start-Transcript -LiteralPath (Join-Path $out 'transcript.txt') | Out-Null
	New-Item -ItemType Directory -Path (Join-Path $lab 'bin') -Force | Out-Null
	$p1 = Start-Process -FilePath 'C:\fixture-media\vc_redist.x64.exe' -ArgumentList '/install', '/quiet', '/norestart' -Wait -PassThru
	$p2 = Start-Process -FilePath 'C:\fixture-media\Git-2.55.0.3-64-bit.exe' -ArgumentList '/VERYSILENT', '/NORESTART', '/NOCANCEL', '/SP-', '/SUPPRESSMSGBOXES' -Wait -PassThru
	Say 'installs_exit' "$($p1.ExitCode),$($p2.ExitCode)"
	$git = 'C:\Program Files\Git\cmd\git.exe'
	Copy-Item -LiteralPath (Join-Path $in 'bin\mise.exe'), (Join-Path $in 'bin\mise-shim.exe') -Destination (Join-Path $lab 'bin')
	Copy-Item -LiteralPath (Join-Path $in 'bin\home-gate.ps1') -Destination $lab
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
	foreach ($repo in @(Get-Content -LiteralPath (Join-Path $in 'repos.txt') | Where-Object { $_.Trim() })) {
		$cfg += "[url `"$ex/mirrors/$repo.git`"]", "`tinsteadOf = $gh/$repo"
		$cfg += "[url `"$ex/mirrors/$repo.git`"]", "`tinsteadOf = $gh/$repo.git"
	}
	foreach ($origin in 'https://github.com/bryan-hoang/dotfiles', 'ssh://git@github.com/bryan-hoang/dotfiles') {
		$cfg += "[url `"$ex/setup.git`"]", "`tinsteadOf = $origin"
	}
	[IO.File]::WriteAllText($env:GIT_CONFIG_GLOBAL, (($cfg -join "`n") + "`n"), $lf)
	Run 'version' $mise @('--version') | Out-Null
	$seed = (& $git -C "$ex/setup.git" rev-parse main)
	$tip = (& $git -C "$ex/setup.git" rev-parse "$seed^")
	Say 'conversion_commit' $seed
	Check 'adopt_exit' (Run 'adopt' $mise @('bootstrap', '--adopt', 'https://github.com/bryan-hoang/dotfiles', '--yes', '--skip', 'tools')) 0

	# Phase F capture: the Windows roots, saved by name.
	foreach ($s in @(
			@{ Live = '~/.config/mintty/config'; Spec = "${tip}:.config/mintty/config" }
			@{ Live = '~/.config/pwsh/Microsoft.PowerShell_profile.ps1'; Spec = "${tip}:.config/pwsh/Microsoft.PowerShell_profile.ps1" }
		)) {
		$dest = Live $s.Live
		New-Item -ItemType Directory -Path (Split-Path $dest) -Force | Out-Null
		Start-Process -FilePath $git -ArgumentList @('-C', "$ex/setup.git", 'cat-file', 'blob', $s.Spec) -RedirectStandardOutput $dest -NoNewWindow -Wait | Out-Null
	}
	$mod = Live '~/.config/mise/dotfiles/.config/windows/WindowsApplications.psm1'
	New-Item -ItemType Directory -Path (Split-Path $mod) -Force | Out-Null
	Copy-Item -LiteralPath (Join-Path $in 'sources\.config\mise\dotfiles\.config\windows\WindowsApplications.psm1') -Destination $mod
	Check 'capture_exit' (Run 'capture' $mise @('dot', 'save', '--description', 'Windows roots', $mod, (Live '~/.config/mintty/config'), (Live '~/.config/pwsh/Microsoft.PowerShell_profile.ps1'))) 0

	# Lab local inputs (synthetic values; the marker and identities must never appear in gate output).
	$localToml = Live '~/.config/mise/config.local.toml'
	$machine = Live '~/.config/git/machine.gitconfig'
	$flags = Live '~/.config/mise/config.windows.local.toml'
	New-Item -ItemType Directory -Path (Split-Path $machine) -Force | Out-Null
	[IO.File]::WriteAllText($localToml, "# lab-marker-376-local`n[settings.history]`nsync = `"manual`"`n", $lf)
	$publicGit = "# lab-marker-376-local`n[include]`n`tpath = ~/.config/mise/dotfiles/.config/git/personal.gitconfig`n"
	[IO.File]::WriteAllText($machine, $publicGit, $lf)
	[IO.File]::WriteAllText($flags, "# lab-marker-376-local`n[vars.windows_applications]`ntopgrade = false`n", $lf)
	Check 'e161_base_apply_exit' (Mod 'e161_base_apply' 'Invoke-WindowsApplications apply -Unit base') 0
	$profileDest = (& $pwsh -NoProfile -Command '$PROFILE.CurrentUserCurrentHost')
	$H = Live '~/.local/state/mise/history/repo.git'
	$test = Live '~/.config/mintty/config'

	# Clean home: passes and leaves the exact pre-gate hash, live and in the head.
	$pre = Blob $test
	$ids = (& $git -C $H rev-list --count main)
	Check 'clean_exit' (Gate 'clean' @()) 0
	Check 'clean_final_hash_is_pre_gate' ((Blob $test) -eq $pre) 'True'
	Check 'clean_head_blob_is_pre_gate' ((& $git -C $H rev-parse 'main:home@windows/.config/mintty/config') -eq $pre) 'True'
	Check 'clean_checkpoints_added' ([int](& $git -C $H rev-list --count main) -gt [int]$ids) 'True'
	foreach ($k in 'watcher', 'sync_mode', 'conflicts', 'head_contains_conversion', 'e161_validate_exit', 'e161_sentinel', 'test_checkpoint_created', 'test_checkpoint_in_stream', 'rollback_dry_run_unchanged', 'rollback_restores_pre_gate_hash', 'undo_restores_edit_hash', 'status_history_problems', 'doctor_history_problems', 'identity_selects_public', 'sanitized_problems') {
		Say "clean_$k" (Value 'clean' $k)
	}
	Check 'clean_test_stream_root' (Value 'clean' 'test_stream_root') 'home@windows'

	# Fault: each missing core local input.
	foreach ($f in @(@{ K = 'config_local_toml'; P = $localToml }, @{ K = 'machine_gitconfig'; P = $machine }, @{ K = 'config_windows_local_toml'; P = $flags })) {
		Move-Item -LiteralPath $f.P -Destination "$($f.P).aside"
		Check "missing_$($f.K)_exit" (Gate "missing_$($f.K)" @()) 1
		Check "missing_$($f.K)_reported" (Value "missing_$($f.K)" "local_input_$($f.K)") 'missing'
		Check "missing_$($f.K)_test_edit" (Value "missing_$($f.K)" 'test_edit') 'skipped'
		Move-Item -LiteralPath "$($f.P).aside" -Destination $f.P
	}

	# Fault: a local-input path in history (a ref holding a checkpoint with it).
	$tmp = Join-Path $lab 'fault-blob.txt'
	[IO.File]::WriteAllText($tmp, "synthetic`n", $lf)
	$env:GIT_INDEX_FILE = Join-Path $lab 'fault.index'
	& $git -C $H read-tree main
	& $git -C $H update-index --add --cacheinfo "100644,$(& $git -C $H hash-object -w --no-filters $tmp),home@windows/.config/git/machine.gitconfig"
	$tree = (& $git -C $H write-tree)
	Remove-Item Env:GIT_INDEX_FILE
	& $git -C $H update-ref refs/heads/lab-fault (& $git -C $H commit-tree -p main -m 'lab fault' $tree)
	Check 'history_path_exit' (Gate 'history_path' @()) 1
	Check 'history_path_reported' (Value 'history_path' 'local_input_machine_gitconfig_history_commits') 1
	& $git -C $H update-ref -d refs/heads/lab-fault
	Check 'history_path_cleared_exit' (Gate 'history_path_cleared' @()) 0

	# Fault: an unknown field in a sanitized source (the E178 check). The gate
	# names the row, path, and class only, never the field name or value.
	$pip = Live '~/.config/mise/dotfiles/.config/pip/pip.conf'
	$reviewed = [IO.File]::ReadAllBytes($pip)
	[IO.File]::AppendAllText($pip, "proxy = http://lab-proxy-376.invalid:3128`n")
	Check 'sanitized_unknown_exit' (Gate 'sanitized_unknown' @()) 1
	Check 'sanitized_unknown_reported' (Value 'sanitized_unknown' 'sanitized_problem') 'E121 dotfiles/.config/pip/pip.conf: unknown-field'
	Check 'sanitized_unknown_name_printed' ([regex]::Matches((Log 'sanitized_unknown'), 'proxy').Count) 0
	Check 'sanitized_unknown_test_edit' (Value 'sanitized_unknown' 'test_edit') 'skipped'
	[IO.File]::WriteAllBytes($pip, $reviewed)

	# Fault: drift (a replaced managed link) writes the sentinel through validate.
	[IO.File]::Delete($profileDest)
	[IO.File]::WriteAllText($profileDest, "# replaced by the lab`n", $lf)
	Check 'drift_exit' (Gate 'drift' @()) 1
	Check 'drift_validate_exit' (Value 'drift' 'e161_validate_exit') 1
	Check 'drift_sentinel' (Value 'drift' 'e161_sentinel') 'present'
	Check 'drift_dest_moved' (Test-Path -LiteralPath $profileDest) 'False'
	Check 'sentinel_rerun_exit' (Gate 'sentinel_rerun' @()) 1
	Check 'sentinel_rerun_before' (Value 'sentinel_rerun' 'e161_sentinel_before') 'present'
	[IO.File]::Delete((Live '~/.local/state/mise/windows-applications/blocked'))
	Check 'drift_resolved_apply_exit' (Mod 'drift_resolved_apply' 'Invoke-WindowsApplications apply -Unit base') 0
	Check 'drift_resolved_exit' (Gate 'drift_resolved' @()) 0

	# Identity: a work identity passes in work mode and fails in public mode.
	[IO.File]::WriteAllText($machine, "# lab-marker-376-local`n[user]`n`tname = Lab Work 376`n`temail = lab-work-376@example.invalid`n", $lf)
	Check 'work_exit' (Gate 'work' @('-Identity', 'work')) 0
	Check 'work_history_commits' (Value 'work' 'identity_history_commits') 0
	Check 'work_as_public_exit' (Gate 'work_as_public' @()) 1
	Check 'work_as_public_reported' (Value 'work_as_public' 'identity_selects_public') 'no'
	[IO.File]::WriteAllText($machine, $publicGit, $lf)

	# Fault: a conflict. A peer publishes an edit of a shared file; this home
	# saves a competing edit and syncs.
	$peer = Join-Path $lab 'peer'
	& $git clone -q "$ex/setup.git" $peer
	[IO.File]::AppendAllText((Join-Path $peer 'home\.config\git\ignore'), "peer edit`n")
	& $git -C $peer commit -q -am 'peer edit'
	Check 'peer_push_exit' (Run 'peer_push' $git @('-C', $peer, 'push', '-q', 'origin', 'main')) 0
	[IO.File]::AppendAllText((Live '~/.config/git/ignore'), "local edit`n")
	Run 'conflict_save' $mise @('dot', 'save', (Live '~/.config/git/ignore')) | Out-Null
	Run 'conflict_sync' $mise @('dot', 'sync') | Out-Null
	Check 'conflict_exit' (Gate 'conflict' @()) 1
	Check 'conflict_reported' (Value 'conflict' 'conflicts') 1
	Check 'conflict_test_edit' (Value 'conflict' 'test_edit') 'skipped'
	Check 'final_hash_is_pre_gate' ((Blob $test) -eq $pre) 'True'
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
