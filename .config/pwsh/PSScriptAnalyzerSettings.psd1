# https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/rules/readme?view=ps-modules
@{
	# PSScriptAnalyzer default settings file.
	# Used implicitly by Invoke-ScriptAnalyzer and Invoke-Formatter
	# via $PSDefaultParameterValues.

	ExcludeRules = @(
		'PSAvoidUsingInvokeExpression'
	)
	# IncludeRules = @()
	Rules = @{
		PSAvoidUsingPositionalParameters = @{
			Enable           = $true
			CommandAllowList = 'Join-Path'
		}
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
			NewLineAfter = $false
		}
		PSUseConsistentIndentation = @{
			Enable = $true
			IndentationSize = 2
			Kind = 'tab'
		}
	}
}
