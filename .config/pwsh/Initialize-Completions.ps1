#!/usr/bin/env pwsh

if (-not (Get-Module -ListAvailable git-completion)) {
	Install-Module git-completion
}
Import-Module git-completion
Register-ArgumentCompleter -CommandName git -Native -ScriptBlock {
	param($wordToComplete, $CommandAst, $CursorPosition)
	return (Complete-Git -CommandAst $CommandAst -CursorPosition $CursorPosition)
}

$PwshCompletionDir = $(Join-Path $env:XDG_DATA_HOME 'pwsh' 'completions')
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

Add-Completion 'atuin' 'atuin gen-completions --shell powershell'
Add-Completion 'aube' 'aube completion powershell'
Add-Completion 'dotnet' 'dotnet completions script pwsh'
Add-Completion 'kubectl' 'kubectl completion powershell'
Add-Completion 'minikube' 'minikube completion powershell'
Add-Completion 'mise' 'mise completion powershell'
Add-Completion 'op' 'op completion powershell'
Add-Completion 'tv' 'tv completions power-shell'
Add-Completion 'typst' 'typst completions powershell'
Add-Completion 'uv' 'uv generate-shell-completion powershell'

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
