# Lab smoke test for the Windows Sandbox fixture (Windows PowerShell 5.1).
# The run .wsb maps C:\fixture-media and C:\lab-in read-only and C:\lab-out
# writable, and starts this script at logon. It writes key=value results to
# C:\lab-out\sandbox-smoke.txt, creates no setup history, and shuts down.
$ErrorActionPreference = 'Stop'
$in = 'C:\lab-in'
$out = 'C:\lab-out'
$lab = 'C:\lab'
$results = Join-Path $out 'sandbox-smoke.txt'
function Say([string]$k, [string]$v) { Add-Content -LiteralPath $results -Value "$k=$v" -Encoding ASCII }
function Run([string]$exe, [string[]]$argv) {
	# Windows PowerShell 5.1 turns redirected native stderr into terminating
	# errors under Stop; expected refusals must be data, not exceptions.
	$ErrorActionPreference = 'Continue'
	$o = & $exe @argv 2>&1 | ForEach-Object { "$_" }
	[pscustomobject]@{ Code = $LASTEXITCODE; Text = ($o -join "`n") }
}
try {
	Start-Transcript -LiteralPath (Join-Path $out 'transcript.txt') | Out-Null
	foreach ($d in 'bin', 'config', 'data', 'state', 'cache', 'tmp') { New-Item -ItemType Directory -Path (Join-Path $lab $d) -Force | Out-Null }
	$start = Get-Date

	# Stock mise for Windows imports VCRUNTIME140.dll, which a clean Sandbox lacks.
	$p = Start-Process -FilePath 'C:\fixture-media\vc_redist.x64.exe' -ArgumentList '/install', '/quiet', '/norestart' -Wait -PassThru
	Say 'vcredist_install_exit' $p.ExitCode
	$p = Start-Process -FilePath 'C:\fixture-media\Git-2.55.0.3-64-bit.exe' -ArgumentList '/VERYSILENT', '/NORESTART', '/NOCANCEL', '/SP-', '/SUPPRESSMSGBOXES' -Wait -PassThru
	Say 'git_install_exit' $p.ExitCode
	$git = 'C:\Program Files\Git\cmd\git.exe'
	Copy-Item -LiteralPath 'C:\fixture-media\mise.exe' -Destination (Join-Path $lab 'bin\mise.exe')
	Copy-Item -LiteralPath (Join-Path $in 'exchange') -Destination (Join-Path $lab 'exchange') -Recurse
	$mise = Join-Path $lab 'bin\mise.exe'

	$env:MISE_CONFIG_DIR = Join-Path $lab 'config'
	$env:MISE_GLOBAL_CONFIG_FILE = Join-Path $lab 'config\config.toml'
	$env:MISE_DATA_DIR = Join-Path $lab 'data'
	$env:MISE_STATE_DIR = Join-Path $lab 'state'
	$env:MISE_CACHE_DIR = Join-Path $lab 'cache'
	$env:MISE_TMP_DIR = Join-Path $lab 'tmp'
	$env:TEMP = Join-Path $lab 'tmp'
	$env:TMP = Join-Path $lab 'tmp'
	$env:MISE_HISTORY_SYNC = 'manual'
	$env:MISE_AUTO_INSTALL = '0'
	$env:GIT_CONFIG_NOSYSTEM = '1'
	$env:GIT_CONFIG_GLOBAL = Join-Path $lab 'gitconfig'
	$env:GIT_TERMINAL_PROMPT = '0'
	Set-Location -LiteralPath $lab

	$ex = 'C:/lab/exchange'
	$gh = 'https://github.com'
	$cfg = @('[protocol]', "`tallow = never", '[protocol "file"]', "`tallow = always", '[user]', "`tname = Lab", "`temail = lab@localhost")
	foreach ($repo in (Get-Content -LiteralPath (Join-Path $in 'repos.txt') | Where-Object { $_.Trim() })) {
		$cfg += "[url `"$ex/mirrors/$repo.git`"]", "`tinsteadOf = $gh/$repo"
		$cfg += "[url `"$ex/mirrors/$repo.git`"]", "`tinsteadOf = $gh/$repo.git"
	}
	foreach ($origin in 'https://github.com/bryan-hoang/dotfiles', 'ssh://git@github.com/bryan-hoang/dotfiles') {
		$cfg += "[url `"$ex/setup.git`"]", "`tinsteadOf = $origin"
	}
	[IO.File]::WriteAllText($env:GIT_CONFIG_GLOBAL, (($cfg -join "`n") + "`n"), (New-Object Text.UTF8Encoding $false))

	Say 'user' $env:USERNAME
	Say 'up_adapters' (@(Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object Status -eq 'Up').Count)
	$tcp = New-Object Net.Sockets.TcpClient
	$reach = $false
	try { $reach = $tcp.ConnectAsync('1.1.1.1', 443).Wait(5000) } catch { $reach = $false } finally { $tcp.Dispose() }
	Say 'outbound' $(if ($reach) { 'reachable' } else { 'blocked' })
	Say 'git' ((Run $git @('--version')).Text -replace '^git version ', '')
	$v = Run $mise @('--version')
	Say 'mise_exit' $v.Code
	Say 'mise' (($v.Text -split "`n" | Select-Object -Last 1) -split ' ')[0]
	Say 'history_sync' (((Run $mise @('settings', 'get', 'history.sync')).Text -split "`n") | Select-Object -Last 1)

	$want = (Run $git @('-C', "$ex/mirrors/dracula/git.git", 'rev-parse', 'HEAD')).Text
	$got = (((Run $git @('ls-remote', 'https://github.com/dracula/git', 'HEAD')).Text -split "`t")[0])
	Say 'approved_url_resolves_to_mirror' $(if ($got -eq $want) { 'yes' } else { 'no' })
	$main = (Run $git @('-C', "$ex/setup.git", 'rev-parse', 'main')).Text
	$got = (((Run $git @('ls-remote', 'ssh://git@github.com/bryan-hoang/dotfiles', 'refs/heads/main')).Text -split "`t")[0])
	Say 'origin_resolves_to_setup_remote' $(if ($got -eq $main) { 'yes' } else { 'no' })
	$r = Run $git @('ls-remote', "$gh/example/not-approved")
	Say 'unapproved_url' $(if ($r.Text -match "transport 'https' not allowed") { 'refused' } else { 'unexpected: ' + $r.Text.Substring(0, [Math]::Min(120, $r.Text.Length)) })

	$profileRoots = @('.config\mise', '.local\share\mise', '.local\state\mise', '.cache\mise', 'AppData\Local\mise') | ForEach-Object { Join-Path $env:USERPROFILE $_ }
	$stray = @($profileRoots | Where-Object { (Test-Path -LiteralPath $_) -and (Get-Item -LiteralPath $_ -Force).CreationTime -ge $start })
	Say 'mise_writes_outside_lab_roots' $(if ($stray.Count) { $stray -join ',' } else { 'none' })
	Say 'history_repo_present' $(if (Test-Path -LiteralPath (Join-Path $lab 'state\history')) { 'yes' } else { 'no' })
	Say 'done' 'yes'
}
catch {
	Say 'error' $_.Exception.Message
}
finally {
	try { Stop-Transcript | Out-Null } catch { }
	shutdown.exe /s /t 5
}
