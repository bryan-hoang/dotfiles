# Runs a lab script (default linux-smoke.sh) in a fresh import of the WSL
# fixture checkpoint, then unregisters the run instance. Results land in <IntakeRoot>\lab-results\<run>.
# The fixture disables interop, which also hides it from \\wsl.localhost, so
# files cross the boundary only as tar streams over wsl.exe stdio. cmd.exe
# pipes carry those streams byte-for-byte. The guest receives a copy of
# -Exchange, lab/rewrites, lab/sources, linux-sanitized.sh, and the pinned mise
# (mise-version.txt) in lab-in/bin, which guest scripts put first on PATH. -Bin adds verified
# executables to lab-in/bin.
# PowerShell 7 (pwsh-version.txt) arrives as lab-in/pwsh.tar.gz when its Linux
# media is staged. -TimeoutSeconds bounds the guest script.
param([Parameter(Mandatory)][string]$IntakeRoot, [Parameter(Mandatory)][string]$Exchange, [string]$Script = 'linux-smoke.sh', [string[]]$Bin = @(), [int]$TimeoutSeconds = 600)
$ErrorActionPreference = 'Stop'
$intake = [IO.Path]::GetFullPath($IntakeRoot)
$name = 'mise-lab-run-' + (Get-Date -Format 'yyyyMMddHHmmss')
$runsRoot = Join-Path $intake 'wsl\runs'
$runDir = Join-Path $runsRoot $name
$stage = Join-Path $runsRoot "$name-stage"
$results = Join-Path $intake "lab-results\$name"
$v = (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'mise-version.txt')).Trim()
$mise = Join-Path $intake "linux-media-$v\mise-v$v-linux-x64"
if (-not (Test-Path -LiteralPath $mise)) { throw "pinned mise $v is not staged" }
foreach ($n in 'GITHUB_TOKEN', 'GH_TOKEN', 'GITHUB_API_TOKEN', 'MISE_GITHUB_TOKEN') {
	Remove-Item -LiteralPath "Env:$n" -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path $runDir, $results, (Join-Path $stage 'lab-in\bin') -Force | Out-Null
$inputs = $Script, 'repos.txt', 'prototype', 'rewrites', 'sources', 'linux-sanitized.sh'
Copy-Item -LiteralPath ($inputs | ForEach-Object { Join-Path $PSScriptRoot $_ }) -Destination (Join-Path $stage 'lab-in') -Recurse
Copy-Item -LiteralPath $Exchange -Destination (Join-Path $stage 'lab-in\exchange') -Recurse
Copy-Item -LiteralPath $mise -Destination (Join-Path $stage 'lab-in\bin\mise')
foreach ($b in $Bin) { Copy-Item -LiteralPath $b -Destination (Join-Path $stage 'lab-in\bin') }
$pv = (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'pwsh-version.txt')).Trim()
$pwshTar = Join-Path $intake "linux-media-pwsh-$pv\powershell-$pv-linux-x64.tar.gz"
if (Test-Path -LiteralPath $pwshTar) { Copy-Item -LiteralPath $pwshTar -Destination (Join-Path $stage 'lab-in\pwsh.tar.gz') }
wsl.exe --import $name $runDir (Join-Path $intake 'wsl\fedora44-fixture-ready.tar') | Out-Null
if ($LASTEXITCODE) { throw "import failed: $name" }
try {
	cmd.exe /d /c "tar.exe --no-fflags -cf - -C `"$stage`" lab-in | wsl.exe -d $name --cd ~ --exec tar -xf - -C /home/tester"
	if ($LASTEXITCODE) { throw 'copy-in failed' }
	wsl.exe -d $name --cd ~ --exec timeout $TimeoutSeconds unshare --user --map-current-user --net bash ./lab-in/$Script
	"smoke exit=$LASTEXITCODE run=$name"
	cmd.exe /d /c "wsl.exe -d $name --cd ~ --exec tar -cf - -C /home/tester lab-out | tar.exe -xf - -C `"$results`""
	if ($LASTEXITCODE) { throw 'copy-out failed' }
}
finally {
	wsl.exe --terminate $name | Out-Null
	wsl.exe --unregister $name | Out-Null
	foreach ($p in $runDir, $stage) {
		$full = [IO.Path]::GetFullPath($p)
		if ((Test-Path -LiteralPath $full) -and $full.StartsWith($runsRoot + '\')) {
			Remove-Item -LiteralPath $full -Recurse -Force
		}
	}
}
