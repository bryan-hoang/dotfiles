#!/usr/bin/env pwsh
#
# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles

if (
	(-not [System.Environment]::UserInteractive ) `
		-or ([Environment]::GetCommandLineArgs() | Where-Object{ $_ -like '-NonI*' }) `
		-or ([Console]::IsOutputRedirected) 	# Can't set PredictionSource = "History" if output is redirected.
) {
	exit
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
	$script = Join-Path $HOME '.config' 'powershell' "Initialize-$noun.ps1"
	if (!(Test-Path -Path $script)) {
		continue
	}

	. $script
}

if (Test-CommandExists tabs) {
	tabs 2
}
