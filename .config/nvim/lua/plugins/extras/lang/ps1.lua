local pssa_settings_path = vim.fs.normalize(
	vim.fn.expand("~/.config/pwsh/PSScriptAnalyzerSettings.psd1")
)
local indentation_options = {}

local function notify_settings_issue(message)
	vim.notify(
		("PSES formatting settings: %s"):format(message),
		vim.log.levels.WARN
	)
end

local function read_pssa_settings()
	if vim.fn.filereadable(pssa_settings_path) ~= 1 then
		notify_settings_issue(
			("could not read %s; using PSES defaults"):format(pssa_settings_path)
		)
		return {}
	end

	if vim.fn.executable("pwsh") ~= 1 then
		notify_settings_issue("pwsh is unavailable; using PSES defaults")
		return {}
	end

	local ok, process = pcall(vim.system, {
		"pwsh",
		"-NoLogo",
		"-NoProfile",
		"-NonInteractive",
		"-Command",
		"$ErrorActionPreference = 'Stop'; "
			.. "$settings = Import-PowerShellDataFile -LiteralPath $env:PSSA_SETTINGS_PATH; "
			.. "$settings | ConvertTo-Json -Depth 20 -Compress",
	}, {
		env = { PSSA_SETTINGS_PATH = pssa_settings_path },
		text = true,
	})
	if not ok then
		notify_settings_issue(
			("could not start pwsh (%s); using PSES defaults"):format(process)
		)
		return {}
	end

	local result = process:wait()
	if result.code ~= 0 then
		local detail = vim.trim(result.stderr or "")
		if detail == "" then
			detail = ("pwsh exited with code %d"):format(result.code)
		end
		notify_settings_issue(("%s; using PSES defaults"):format(detail))
		return {}
	end

	local decoded, settings = pcall(vim.json.decode, result.stdout)
	if not decoded or type(settings) ~= "table" then
		notify_settings_issue(
			("could not parse %s; using PSES defaults"):format(pssa_settings_path)
		)
		return {}
	end

	return settings
end

local function copy_boolean(target, source, source_key, target_key)
	local value
	if type(source) == "table" then
		value = source[source_key]
	end
	if type(value) == "boolean" then
		target[target_key] = value
	end
end

local function map_rule(target, rules, rule_name, mappings)
	local rule = rules[rule_name]
	if type(rule) ~= "table" then
		return
	end
	for source_key, target_key in pairs(mappings) do
		copy_boolean(target, rule, source_key, target_key)
	end
end

local function translate_pssa_settings(settings)
	if type(settings) ~= "table" or type(settings.Rules) ~= "table" then
		return {}
	end

	local formatting = { preset = "Custom" }
	local rules = settings.Rules

	map_rule(formatting, rules, "PSPlaceOpenBrace", {
		OnSameLine = "openBraceOnSameLine",
		NewLineAfter = "newLineAfterOpenBrace",
	})
	map_rule(formatting, rules, "PSPlaceCloseBrace", {
		NewLineAfter = "newLineAfterCloseBrace",
	})

	local open_brace = rules.PSPlaceOpenBrace
	local close_brace = rules.PSPlaceCloseBrace
	if
		type(open_brace) == "table"
		and type(open_brace.IgnoreOneLineBlock) == "boolean"
	then
		formatting.ignoreOneLineBlock = open_brace.IgnoreOneLineBlock
	elseif
		type(close_brace) == "table"
		and type(close_brace.IgnoreOneLineBlock) == "boolean"
	then
		formatting.ignoreOneLineBlock = close_brace.IgnoreOneLineBlock
	end

	map_rule(formatting, rules, "PSUseConsistentWhitespace", {
		CheckOpenBrace = "whitespaceBeforeOpenBrace",
		CheckOpenParen = "whitespaceBeforeOpenParen",
		CheckOperator = "whitespaceAroundOperator",
		CheckSeparator = "whitespaceAfterSeparator",
		CheckParameter = "whitespaceBetweenParameters",
		CheckInnerBrace = "whitespaceInsideBrace",
		CheckPipe = "addWhitespaceAroundPipe",
		CheckPipeForRedundantWhitespace = "trimWhitespaceAroundPipe",
	})
	map_rule(formatting, rules, "PSAlignAssignmentStatement", {
		CheckHashtable = "alignPropertyValuePairs",
		CheckEnums = "alignEnumMemberValues",
	})
	map_rule(formatting, rules, "PSUseCorrectCasing", {
		Enable = "useCorrectCasing",
	})
	map_rule(formatting, rules, "PSAvoidUsingDoubleQuotesForConstantString", {
		Enable = "useConstantStrings",
	})
	map_rule(formatting, rules, "PSAvoidSemicolonsAsLineTerminators", {
		Enable = "avoidSemicolonsAsLineTerminators",
	})

	local indentation = rules.PSUseConsistentIndentation
	if type(indentation) == "table" then
		local size = indentation.IndentationSize
		if type(size) == "number" and size > 0 and size == math.floor(size) then
			indentation_options.tab_size = size
		end

		if indentation.Kind == "tab" or indentation.Kind == "space" then
			indentation_options.insert_spaces = indentation.Kind == "space"
		end

		local pipeline_styles = {
			IncreaseIndentationForFirstPipeline = true,
			IncreaseIndentationAfterEveryPipeline = true,
			NoIndentation = true,
			None = true,
		}
		if pipeline_styles[indentation.PipelineIndentation] then
			formatting.pipelineIndentationStyle = indentation.PipelineIndentation
		end
	end

	-- PSES always enables its core formatting rules, so their rule-level
	-- Enable flags and NoEmptyLineBefore are not representable. IndentationSize
	-- and Kind are applied to buffer options below. ExcludeRules is lint-only.
	-- Do not infer autoCorrectAliases from PSAvoidUsingCmdletAliases.

	return formatting
end

local function apply_indentation_options(buf)
	if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].filetype ~= "ps1" then
		return
	end
	if indentation_options.tab_size then
		vim.bo[buf].shiftwidth = indentation_options.tab_size
		vim.bo[buf].tabstop = indentation_options.tab_size
	end
	if indentation_options.insert_spaces ~= nil then
		vim.bo[buf].expandtab = indentation_options.insert_spaces
	end
end

return {
	{
		"mason-org/mason.nvim",
		opts = {
			ensure_installed = {
				"powershell-editor-services",
			},
		},
	},
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				-- PowerShell is managed by `powershell.nvim`.
				powershell_es = { enabled = false },
			},
		},
	},
	{
		"TheLeoP/powershell.nvim",
		ft = "ps1",
		opts = function(_, opts)
			local settings = read_pssa_settings()
			indentation_options = {}
			local code_formatting = translate_pssa_settings(settings)

			return vim.tbl_deep_extend("force", opts, {
				bundle_path = vim.fn.stdpath("data")
					.. "/mason/packages/powershell-editor-services",
				settings = {
					powershell = {
						codeFormatting = code_formatting,
					},
				},
				-- PSES otherwise registers formatting dynamically after initialize.
				-- Keep these capabilities static so Conform can select the LSP
				-- formatter immediately after the client attaches.
				capabilities = vim.tbl_deep_extend(
					"force",
					vim.lsp.protocol.make_client_capabilities(),
					{
						textDocument = {
							formatting = { dynamicRegistration = false },
						},
					}
				),
			})
		end,
		config = function(_, opts)
			require("powershell").setup(opts)

			local group = vim.api.nvim_create_augroup(
				"powershell-pse-formatting",
				{ clear = true }
			)
			vim.api.nvim_create_autocmd("FileType", {
				group = group,
				pattern = "ps1",
				callback = function(args)
					apply_indentation_options(args.buf)
				end,
			})
			for _, buf in ipairs(vim.api.nvim_list_bufs()) do
				apply_indentation_options(buf)
			end
		end,
	},
	{
		"conform.nvim",
		optional = true,
		opts = function(_, opts)
			local user_opts = {
				formatters = {
					ps_script_analyzer = {
						command = "pwsh",
						-- Profiles provide the shared `PSScriptAnalyzer` settings.
						stdin = true,
						args = {
							"-Command",
							"Invoke-Formatter",
							"-ScriptDefinition",
							"($input | Out-String)",
						},
					},
				},
				formatters_by_ft = {
					ps1 = { "ps_script_analyzer" },
				},
			}

			local merged_opts = vim.tbl_deep_extend("force", opts, user_opts)

			return merged_opts
		end,
	},
	{
		"mfussenegger/nvim-lint",
		optional = true,
		opts = function(_, opts)
			local severity = {
				[0] = vim.diagnostic.severity.INFO,
				[1] = vim.diagnostic.severity.WARN,
				[2] = vim.diagnostic.severity.ERROR,
			}
			local user_opts = {
				linters = {
					ps_script_analyzer = {
						cmd = "pwsh",
						stdin = true,
						args = {
							"-Command",
							"Invoke-ScriptAnalyzer",
							"-ScriptDefinition",
							"($input | Out-String) | ConvertTo-Json -Depth 4",
						},
						parser = function(output)
							local decoded = vim.json.decode(output)
							local messages = {}
							if vim.isarray(decoded) then
								messages = decoded
							else
								table.insert(messages, 1, decoded)
							end
							local diagnostics = {}
							for _, item in ipairs(messages) do
								table.insert(diagnostics, {
									lnum = item.Extent.StartLineNumber - 1,
									col = item.Extent.StartColumnNumber - 1,
									end_lnum = item.Extent.EndLineNumber - 1,
									end_col = item.Extent.EndColumnNumber - 1,
									code = item.RuleName,
									source = "PSScriptAnalyzer",
									severity = severity[item.Severity],
									message = item.Message,
								})
							end
							return diagnostics
						end,
					},
				},
				linters_by_ft = {
					ps1 = { "ps_script_analyzer" },
				},
			}

			local merged_opts = vim.tbl_deep_extend("force", opts, user_opts)
			return merged_opts
		end,
	},
}
