set number
set termguicolors

"dein Scripts-----------------------------
if &compatible
  set nocompatible               " Be iMproved
endif

" Required:

let s:dein_dir = expand('~/.cache/dein')
let s:dein_repo_dir = s:dein_dir . '/repos/github.com/Shougo/dein.vim'

" If 'dein.vim' is NO installed, download and install
if &runtimepath !~# '/dein.vim'

  if !isdirectory(s:dein_repo_dir)

    execute '!git clone https://github.com/Shougo/dein.vim' s:dein_repo_dir

  endif

  execute 'set runtimepath^=' . fnamemodify(s:dein_repo_dir, ':p')

endif

"dein Scripts-----------------------------
if &compatible
  set nocompatible               " Be iMproved
endif

" Required:
set runtimepath+=~/.cache/dein/repos/github.com/Shougo/dein.vim

" Required:
if dein#load_state('~/.cache/dein')
  call dein#begin('~/.cache/dein')

  " Let dein manage dein
  " Required:
  call dein#add('~/.cache/dein/repos/github.com/Shougo/dein.vim')

  " Add or remove your plugins here like this:
  call dein#add('Shougo/neosnippet.vim')
  call dein#add('Shougo/neosnippet-snippets')

	" Theme
	call dein#add('joshdick/onedark.vim')
	" Shorthand notation; fetches https://github.com/junegunn/vim-easy-align
	call dein#add('junegunn/vim-easy-align')

	" Any valid git URL is allowed
	call dein#add('https://github.com/junegunn/vim-github-dashboard.git')

	" Multiple Plug commands can be written in a single line using | separators
	call dein#add('SirVer/ultisnips')
	call dein#add('honza/vim-snippets')

	" On-demand loading
	call dein#add('scrooloose/nerdtree', { 'on':  'NERDTreeToggle' })
	call dein#add('tpope/vim-fireplace', { 'for': 'clojure' })

	" Using a non-master branch
	call dein#add('rdnetto/YCM-Generator', { 'branch': 'stable' }) 
	" Using a tagged release; wildcard allowed (requires git 1.9.2 or above)
	"call dein#add('fatih/vim-go', { 'tag': '*' })

	" Plugin options
	call dein#add('nsf/gocode', { 'tag': 'v.20150303', 'rtp': 'vim' })

	" Plugin outside ~/.vim/plugged with post-update hook
	call dein#add('junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' })
	call dein#add('junegunn/fzf.vim')

	" Using vim lsp
	call dein#add('prabirshrestha/async.vim')
	call dein#add('prabirshrestha/vim-lsp')
	call dein#add('prabirshrestha/asyncomplete.vim')
	call dein#add('prabirshrestha/asyncomplete-lsp.vim')
	call dein#add('mattn/vim-lsp-settings')
	let g:lsp_diagnostics_enabled=0

	"
	call dein#add('ntpeters/vim-better-whitespace')
	call dein#add('Yggdroot/indentLine')
	call dein#add('airblade/vim-rooter')
	call dein#add('tpope/vim-fugitive')
	call dein#add('airblade/vim-gitgutter')
	call dein#add('xuyuanp/nerdtree-git-plugin', { 'on': 'NERDTreeToggle' })
	call dein#add('dense-analysis/ale')
	call dein#add('neoclide/coc.nvim', {'branch': 'release'})
	call dein#add('itchyny/lightline.vim')
	call dein#add('sheerun/vim-polyglot')

	"Snipet
	call dein#add('SirVer/ultisnips')
	call dein#add('honza/vim-snippets')

	"Terminal
	call dein#add('kassio/neoterm')

	"CommentOut
	call dein#add('tpope/vim-commentary')

	"Undo
	call dein#add('mbbill/undotree')

	"easymotion/vim-easymotion
	call dein#add('easymotion/vim-easymotion')

	"tpope/vim-surround
	call dein#add('tpope/vim-surround')

	"jiangmiao/auto-pairs
	call dein#add('jiangmiao/auto-pairs')

	"Japanese help
	call dein#add('vim-jp/vimdoc-ja')
	set helplang=ja,en

	"Required:
  call dein#end()
  call dein#save_state()
endif

" Required:
filetype plugin indent on
syntax enable

" If you want to install not installed plugins on startup.
if dein#check_install()
  call dein#install()
endif

"End dein Scripts-------------------------




let g:python_host_prog = $HOME . '/.anyenv/envs/pyenv/versions/neovim2/bin/python'
let g:python3_host_prog = $HOME . '/.anyenv/envs/pyenv/versions/neovim3/bin/python'

let g:ruby_host_prog = $HOME . '/.anyenv/envs/rbenv/versions/2.6.5/bin/neovim-ruby-host'
let g:node_host_prog = $HOME . '/.anyenv/envs/nodenv/versions/13.5.0/lib/node_modules/neovim/bin/cli.js'

"set runtimepath+=~/.vim_runtime
"
"source ~/.vim_runtime/vimrcs/basic.vim
"source ~/.vim_runtime/vimrcs/filetypes.vim
"source ~/.vim_runtime/vimrcs/plugins_config.vim
"source ~/.vim_runtime/vimrcs/extended.vim

"try
"source ~/.plugin.vim
"catch
"endtry

" color theme
colorscheme onedark

" key-map
nmap <C-e> :NERDTreeToggle<CR>

set shiftwidth=2
set tabstop=2

nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" kassio/neoterm
let g:neoterm_default_mod='belowright'
let g:neoterm_size=10
let g:neoterm_autoscroll=1
tnoremap <silent> <C-w> <C-\><C-n><C-w>
nnoremap <silent> <C-n> :TREPLSendLine<CR>j0
vnoremap <silent> <C-n> V:TREPLSendSelection<CR>'>j0

" mbbill/undotree
nmap <F5> :UndotreeToggle<CR>
