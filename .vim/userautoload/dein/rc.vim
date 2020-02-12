if &compatible
  set nocompatible
endif

let s:dein_path = expand('~/.vim/dein')
let s:dein_repo_path = s:dein_path . '/repos/github.com/Shougo/dein.vim'

" deinなかったらcloneでもってくる
if !isdirectory(s:dein_repo_path)
  execute '!git clone https://github.com/Shougo/dein.vim' s:dein_repo_path
endif

execute 'set runtimepath^=' . s:dein_repo_path

let g:dein#install_progress_type = 'title'
let g:dein#enable_notification = 1

call dein#begin(s:dein_path)
call dein#load_toml('~/.vim/userautoload/dein/plugins.toml', {'lazy': 0})
call dein#load_toml('~/.vim/userautoload/dein/plugins-lazy.toml', {'lazy': 1})
call dein#end()

if dein#check_install()
  call dein#install()
endif

let g:python_host_prog = $HOME . '/.anyenv/envs/pyenv/versions/neovim2/bin/python'
let g:python3_host_prog = $HOME . '/.anyenv/envs/pyenv/versions/neovim3/bin/python'
let g:ruby_host_prog = $HOME . '/.anyenv/envs/rbenv/versions/2.6.5/bin/neovim-ruby-host'
let g:node_host_prog = $HOME . '/.anyenv/envs/nodenv/versions/13.5.0/lib/node_modules/neovim/bin/cli.js'

