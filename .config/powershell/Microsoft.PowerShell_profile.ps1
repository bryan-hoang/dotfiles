#!/usr/bin/env pwsh

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles

foreach ($noun in 'Functions','Environment','Completions','Machine')
{
	$script = Join-Path $HOME '.config' 'powershell' "Initialize-$noun.ps1"
	if (!(Test-Path -Path $script))
	{
		continue
	}

	. $script
}

$PSReadLineOptions = @{
	EditMode = "Emacs"
	# https://learn.microsoft.com/en-us/powershell/module/psreadline/about/about_psreadline?view=powershell-7.5#enable-predictive-intellisense
	PredictionSource = "HistoryAndPlugin"
	HistorySearchCursorMovesToEnd = $true
}
Set-PSReadLineOption @PSReadLineOptions

# I hecking love having a consistent editing mode.
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

if (Test-CommandExists zoxide)
{
	Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

if (Test-CommandExists starship)
{
	# Initializing Starship prompt.
	Invoke-Expression (&starship init powershell)
}
else
{
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
