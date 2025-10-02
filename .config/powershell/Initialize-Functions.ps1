#!/usr/bin/env pwsh

# Lists the aliases for any cmdlet.
function Get-CmdletAlias ($cmdletname) {
	Get-Alias |
		Where-Object -FilterScript {$_.Definition -like "$cmdletname"} |
		Format-Table -Property Definition, Name -AutoSize
}

# https://www.reddit.com/r/Windows11/comments/pu5aa3/howto_disable_new_context_menu_explorer_command/?utm_source=share&utm_medium=web2x&context=3
function Disable-New-Context-Menu {
	reg add 'HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32' /f /ve
}

# Print the values of all environment variables.
function env {
	Get-ChildItem env:
}

function path {
	$env:Path -split ";"
}

function Set-UserEnvVar($envname, $envvalue) {
	if ([string]::IsNullOrEmpty([Environment]::GetEnvironmentVariable($envname, 'User'))) {
		[Environment]::SetEnvironmentVariable(
			$envname,
			$envvalue,
			'User'
		)
	}

	Set-Item "env:$envname" $envvalue
}

function Add-UserPath($PathToAdd) {
	if (
		([Environment]::GetEnvironmentVariable('Path', 'User') -notlike "*$PathToAdd*") -and (Test-Path -PathType Container "$PathToAdd")
	) {
		[Environment]::SetEnvironmentVariable(
			'Path',
			[Environment]::GetEnvironmentVariable('Path', 'User') + "$PathToAdd;",
			'User'
		)
	}
}

function Test-CommandExists($command) {
	$oldPreference = $ErrorActionPreference
	$ErrorActionPreference = 'stop'
	try
	{
		if (Get-Command $command)
		{
			RETURN $true
		}
	} Catch
	{
		RETURN $false
	} Finally
	{
		$ErrorActionPreference=$oldPreference
	}
}

function Find-WslVhdx {
	param (
		$DistributionName
	)
	(Get-ChildItem -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss | Where-Object { $_.GetValue("DistributionName") -eq $DistributionName }).GetValue("BasePath") + "\ext4.vhdx"
}

if (Test-CommandExists yazi.exe) {
	function y {
		$tmp = (New-TemporaryFile).FullName
		yazi $args --cwd-file="$tmp"
		$cwd = Get-Content -Path $tmp -Encoding UTF8
		if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
			Set-Location -LiteralPath (Resolve-Path -LiteralPath $cwd).Path
		}
		Remove-Item -Path $tmp
	}
}

# FIXME: Can't share home w/ `cmd.exe`.
#
# # https://commandbox.ortusbooks.com/setup/installation
# if (Test-CommandExists box.exe)
# {
# 	function box
# 	{
# 		box.exe -commandbox_home="$(Join-Path $env:XDG_DATA_HOME 'commandbox')" @args
# 	}
# }

if (Test-CommandExists lsd) {
	function ll {
		lsd --long --almost-all --classify --group-directories-first $args
	}
}
