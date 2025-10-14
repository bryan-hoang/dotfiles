#!/usr/bin/env pwsh

# https://github.com/dahlbyk/posh-git#installing-posh-git-via-powershellget-on-linux-macos-and-windows
if (!(Get-Module -ListAvailable -Name posh-git)) {
	Install-Module posh-git -Scope CurrentUser -Force
}
Import-Module posh-git

if (!(Get-Module -ListAvailable -Name DockerCompletion)) {
	Install-Module DockerCompletion -Scope CurrentUser -Force
}
Import-Module DockerCompletion

if (Test-CommandExists uv) {
	(& uv generate-shell-completion powershell) | Out-String | Invoke-Expression
	(& uvx --generate-shell-completion powershell) | Out-String | Invoke-Expression
}

if (Test-CommandExists sqlcmd.exe) {
	(& sqlcmd completion powershell) | Out-String | Invoke-Expression
}

if (Test-CommandExists kubectl) {
	(& kubectl completion powershell) | Out-String | Invoke-Expression
}

# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
if (($IsWindows) -and ($env:ChocolateyInstall) -and (Test-Path(Join-Path $env:ChocolateyInstall "helpers" "chocolateyProfile.psm1"))) {
	Import-Module "$ChocolateyProfile"
}
