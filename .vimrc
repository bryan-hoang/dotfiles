if exists('g:vscode')
  " VSCode extension
else
  " Ordinary neovim
  set runtimepath+=~/.vim_runtime

  source ~/.vim_runtime/vimrcs/basic.vim
  source ~/.vim_runtime/vimrcs/filetypes.vim
  source ~/.vim_runtime/vimrcs/plugins_config.vim
  source ~/.vim_runtime/vimrcs/extended.vim
endif

try
  source ~/.vim_runtime/my_configs.vim
catch
endtry
