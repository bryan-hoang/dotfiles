#!/usr/bin/env pwsh
#
# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles

# Keep analyzer defaults available to redirected formatter and linter processes.
$globalPSSAsettings = Join-Path $env:XDG_CONFIG_HOME 'pwsh' 'PSScriptAnalyzerSettings.psd1'

if (Test-Path -LiteralPath $globalPSSAsettings) {
	$PSDefaultParameterValues['Invoke-Formatter:Settings'] = $globalPSSAsettings
	$PSDefaultParameterValues['Invoke-ScriptAnalyzer:Settings'] = $globalPSSAsettings
}

if (
	(-not [System.Environment]::UserInteractive ) `
		-or ([Environment]::GetCommandLineArgs() | Where-Object{ $_ -like '-NonI*' }) `
		-or ([Console]::IsOutputRedirected) 	# Can't set PredictionSource = "History" if output is redirected.
) {
	return
}

foreach (
	$noun in
	'Functions',
	'Environment',
	'Preferences',
	'Completions',
	'Aliases',
	'Machine',
	'Integrations'
) {
	$script = Join-Path $HOME '.config' 'pwsh' "Initialize-$noun.ps1"
	if (!(Test-Path -Path $script)) {
		continue
	}

	. $script
}

if (Test-CommandExists tabs) {
	tabs 2
}
