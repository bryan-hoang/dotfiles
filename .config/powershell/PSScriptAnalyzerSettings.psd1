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
		PSPlaceCloseBrace = @{
			Enable = $true
			NoEmptyLineBefore = $true
			IgnoreOneLineBlock = $true
			NewLineAfter = $true
		}
		PSUseConsistentIndentation = @{
			Enable = $true
			IndentationSize = 2
			Kind = 'tab'
		}
	}
}
