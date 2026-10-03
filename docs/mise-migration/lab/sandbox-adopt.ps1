# Prototype Windows adoption run for Windows Sandbox (Windows PowerShell 5.1).
# Adopts the seeded setup repository from the exchange copy with stock mise,
# checks restored files and bootstrap repositories, adds the synthetic Windows
# stream, and publishes it. Writes key=value results and logs to C:\lab-out,
# including the advanced setup.git for the host to fast-forward fetch.
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
	Copy-Item -LiteralPath 'C:\fixture-media\mise.exe' -Destination (Join-Path $lab 'bin\mise.exe')
	Copy-Item -LiteralPath (Join-Path $in 'exchange') -Destination (Join-Path $lab 'exchange') -Recurse
	$mise = Join-Path $lab 'bin\mise.exe'
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
	$seed = (& $git -C "$ex/setup.git" rev-parse main)
	Say 'seed_tip' $seed

	Run 'adopt' $mise @('bootstrap', '--adopt', 'https://github.com/bryan-hoang/dotfiles', '--yes') | Out-Null

	$rows = Get-Content -LiteralPath (Join-Path $p 'files.tsv') | ForEach-Object { $f = $_ -split "`t"; [pscustomobject]@{ Id = $f[0]; Var = $f[1]; Live = $f[2]; Stream = $f[3] } }
	$ok = 0; $bad = @(); $linuxPresent = 0
	foreach ($r in $rows) {
		$path = Live $r.Live
		if ($r.Var -eq 'L') { if (Test-Path -LiteralPath $path) { $linuxPresent++ }; continue }
		if ($r.Var -eq 'W') { continue }
		$want = if ($r.Id -eq 'E011') { [IO.File]::ReadAllText((Join-Path $p 'dotfiles.toml')) } else { "# synthetic $($r.Id) $($r.Stream)`n" }
		if ((Test-Path -LiteralPath $path) -and [IO.File]::ReadAllText($path) -eq $want) { $ok++ } else { $bad += $r.Id }
	}
	Say 'shared_files_restored_exact' $ok
	Say 'shared_files_wrong_or_missing' $(if ($bad.Count) { ($bad | Select-Object -Unique) -join ',' } else { 'none' })
	Say 'linux_files_present' $linuxPresent
	Say 'stylua_present' (Test-Path -LiteralPath (Live '~/.config/nvim/stylua.toml'))

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

	$n = 0
	foreach ($r in ($rows | Where-Object Var -eq 'W')) {
		$path = Live $r.Live
		New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force | Out-Null
		[IO.File]::WriteAllText($path, "# synthetic $($r.Id) $($r.Stream)`n", $lf)
		$n++
	}
	Say 'windows_files_written' $n
	$saves = @(Get-Content -LiteralPath (Join-Path $p 'roots.tsv') | ForEach-Object { $f = $_ -split "`t"; if ($f[1] -eq 'W') { Live $f[2] } })
	Say 'windows_save_roots' $saves.Count
	Run 'save' $mise (@('dot', 'save', '--description', 'Prototype Windows stream') + $saves) | Out-Null
	Run 'sync' $mise @('dot', 'sync') | Out-Null
	Run 'status' $mise @('dot', 'status', '--json') | Out-Null
	if ($hist) {
		Say 'local_head' (& $git -C $hist.FullName rev-parse main)
		Say 'local_head_contains_seed' $(if ((Run 'ancestry_local' $git @('-C', $hist.FullName, 'merge-base', '--is-ancestor', $seed, 'main')) -eq 0) { 'yes' } else { 'no' })
	}
	$tip = (& $git -C "$ex/setup.git" rev-parse main)
	Say 'exchange_tip' $tip
	Say 'exchange_advanced' $(if ($tip -ne $seed) { 'yes' } else { 'no' })
	Say 'exchange_windows_files' @(& $git -C "$ex/setup.git" ls-tree -r --name-only main -- 'home@windows' 'config@windows').Count
	Copy-Item -LiteralPath "$lab\exchange\setup.git" -Destination (Join-Path $out 'setup.git') -Recurse
	Say 'done' 'yes'
}
catch {
	Say 'error' $_.Exception.Message
}
finally {
	try { Stop-Transcript | Out-Null } catch { }
	shutdown.exe /s /t 5
}
