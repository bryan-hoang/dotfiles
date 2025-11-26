" https://github.com/neovim/neovim/blob/master/runtime/compiler/dotnet.vim
" https://learn.microsoft.com/en-us/visualstudio/msbuild/msbuild-command-line-reference

if exists("current_compiler")
	finish
endif
let current_compiler = "dotnet"

let s:cpo_save = &cpo
set cpo&vim

if get(g:, "dotnet_errors_only", v:false)
	CompilerSet makeprg=dotnet\ msbuild\ -target:rebuild\ -terminalLogger:off
				\\ -verbosity:quiet
				\\ -consoleLoggerParameters:ErrorsOnly
else
	CompilerSet makeprg=dotnet\ msbuild\ -target:rebuild\ -terminalLogger:off
				\\ -verbosity:quiet
endif

if get(g:, "dotnet_show_project_file", v:true)
	CompilerSet errorformat=%E%f(%l\\,%c):\ %trror\ %m,
				\%W%f(%l\\,%c):\ %tarning\ %m,
				\%-G%.%#
else
	CompilerSet errorformat=%E%f(%l\\,%c):\ %trror\ %m\ [%.%#],
				\%W%f(%l\\,%c):\ %tarning\ %m\ [%.%#],
				\%-G%.%#
endif

let &cpo = s:cpo_save
unlet s:cpo_save
