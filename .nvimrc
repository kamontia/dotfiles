set number
set termguicolors



let g:python_host_prog = $HOME . '/.anyenv/envs/pyenv/versions/neovim2/bin/python'
let g:python3_host_prog = $HOME . '/.anyenv/envs/pyenv/versions/neovim3/bin/python'

let g:ruby_host_prog = $HOME . '/.anyenv/envs/rbenv/versions/2.6.5/bin/neovim-ruby-host'
let g:node_host_prog = $HOME . '/.anyenv/envs/nodenv/versions/8.13.0/lib/node_modules/neovim/bin/cli.js'

set runtimepath+=~/.vim_runtime

source ~/.vim_runtime/vimrcs/basic.vim
source ~/.vim_runtime/vimrcs/filetypes.vim
source ~/.vim_runtime/vimrcs/plugins_config.vim
source ~/.vim_runtime/vimrcs/extended.vim

try
source ~/.plugin.vim
catch
endtry

" color theme
let g:lightline = {'colorscheme': 'wombat'}


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
