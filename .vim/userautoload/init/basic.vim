set number
set termguicolors

let g:python_host_prog = $HOME . '/.anyenv/envs/pyenv/versions/neovim2/bin/python'
let g:python3_host_prog = $HOME . '/.anyenv/envs/pyenv/versions/neovim3/bin/python'
let g:ruby_host_prog = $HOME . '/.anyenv/envs/rbenv/versions/2.6.5/bin/neovim-ruby-host'
let g:node_host_prog = $HOME . '/.anyenv/envs/nodenv/versions/13.5.0/lib/node_modules/neovim/bin/cli.js'


" color theme
" colorscheme onedark

set autoindent         "改行時に自動でインデントする
set tabstop=2          "タブを何文字の空白に変換するか
set shiftwidth=2       "自動インデント時に入力する空白の数
set expandtab          "タブ入力を空白に変換
set splitright         "画面を縦分割する際に右に開く

set smartcase
set smartindent
set incsearch
set wildmenu

" Undo永続化
if has('persistent_undo')
  set undodir=~/.vim/undo
  set undofile
endif

" Clipboard
set clipboard+=unnamed
