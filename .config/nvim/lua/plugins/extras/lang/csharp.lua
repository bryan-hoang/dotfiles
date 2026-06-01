-- https://github.com/tris203/rzls.nvim#example-configuration
return {
	{
		"seblyng/roslyn.nvim",
		ft = {
			"cs",
		},
		dependencies = {
			{
				"mason-org/mason.nvim",
				opts = {
					registries = {
						"github:mason-org/mason-registry",
					},
					ensure_installed = {
						"roslyn-language-server",
					},
				},
			},
			{
				"neovim/nvim-lspconfig",
				opts = {
					servers = {
						-- Ensure it only one instance of the LS is started.
						roslyn_ls = {
							enabled = false,
						},
					},
				},
			},
		},
		config = function(_, opts)
			require("roslyn").setup(opts)
			vim.lsp.config("roslyn", {
				filetypes = { "cs", "razor" },
				settings = {
					["csharp|background_analysis"] = {
						dotnet_analyzer_diagnostics_scope = "openFiles",
						dotnet_compiler_diagnostics_scope = "openFiles",
					},
					["csharp|inlay_hints"] = {
						csharp_enable_inlay_hints_for_implicit_object_creation = true,
						csharp_enable_inlay_hints_for_implicit_variable_types = true,
						csharp_enable_inlay_hints_for_lambda_parameter_types = true,
						csharp_enable_inlay_hints_for_types = true,
						dotnet_enable_inlay_hints_for_indexer_parameters = true,
						dotnet_enable_inlay_hints_for_literal_parameters = true,
						dotnet_enable_inlay_hints_for_object_creation_parameters = true,
						dotnet_enable_inlay_hints_for_other_parameters = true,
						dotnet_enable_inlay_hints_for_parameters = true,
						dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = true,
						dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
						dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
					},
					["csharp|symbol_search"] = {
						dotnet_search_reference_assemblies = true,
					},
					["csharp|completion"] = {
						dotnet_show_name_completion_suggestions = true,
						dotnet_show_completion_items_from_unimported_namespaces = true,
						dotnet_provide_regex_completions = true,
					},
					["csharp|code_lens"] = {
						dotnet_enable_references_code_lens = true,
					},
				},
			})
		end,
	},
	{
		"stevearc/conform.nvim",
		optional = true,
		opts = {
			formatters_by_ft = {
				cs = { "csharpier" },
			},
		},
	},
}
