#!/usr/bin/env pwsh
#
# Activate/init scripts

if (Test-CommandExists tv) {
	# Adds CTRL-R & CTRL-T keybinds.
	tv init power-shell | Out-String | Invoke-Expression
}

if (Test-CommandExists atuin) {
	atuin init --disable-up-arrow powershell | Out-String | Invoke-Expression
}

if (Test-CommandExists starship) {
	# Initializing Starship prompt.
	Invoke-Expression (&starship init powershell)

	# https://learn.microsoft.com/en-us/windows/terminal/tutorials/new-tab-same-directory#powershell-with-starship
	if ($env:WT_SESSION) {
		function Invoke-Starship-PreCommand {
			$loc = $executionContext.SessionState.Path.CurrentLocation
			$prompt = "$([char]27)]9;12$([char]7)"
			if ($loc.Provider.Name -eq 'FileSystem') {
				$prompt += "$([char]27)]9;9;`"$($loc.ProviderPath)`"$([char]27)\"
			}
			$host.ui.Write($prompt)
		}
	}
}

if (Test-CommandExists mise) {
	mise activate pwsh | Out-String | Invoke-Expression
}

# NOTE: `zoxide` should be initialized after `starship`.
# https://github.com/ajeetdsouza/zoxide/issues/1021#issuecomment-2810261891
if (Test-CommandExists zoxide) {
	Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

# if (Test-CommandExists fnox) {
# 	(&fnox activate pwsh) | Out-String | Invoke-Expression
# }

