#region Functions

# Add commands that make it easy to open your profile.
function Pro {
  code $PROFILE.CurrentUserAllHosts
}

# Add a function that lists the aliases for any cmdlet.
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
function printenv {
  Get-ChildItem env:
}

function path {
  $env:PATH -split ";"
}

#endregion

#region Aliases

Set-Alias which get-command

#endregion

#region Environment Variables

$env:PATH = "$env:HOMEPATH\.asdf;$env:PATH"
$env:PATH = "$env:HOMEPATH\.asdf\shims;$env:PATH"

#endregion

# Initializing Starship prompt.
Invoke-Expression (&starship init powershell)
