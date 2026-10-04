# Windows adoption run for Windows Sandbox (Windows PowerShell 5.1, ASCII
# only). Adopts the setup repository from the exchange copy with the pinned
# mise in C:\lab-in\bin, then checks held paths, restored shared files byte
# for byte, repository-only paths, bootstrap repositories, and the E092
# Topgrade status check. Tools are
# skipped: the offline lab cannot install the restored tool list. Nothing is
# published. Writes key=value results and logs to C:\lab-out.
$ErrorActionPreference = 'Stop'
$in = 'C:\lab-in'
$out = 'C:\lab-out'
$lab = 'C:\lab'
$p = Join-Path $in 'prototype'
$results = Join-Path $out 'sandbox-adopt.txt'
function Say([string]$k, [string]$v) { Add-Content -LiteralPath $results -Value "$k=$v" -Encoding ASCII }
function Run([string]$name, [string]$exe, [string[]]$argv) {
	$ErrorActionPreference = 'Continue'
	$o = & $exe @argv 2>&1 | ForEach-Object { "$_" }
	$code = $LASTEXITCODE
	[IO.File]::WriteAllText((Join-Path $out "$name.log"), (($o -join "`n") + "`n"))
	Say "${name}_exit" $code
	$code
}
function Live([string]$tilde) { Join-Path $env:USERPROFILE ($tilde.Substring(2) -replace '/', '\') }
$lf = New-Object Text.UTF8Encoding $false
try {
	Start-Transcript -LiteralPath (Join-Path $out 'transcript.txt') | Out-Null
	New-Item -ItemType Directory -Path (Join-Path $lab 'bin') -Force | Out-Null
	$p1 = Start-Process -FilePath 'C:\fixture-media\vc_redist.x64.exe' -ArgumentList '/install', '/quiet', '/norestart' -Wait -PassThru
	$p2 = Start-Process -FilePath 'C:\fixture-media\Git-2.55.0.3-64-bit.exe' -ArgumentList '/VERYSILENT', '/NORESTART', '/NOCANCEL', '/SP-', '/SUPPRESSMSGBOXES' -Wait -PassThru
	Say 'installs_exit' "$($p1.ExitCode),$($p2.ExitCode)"
	$git = 'C:\Program Files\Git\cmd\git.exe'
	Copy-Item -Path (Join-Path $in 'bin\*') -Destination (Join-Path $lab 'bin')
	Copy-Item -LiteralPath (Join-Path $in 'exchange') -Destination (Join-Path $lab 'exchange') -Recurse
	$mise = Join-Path $lab 'bin\mise.exe'
	# PowerShell 7 from lab-in runs the E178 sanitized check in the status check.
	$env:PATH = "$lab\bin;$in\bin\pwsh;C:\Program Files\Git\cmd;$env:PATH"
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
	Say 'mise' ((([IO.File]::ReadAllText((Join-Path $out 'version.log'))).Trim() -split ' ')[0])
	$seed = (& $git -C "$ex/setup.git" rev-parse main)
	Say 'seed_tip' $seed
	$rows = Get-Content -LiteralPath (Join-Path $p 'files.tsv') | ForEach-Object { $f = $_ -split "`t"; [pscustomobject]@{ Id = $f[0]; Var = $f[1]; Live = $f[2]; Stream = $f[3] } }
	$shared = @{}
	foreach ($r in ($rows | Where-Object { $_.Var -eq 'S' })) { $shared[$r.Live.Substring(2)] = $true }
	# Repository-only tip paths that already exist natively are not adoption output.
	$repoOnly = @(& $git -C "$ex/setup.git" -c core.quotePath=false ls-tree -r --name-only $seed | Where-Object { $_ -notmatch '^(home|config)(@[a-z]+)?/' -and $_ -notlike '.mise-history/*' -and -not $shared.ContainsKey($_) })
	$preexisting = @($repoOnly | Where-Object { Test-Path -LiteralPath (Live "~/$_") })

	Run 'adopt' $mise @('bootstrap', '--adopt', 'https://github.com/bryan-hoang/dotfiles', '--yes', '--skip', 'tools') | Out-Null
	Say 'held_paths' @([IO.File]::ReadAllLines((Join-Path $out 'adopt.log')) | Where-Object { $_ -match 'held:' }).Count

	$ok = 0; $bad = @(); $linuxPresent = 0
	foreach ($r in $rows) {
		$path = Live $r.Live
		if ($r.Var -eq 'L') { if (Test-Path -LiteralPath $path) { $linuxPresent++ }; continue }
		if ($r.Var -eq 'W') { continue }
		$want = (& $git -C "$ex/setup.git" rev-parse "${seed}:$($r.Stream)")
		$got = if (Test-Path -LiteralPath $path -PathType Leaf) { (& $git hash-object --no-filters -- $path) } else { '' }
		if ($got -and $got -eq $want) { $ok++ } else { $bad += $r.Id }
	}
	Say 'shared_files_restored_exact' $ok
	Say 'shared_files_wrong_or_missing' $(if ($bad.Count) { ($bad | Select-Object -Unique) -join ',' } else { 'none' })
	Say 'linux_files_present' $linuxPresent
	Say 'stylua_present' (Test-Path -LiteralPath (Live '~/.config/nvim/stylua.toml'))

	$restored = @($repoOnly | Where-Object { $preexisting -notcontains $_ -and (Test-Path -LiteralPath (Live "~/$_")) })
	[IO.File]::WriteAllText((Join-Path $out 'repository_only_restored.txt'), (($restored -join "`n") + "`n"))
	Say 'repository_only_checked' $repoOnly.Count
	Say 'repository_only_preexisting' $preexisting.Count
	Say 'repository_only_restored' $restored.Count

	$cloned = 0; $wrong = @()
	foreach ($repo in $repos) {
		$d = Live "~/src/github.com/$repo"
		$h = if (Test-Path -LiteralPath (Join-Path $d '.git')) { (& $git -C $d rev-parse HEAD) } else { '' }
		if ($h -and $h -eq (& $git -C "$ex/mirrors/$repo.git" rev-parse HEAD)) { $cloned++ } else { $wrong += $repo }
	}
	Say 'repos_cloned_at_mirror_head' $cloned
	Say 'repos_wrong_or_missing' $(if ($wrong.Count) { $wrong -join ',' } else { 'none' })
	$contrib = Live '~/src/github.com/akinomyoga/ble.sh/contrib'
	Say 'blesh_contrib_entries' $(if (Test-Path -LiteralPath $contrib) { @(Get-ChildItem -LiteralPath $contrib -Force).Count } else { 'absent' })

	$hist = Get-ChildItem -LiteralPath $env:USERPROFILE -Recurse -Directory -Filter 'repo.git' -Force -ErrorAction SilentlyContinue | Where-Object { $_.Parent.Name -eq 'history' } | Select-Object -First 1
	Say 'history_repo' $(if ($hist) { $hist.FullName.Substring($env:USERPROFILE.Length) } else { 'missing' })
	if ($hist) {
		Say 'adopted_head' (& $git -C $hist.FullName rev-parse main)
		Say 'adopted_head_contains_seed' $(if ((Run 'ancestry_seed' $git @('-C', $hist.FullName, 'merge-base', '--is-ancestor', $seed, 'main')) -eq 0) { 'yes' } else { 'no' })
	}
	Run 'status' $mise @('dot', 'status', '--json') | Out-Null

	# Topgrade status check from the restored E092, run the way Topgrade runs a
	# custom command on Windows without pwsh (powershell -Command), whose pipes
	# add a byte order mark. It must pass here, fail with a declared but stopped
	# watcher or an unknown field in a sanitized source (the E178 check), and
	# print only true or false. Needs jaq.exe and PowerShell 7 in C:\lab-in\bin.
	$line = @([IO.File]::ReadAllLines((Live '~/.config/topgrade/topgrade.toml')) | Where-Object { $_ -like '"mise dot status" = "*' })[0]
	Say 'check_command_found' $(if ($line) { 'yes' } else { 'no' })
	$cmd = $line.Substring($line.IndexOf('= "') + 3).TrimEnd('"').Replace('\"', '"')
	function StatusCheck([string]$name) {
		Run "${name}_status" $mise @('dot', 'status', '--json') | Out-Null
		$ErrorActionPreference = 'Continue'
		Say "${name}_watcher" (& (Join-Path $lab 'bin\jaq.exe') -r '.history.watcher' (Join-Path $out "${name}_status.log"))
		Run $name 'powershell.exe' @('-NoProfile', '-Command', $cmd) | Out-Null
		Say "${name}_output" ((([IO.File]::ReadAllText((Join-Path $out "$name.log"))).Trim() -split "`n") -join ',')
	}
	StatusCheck 'check_healthy'
	$watcher = Live '~/.config/mise/config.local.toml'
	[IO.File]::WriteAllText($watcher, "[bootstrap.services.mise-history]`nbuiltin = `"history-watch`"`n", $lf)
	StatusCheck 'check_watcher_stopped'
	Remove-Item -LiteralPath $watcher
	StatusCheck 'check_watcher_removed'
	$pip = Live '~/.config/mise/dotfiles/.config/pip/pip.conf'
	$reviewed = [IO.File]::ReadAllBytes($pip)
	[IO.File]::AppendAllText($pip, "proxy = http://lab.invalid:3128`n")
	StatusCheck 'check_sanitized_unknown'
	[IO.File]::WriteAllBytes($pip, $reviewed)
	StatusCheck 'check_sanitized_restored'
	Say 'done' 'yes'
}
catch {
	Say 'error' $_.Exception.Message
}
finally {
	try { Stop-Transcript | Out-Null } catch { }
	shutdown.exe /s /t 5
}
