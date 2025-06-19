# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles

#region Functions

# Lists the aliases for any cmdlet.
function Get-CmdletAlias ($cmdletname)
{
	Get-Alias |
		Where-Object -FilterScript {$_.Definition -like "$cmdletname"} |
		Format-Table -Property Definition, Name -AutoSize
}

# https://www.reddit.com/r/Windows11/comments/pu5aa3/howto_disable_new_context_menu_explorer_command/?utm_source=share&utm_medium=web2x&context=3
function Disable-New-Context-Menu
{
	reg add 'HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32' /f /ve
}

# Print the values of all environment variables.
function env
{
	Get-ChildItem env:
}

function path
{
	$Env:Path -split ";"
}

function Set-UserEnvVar($envname, $envvalue)
{
	if ([string]::IsNullOrEmpty([Environment]::GetEnvironmentVariable($envname, 'User')))
	{
		[Environment]::SetEnvironmentVariable(
			$envname,
			$envvalue,
			'User'
		)
	}

	Set-Item "env:$envname" $envvalue
}

function Add-UserPath($PathToAdd)
{
	if (
		([Environment]::GetEnvironmentVariable('Path', 'User') -notlike "*$PathToAdd*") -and (Test-Path -PathType Container "$PathToAdd")
	)
	{
		[Environment]::SetEnvironmentVariable(
			'Path',
			[Environment]::GetEnvironmentVariable('Path', 'User') + "$PathToAdd;",
			'User'
		)
	}
}

function Test-CommandExists($command)
{
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
		Write-Host “$command does not exist”
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

#endregion

#region Aliases
#endregion

#region Environment Variables

# Enable symlinking.
Set-UserEnvVar 'MSYS' 'winsymlinks:nativestrict'
Set-UserEnvVar 'XDG_CONFIG_HOME' "$Env:USERPROFILE\.config"
Set-UserEnvVar 'XDG_LOCAL_HOME' "$Env:USERPROFILE\.local"
Set-UserEnvVar 'XDG_BIN_HOME' "$Env:XDG_LOCAL_HOME\bin"
Set-UserEnvVar 'XDG_DATA_HOME' "$Env:XDG_LOCAL_HOME\share"
Set-UserEnvVar 'CARGO_HOME' "$Env:XDG_DATA_HOME\cargo"
Set-UserEnvVar 'RUSTUP_HOME' "$Env:XDG_DATA_HOME\rustup"
Set-UserEnvVar 'KOMOREBI_CONFIG_HOME' "$Env:XDG_CONFIG_HOME\komorebi"
Set-UserEnvVar 'PNPM_HOME' "$Env:XDG_DATA_HOME\pnpm"
Set-UserEnvVar 'GOPATH' "$Env:XDG_DATA_HOME\go"
Set-UserEnvVar 'VSCODE_PORTABLE' "$Env:XDG_DATA_HOME\vscode"
Set-UserEnvVar 'WHKD_CONFIG_HOME' "$Env:XDG_CONFIG_HOME\whkd"
Set-UserEnvVar 'AZURE_CONFIG_DIR' "$Env:XDG_DATA_HOME\azure"
Set-UserEnvVar 'DOCKER_CONFIG' "$Env:XDG_CONFIG_HOME\docker"
Set-UserEnvVar 'STARSHIP_CONFIG' "$Env:XDG_CONFIG_HOME\starship\starship.toml"
Set-UserEnvVar 'GNUPGHOME' "$Env:XDG_DATA_HOME\gnupg"

Add-UserPath "$Env:XDG_BIN_HOME"

#endregion

# Hooking zoxide.
if (Test-CommandExists zoxide)
{
	Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

# Initializing Starship prompt.
Invoke-Expression (&starship init powershell)
Set-UserEnvVar 'STARSHIP_SHELL' 'C:\Program Files\Git\bin\bash.exe --noprofile --norc'
