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
Add-Completion 'atuin' 'atuin gen-completions --shell powershell'
Add-Completion 'mise' 'mise completion powershell'

$completionFiles = Get-ChildItem $PwshCompletionDir -Filter *.ps1
foreach ($file in $completionFiles) {
	. $file.FullName
}

if (Test-CommandExists az) {
	Register-ArgumentCompleter -Native -CommandName az -ScriptBlock {
		param($commandName, $wordToComplete, $cursorPosition)
			$completion_file = New-TemporaryFile
			$env:ARGCOMPLETE_USE_TEMPFILES = 1
			$env:_ARGCOMPLETE_STDOUT_FILENAME = $completion_file
			$env:COMP_LINE = $wordToComplete
			$env:COMP_POINT = $cursorPosition
			$env:_ARGCOMPLETE = 1
			$env:_ARGCOMPLETE_SUPPRESS_SPACE = 0
			$env:_ARGCOMPLETE_IFS = "`n"
			$env:_ARGCOMPLETE_SHELL = 'powershell'
			az 2>&1 | Out-Null
			Get-Content $completion_file | Sort-Object | ForEach-Object {
				[System.Management.Automation.CompletionResult]::new($_, $_, "ParameterValue", $_)
			}
		Remove-Item $completion_file, Env:\_ARGCOMPLETE_STDOUT_FILENAME, Env:\ARGCOMPLETE_USE_TEMPFILES, Env:\COMP_LINE, Env:\COMP_POINT, Env:\_ARGCOMPLETE, Env:\_ARGCOMPLETE_SUPPRESS_SPACE, Env:\_ARGCOMPLETE_IFS, Env:\_ARGCOMPLETE_SHELL
	}
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
