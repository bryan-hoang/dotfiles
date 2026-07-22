#!/usr/bin/env pwsh

$PSReadLineOptions = @{
	EditMode = "Emacs"
	HistorySearchCursorMovesToEnd = $true
	MaximumHistoryCount = [Math]::Pow(2, 14)
	# https://learn.microsoft.com/en-us/powershell/module/psreadline/about/about_psreadline?view=powershell-7.5#enable-predictive-intellisense
	PredictionSource = "History"
	# Adding `_` as a delimiter.
	# https://learn.microsoft.com/en-us/powershell/module/psreadline/set-psreadlineoption?view=powershell-7.5#-worddelimiters
	WordDelimiters = ';:,.[]{}()/\|^&*-=+''"---_@'
}
Set-PSReadLineOption @PSReadLineOptions

# I hecking love having a consistent editing mode.
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadlineKeyHandler -Key Ctrl+w -Function BackwardKillWord

$globalPssaSettings = Join-Path -Resolve $env:XDG_CONFIG_HOME 'powershell' 'PSScriptAnalyzerSettings.psd1'

if (Test-Path -LiteralPath $globalPssaSettings) {
	$PSDefaultParameterValues['Invoke-ScriptAnalyzer:Settings'] = $globalPssaSettings
	$PSDefaultParameterValues['Invoke-Formatter:Settings'] = $globalPssaSettings
}
