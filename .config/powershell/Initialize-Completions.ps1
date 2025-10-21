#!/usr/bin/env pwsh

if (!(Get-Module -ListAvailable -Name PSCompletions )) {
	Install-Module PSCompletions -Scope CurrentUser -Force
}
Import-Module PSCompletions

if (Test-CommandExists kubectl) {
	kubectl completion powershell | Out-String | Invoke-Expression
}

if (Test-CommandExists sqlcmd.exe) {
	(& sqlcmd completion powershell) | Out-String | Invoke-Expression
}

if (Test-CommandExists dotnet) {
	# https://learn.microsoft.com/en-us/dotnet/core/tools/enable-tab-autocomplete#powershell
	# PowerShell parameter completion shim for the dotnet CLI
	Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
		param($wordToComplete, $commandAst, $cursorPosition)
		dotnet complete --position $cursorPosition "$commandAst" | ForEach-Object {
			[System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
		}
	}
}

# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
if (($IsWindows) -and ($env:ChocolateyInstall) -and (Test-Path(Join-Path $env:ChocolateyInstall "helpers" "chocolateyProfile.psm1"))) {
	Import-Module "$ChocolateyProfile"
}
