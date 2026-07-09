# Avoid `coreutils` aliases that trip up agents.
Get-Alias | Remove-Alias -Force

if (Test-CommandExists lsd) {
	Set-Alias -Name ls -Value lsd
}
