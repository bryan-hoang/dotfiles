# Launches a fresh, network-disabled Windows Sandbox that runs a lab script
# (default sandbox-smoke.ps1) at logon, waits for it to shut down, and removes the run
# staging. Results land in <IntakeRoot>\lab-results\<run>\lab-out. The guest
# receives a copy of -Exchange and the pinned mise (mise-version.txt) in
# C:\lab-in\bin.
param([Parameter(Mandatory)][string]$IntakeRoot, [Parameter(Mandatory)][string]$Exchange, [int]$TimeoutMinutes = 20, [string]$Script = 'sandbox-smoke.ps1')
$ErrorActionPreference = 'Stop'
$intake = [IO.Path]::GetFullPath($IntakeRoot)
if (Get-Process -Name 'WindowsSandbox*' -ErrorAction SilentlyContinue) { throw 'A Windows Sandbox is already running.' }
$v = (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'mise-version.txt')).Trim()
$media = Join-Path $intake "windows-media-$v"
if (-not (Test-Path -LiteralPath (Join-Path $media 'mise.exe'))) { throw "pinned mise $v is not staged" }
$name = 'sandbox-run-' + (Get-Date -Format 'yyyyMMddHHmmss')
$runsRoot = Join-Path $intake 'sandbox-runs'
$run = Join-Path $runsRoot $name
$labIn = Join-Path $run 'lab-in'
$labOut = Join-Path $intake "lab-results\$name\lab-out"
New-Item -ItemType Directory -Path (Join-Path $labIn 'bin'), $labOut -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $PSScriptRoot $Script), (Join-Path $PSScriptRoot 'repos.txt'), (Join-Path $PSScriptRoot 'prototype') -Destination $labIn -Recurse
Copy-Item -LiteralPath $Exchange -Destination (Join-Path $labIn 'exchange') -Recurse
Copy-Item -LiteralPath (Join-Path $media 'mise.exe'), (Join-Path $media 'mise-shim.exe') -Destination (Join-Path $labIn 'bin')

function Map([string]$hostPath, [string]$sandboxPath, [string]$readOnly) {
	"    <MappedFolder><HostFolder>$hostPath</HostFolder><SandboxFolder>$sandboxPath</SandboxFolder><ReadOnly>$readOnly</ReadOnly></MappedFolder>"
}
$wsb = Join-Path $run 'run.wsb'
@(
	'<Configuration>'
	'  <Networking>Disable</Networking>'
	'  <vGPU>Disable</vGPU>'
	'  <ClipboardRedirection>Disable</ClipboardRedirection>'
	'  <AudioInput>Disable</AudioInput>'
	'  <VideoInput>Disable</VideoInput>'
	'  <PrinterRedirection>Disable</PrinterRedirection>'
	'  <MappedFolders>'
	(Map (Join-Path $intake 'windows-media') 'C:\fixture-media' 'true')
	(Map $labIn 'C:\lab-in' 'true')
	(Map $labOut 'C:\lab-out' 'false')
	'  </MappedFolders>'
	"  <LogonCommand><Command>powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\lab-in\$Script</Command></LogonCommand>"
	'</Configuration>'
) | Set-Content -LiteralPath $wsb -Encoding utf8
[xml](Get-Content -LiteralPath $wsb -Raw) | Out-Null

try {
	Start-Process -FilePath "$env:WINDIR\System32\WindowsSandbox.exe" -ArgumentList "`"$wsb`""
	$deadline = (Get-Date).AddMinutes($TimeoutMinutes)
	Start-Sleep -Seconds 20
	while ((Get-Process -Name 'WindowsSandbox*' -ErrorAction SilentlyContinue) -and (Get-Date) -lt $deadline) { Start-Sleep -Seconds 10 }
	if (Get-Process -Name 'WindowsSandbox*' -ErrorAction SilentlyContinue) {
		Get-Process -Name 'WindowsSandbox*' | Stop-Process -Force
		"sandbox timed out and was stopped: $name"
	}
	else { "sandbox exited: $name" }
}
finally {
	$full = [IO.Path]::GetFullPath($run)
	if ((Test-Path -LiteralPath $full) -and $full.StartsWith($runsRoot + '\')) { Remove-Item -LiteralPath $full -Recurse -Force }
}
$smoke = Join-Path $labOut ([IO.Path]::ChangeExtension($Script, '.txt'))
if (Test-Path -LiteralPath $smoke) { Get-Content -LiteralPath $smoke } else { 'no results written' }
