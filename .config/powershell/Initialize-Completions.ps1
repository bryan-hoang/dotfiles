#!/usr/bin/env pwsh

# https://github.com/dahlbyk/posh-git#installing-posh-git-via-powershellget-on-linux-macos-and-windows
if (!(Get-Module -ListAvailable -Name posh-git))
{
	Install-Module posh-git -Scope CurrentUser -Force
}
Import-Module posh-git

if (!(Get-Module -ListAvailable -Name DockerCompletion))
{
	Install-Module DockerCompletion -Scope CurrentUser -Force
}
Import-Module DockerCompletion

if (Test-CommandExists uv)
{
	(& uv generate-shell-completion powershell) | Out-String | Invoke-Expression
	(& uvx --generate-shell-completion powershell) | Out-String | Invoke-Expression
}

if (Test-CommandExists sqlcmd)
{
	(& sqlcmd completion powershell) | Out-String | Invoke-Expression
}

if (Test-CommandExists kubectl)
{
	(& kubectl completion powershell) | Out-String | Invoke-Expression
}
