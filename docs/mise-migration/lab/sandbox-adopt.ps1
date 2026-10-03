# Windows adoption run for Windows Sandbox (Windows PowerShell 5.1, ASCII
# only). Adopts the setup repository from the exchange copy with the pinned
# mise in C:\lab-in\bin, then checks held paths, restored shared files byte
# for byte, repository-only paths, and bootstrap repositories. Tools are
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
	Copy-Item -LiteralPath (Join-Path $in 'bin\mise.exe'), (Join-Path $in 'bin\mise-shim.exe') -Destination (Join-Path $lab 'bin')
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
	Say 'done' 'yes'
}
catch {
	Say 'error' $_.Exception.Message
}
finally {
	try { Stop-Transcript | Out-Null } catch { }
	shutdown.exe /s /t 5
}
