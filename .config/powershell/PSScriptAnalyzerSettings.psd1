@{
	# PSScriptAnalyzer default settings file.
	# Used implicitly by Invoke-ScriptAnalyzer and Invoke-Formatter
	# via $PSDefaultParameterValues.

	# ExcludeRules = @()
	# IncludeRules = @()
	Rules = @{
		PSPlaceOpenBrace = @{
			Enable = $true
			OnSameLine = $true
			NewLineAfter = $true
			IgnoreOneLineBlock = $true
		}
	}
}
