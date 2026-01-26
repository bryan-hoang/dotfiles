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

foreach ($noun in 'Functions', 'Environment', 'Completions', 'Aliases', 'Machine') {
	$script = Join-Path $HOME '.config' 'powershell' "Initialize-$noun.ps1"
	if (!(Test-Path -Path $script)) {
		continue
	}

	. $script
}

$PSReadLineOptions = @{
	EditMode = "Emacs"
	# https://learn.microsoft.com/en-us/powershell/module/psreadline/about/about_psreadline?view=powershell-7.5#enable-predictive-intellisense
	PredictionSource = "History"
	HistorySearchCursorMovesToEnd = $true
	# Adding `_` as a delimiter.
	# https://learn.microsoft.com/en-us/powershell/module/psreadline/set-psreadlineoption?view=powershell-7.5#-worddelimiters
	WordDelimiters = ';:,.[]{}()/\|^&*-=+''"---_@'
}
Set-PSReadLineOption @PSReadLineOptions

# I hecking love having a consistent editing mode.
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadlineKeyHandler -Key Ctrl+w -Function BackwardKillWord

if (Test-CommandExists atuin) {
	atuin init powershell | Out-String | Invoke-Expression
}

if (Test-CommandExists starship) {
	# Initializing Starship prompt.
	Invoke-Expression (&starship init powershell)
} else {
	# Customize the prompt
	function prompt {
		$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
		$principal = [Security.Principal.WindowsPrincipal] $identity
		$adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator

		$prefix = if (Test-Path Variable:/PSDebugContext) { '[DBG]: ' } else { '' }
		if ($principal.IsInRole($adminRole)) {
				$prefix = "[ADMIN]:$prefix"
		}
		$body = 'PS ' + $PWD.path
		$suffix = $(if ($NestedPromptLevel -ge 1) { '>>' }) + '> '
		"${prefix}${body}${suffix}"
	}
}

if (Test-CommandExists mise) {
	mise activate pwsh | Out-String | Invoke-Expression
}

# NOTE: `zoxide` should be initialized after `starship`.
# https://github.com/ajeetdsouza/zoxide/issues/1021#issuecomment-2810261891
if (Test-CommandExists zoxide) {
	Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

if (Test-CommandExists tabs) {
  tabs 2
}
