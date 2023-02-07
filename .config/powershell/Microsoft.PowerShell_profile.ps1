# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles

#region Functions

# Lists the aliases for any cmdlet.
function Get-CmdletAlias ($cmdletname) {
	Get-Alias |
		Where-Object -FilterScript {$_.Definition -like "$cmdletname"} |
			Format-Table -Property Definition, Name -AutoSize
}

# https://www.reddit.com/r/Windows11/comments/pu5aa3/howto_disable_new_context_menu_explorer_command/?utm_source=share&utm_medium=web2x&context=3
function Disable-New-Context-Menu {
	reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve
}

# Print the values of all environment variables.
function env {
	Get-ChildItem env:
}

function path {
	$env:PATH -split ";"
}

function export($envname, $envvalue) {
	if ([string]::IsNullOrEmpty([Environment]::GetEnvironmentVariable($envname))) {
		[Environment]::SetEnvironmentVariable(
			$envname,
			$envvalue,
			"User"
		)
	}

	Set-Item "env:$envname" $envvalue
}

#endregion

#region Aliases
#endregion

#region Environment Variables

# Enable symlinking.
export "MSYS" "winsymlinks:nativestrict"
export "XDG_CONFIG_HOME" "$env:USERPROFILE\.config"
export "XDG_LOCAL_HOME" "$env:USERPROFILE\.local"
export "XDG_DATA_HOME" "$env:XDG_LOCAL_HOME\share"
export "CARGO_HOME" "$env:XDG_DATA_HOME\cargo"
export "RUSTUP_HOME" "$env:XDG_DATA_HOME\rustup"
export "KOMOREBI_CONFIG_HOME" "$env:XDG_CONFIG_HOME\komorebi"
export "PNPM_HOME" "$env:XDG_DATA_HOME\pnpm"
export "GOPATH" "$env:XDG_DATA_HOME\go"

$env:PATH = "$env:HOMEPATH\.asdf;$env:PATH"
$env:PATH = "$env:HOMEPATH\.asdf\shims;$env:PATH"

#endregion

# Hooking zoxide.
Invoke-Expression (& {
	$hook = if ($PSVersionTable.PSVersion.Major -lt 6) { 'prompt' } else { 'pwd' }
	(zoxide init --hook $hook powershell | Out-String)
})

# Initializing Starship prompt.
Invoke-Expression (&starship init powershell)
export "STARSHIP_SHELL" "C:\Program Files\Git\bin\bash.exe --noprofile --norc"
