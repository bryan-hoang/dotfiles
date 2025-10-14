#!/usr/bin/env pwsh

Set-UserEnvVar 'POWERSHELL_UPDATECHECK' 'LTS'
Set-UserEnvVar 'MSYS' 'winsymlinks:nativestrict'
Set-UserEnvVar 'USERPROFILE' "$HOME"
Set-UserEnvVar 'APPDATA' (Join-Path -Resolve $env:USERPROFILE 'AppData' 'Roaming')
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
Set-UserEnvVar 'PNPM_HOME' (Join-Path $env:XDG_DATA_HOME 'pnpm')

Add-UserPath "$env:XDG_BIN_HOME"
Add-UserPath (Join-Path $env:APPDATA "npm")
Add-UserPath "$env:PNPM_HOME"
if (Test-Path $(Join-Path "$env:CARGO_HOME" "bin")) {
  Add-UserPath $(Join-Path "$env:CARGO_HOME" "bin")
}

if ($IsWindows) {
		$env:PATH = "$([Environment]::GetEnvironmentVariable("Path", "User"))$([Environment]::GetEnvironmentVariable("Path", "Machine"))"
}

if (Test-CommandExists 'vivid') {
	Set-UserEnvVar 'LS_COLORS' (vivid generate catppuccin-mocha)
}
