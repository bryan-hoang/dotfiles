#!/usr/bin/env pwsh

if (-not (Get-Module -ListAvailable -Name PSCompletions)) {
	Install-Module PSCompletions -Scope CurrentUser -Force
}
# Import-Module PSCompletions

If (-not (Get-Module -ListAvailable -Name posh-git)) {
	Install-Module posh-git -Scope CurrentUser -Force
}
Import-Module posh-git

$PwshCompletionDir = $(Join-Path $env:XDG_DATA_HOME 'powershell' 'completions')
if (-not (Test-Path $PwshCompletionDir)) {
	New-Item -ItemType Directory -Force -Path $PwshCompletionDir > $null
}

function Add-Completion {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[string]$CommandToComplete,
		[Parameter(Mandatory)]
		[string]$CompletionCommand
	)
	$completionFile = $(Join-Path $PwshCompletionDir "${CommandToComplete}.ps1")
	if (-not (Test-CommandExists $CommandToComplete)) {
		return
	}
	if (-not (Test-Path $completionFile)) {
		Invoke-Expression $CompletionCommand > $completionFile
	}
}

Add-Completion 'kubectl' 'kubectl completion powershell'
Add-Completion 'op' 'op completion powershell'
# Add-Completion 'sqlcmd' 'sqlcmd completion powershell'
Add-Completion 'minikube' 'minikube completion powershell'

$completionFiles = Get-ChildItem $PwshCompletionDir -Filter *.ps1
foreach ($file in $completionFiles) {
	. $file.FullName
}

# if (Test-CommandExists dotnet) {
# 	# https://learn.microsoft.com/en-us/dotnet/core/tools/enable-tab-autocomplete#powershell
# 	# PowerShell parameter completion shim for the dotnet CLI
# 	Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
# 		param($wordToComplete, $commandAst, $cursorPosition)
# 		dotnet complete --position $cursorPosition "$commandAst" | ForEach-Object {
# 			[System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
# 		}
# 	}
# }
