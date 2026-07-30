# Avoid `coreutils` aliases that trip up agents.
$AllowedAliases = 'cd', 'chdir', 'pwd', 'pushd', 'popd', 'clear', 'cls'
Get-Alias | Where-Object Name -NotIn $AllowedAliases | Remove-Alias -Force

if (Test-CommandExists eza) {
	Set-Alias -Name ls -Value 'eza'
}
