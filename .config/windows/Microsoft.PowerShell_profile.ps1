# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_update_notifications?view=powershell-7.5
[Environment]::SetEnvironmentVariable('POWERSHELL_UPDATECHECK','LTS','User')

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
	$env:Path -split ";"
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
		RETURN $false
	} Finally
	{
		$ErrorActionPreference=$oldPreference
	}
}

function Find-WslVhdx
{
	param (
		$DistributionName
	)
	(Get-ChildItem -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss | Where-Object { $_.GetValue("DistributionName") -eq $DistributionName }).GetValue("BasePath") + "\ext4.vhdx"
}

#endregion

#region Environment Variables

# Enable symlinking.
Set-UserEnvVar 'MSYS' 'winsymlinks:nativestrict'
Set-UserEnvVar 'USERPROFILE' "$HOME"
Set-UserEnvVar 'APPDATA' (Join-Path $env:USERPROFILE 'AppData' 'Roaming')
Set-UserEnvVar 'XDG_CONFIG_HOME' (Join-Path $env:USERPROFILE '.config')
Set-UserEnvVar 'XDG_CONFIG_HOME' (Join-Path $env:USERPROFILE '.config')
Set-UserEnvVar 'XDG_CACHE_HOME' (Join-Path $env:USERPROFILE '.cache')
Set-UserEnvVar 'XDG_LOCAL_HOME' (Join-Path $env:USERPROFILE '.local')
Set-UserEnvVar 'XDG_BIN_HOME' (Join-Path $env:XDG_LOCAL_HOME 'bin')
Set-UserEnvVar 'XDG_DATA_HOME' (Join-Path $env:XDG_LOCAL_HOME 'share')
Set-UserEnvVar 'XDG_STATE_HOME' (Join-Path $env:XDG_LOCAL_HOME 'state')
Set-UserEnvVar 'CARGO_HOME' (Join-Path $env:XDG_DATA_HOME 'cargo')
Set-UserEnvVar 'RUSTUP_HOME' (Join-Path $env:XDG_DATA_HOME 'rustup')
Set-UserEnvVar 'KOMOREBI_CONFIG_HOME' (Join-Path $env:XDG_CONFIG_HOME 'komorebi')
Set-UserEnvVar 'GOPATH' (Join-Path $env:XDG_DATA_HOME 'go')
Set-UserEnvVar 'VSCODE_PORTABLE' (Join-Path $env:XDG_DATA_HOME 'vscode')
Set-UserEnvVar 'WHKD_CONFIG_HOME' (Join-Path $env:XDG_CONFIG_HOME 'whkd')
Set-UserEnvVar 'AZURE_CONFIG_DIR' (Join-Path $env:XDG_DATA_HOME 'azure')
Set-UserEnvVar 'DOCKER_CONFIG' (Join-Path $env:XDG_CONFIG_HOME 'docker')
Set-UserEnvVar 'STARSHIP_CONFIG' (Join-Path $env:XDG_CONFIG_HOME 'starship' 'starship.toml')
Set-UserEnvVar 'GNUPGHOME' (Join-Path $env:XDG_DATA_HOME 'gnupg')
Set-UserEnvVar 'GLAZEWM_CONFIG_PATH' (Join-Path $env:XDG_CONFIG_HOME 'glazewm' 'config.yaml')
Set-UserEnvVar 'ZEBAR_CONFIG_DIR' (Join-Path $env:XDG_CONFIG_HOME 'zebar')
Set-UserEnvVar 'DOTNET_CLI_HOME' (Join-Path $env:XDG_DATA_HOME 'dotnet')
Set-UserEnvVar 'NUGET_PACKAGES' (Join-Path $env:XDG_CACHE_HOME 'nuget-packages')
Set-UserEnvVar 'OMNISHARPHOME' (Join-Path $env:XDG_CONFIG_HOME 'omnisharp')
Set-UserEnvVar 'NODE_REPL_HISTORY' (Join-Path $env:XDG_STATE_HOME 'node' 'history')
Set-UserEnvVar 'PYTHON_HISTORY' (Join-Path $env:XDG_STATE_HOME 'python' 'history')
Set-UserEnvVar 'MINIKUBE_HOME' (Join-Path $env:XDG_DATA_HOME 'minikube')
Set-UserEnvVar 'KUBECONFIG' (Join-Path $env:XDG_CONFIG_HOME 'kube')
Set-UserEnvVar 'KUBECACHEDIR' (Join-Path $env:XDG_CACHE_HOME 'kube')

Add-UserPath "$env:XDG_BIN_HOME"
Add-UserPath (Join-Path $env:APPDATA 'npm')
Set-UserEnvVar 'PNPM_HOME' (Join-Path $env:XDG_DATA_HOME 'pnpm')
Add-UserPath "$env:PNPM_HOME"

if (Test-Path -Path (Join-Path $env:XDG_CONFIG_HOME 'windows' 'pwsh-machine-profile.ps1'))
{
	Invoke-Expression (Get-Content -Path (Join-Path $env:XDG_CONFIG_HOME 'windows' 'pwsh-machine-profile.ps1') -Raw)
}

#endregion

#region Aliases

# https://commandbox.ortusbooks.com/setup/installation
if (Test-CommandExists box.exe)
{
	function box
	{
		box.exe -commandbox_home="$env:XDG_DATA_HOME/commandbox" @args
	}
}

#endregion

# I hecking love having a consistent editing mode.
Set-PSReadLineOption -EditMode Emacs

# Completions
if (Test-CommandExists uv)
{
  (& uv generate-shell-completion powershell) | Out-String | Invoke-Expression
  (& uvx --generate-shell-completion powershell) | Out-String | Invoke-Expression
}

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
