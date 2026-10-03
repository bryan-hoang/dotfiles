# Removes every lab run artifact while keeping the fixtures and the canonical
# exchange: stops Windows Sandbox, unregisters mise-lab-* WSL instances, and
# deletes run staging and results under <IntakeRoot>. Prints what remains.
param([Parameter(Mandatory)][string]$IntakeRoot)
$ErrorActionPreference = 'Stop'
$intake = [IO.Path]::GetFullPath($IntakeRoot)
Get-Process -Name 'WindowsSandbox*' -ErrorAction SilentlyContinue | Stop-Process -Force
$instances = (wsl.exe --list --quiet) | ForEach-Object { ($_ -replace "`0", '').Trim() } | Where-Object { $_ -like 'mise-lab-*' }
foreach ($i in $instances) {
	wsl.exe --terminate $i | Out-Null
	wsl.exe --unregister $i | Out-Null
}
foreach ($rel in 'wsl\runs', 'sandbox-runs', 'lab-results') {
	$full = [IO.Path]::GetFullPath((Join-Path $intake $rel))
	if (-not $full.StartsWith($intake + '\')) { throw "refusing to delete outside the intake root: $full" }
	if (Test-Path -LiteralPath $full) {
		if ((Get-Item -LiteralPath $full -Force).LinkType) { throw "refusing to delete a link: $full" }
		Remove-Item -LiteralPath $full -Recurse -Force
	}
}
"sandbox processes: " + @(Get-Process -Name 'WindowsSandbox*' -ErrorAction SilentlyContinue).Count
"lab instances: " + @((wsl.exe --list --quiet) | ForEach-Object { ($_ -replace "`0", '').Trim() } | Where-Object { $_ -like 'mise-lab-*' }).Count
"run artifacts left: " + @('wsl\runs', 'sandbox-runs', 'lab-results' | Where-Object { Test-Path -LiteralPath (Join-Path $intake $_) }).Count
