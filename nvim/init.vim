nnoremap <C-p> :<C-u>FZF<CR>

lua require('config')
lua require('plugins')

let mapleader = ","
set encoding=utf-8
set number relativenumber
syntax enable
set noswapfile
set backspace=indent,eol,start

set tabstop=4
set softtabstop=4
set shiftwidth=4
set expandtab
set autoindent
set fileformat=unix

" Enable folding
set foldmethod=indent
set foldlevel=99
nnoremap <space> za

set clipboard=unnamed

" filetree
nnoremap g- :NvimTreeToggle<CR>
" let g:netrw_banner = 0
" let g:netrw_liststyle = 3
" let g:netrw_bufsettings = 'noma nomod nu nobl nowrap ro'
" autocmd FileType netrw setl bufhidden=delete
"-- filetree END

" terminal easy switch windows
nnoremap <M-h> <c-w>h
nnoremap <M-j> <c-w>j
nnoremap <M-k> <c-w>k
nnoremap <M-l> <c-w>l 
if has('nvim')
  tnoremap <M-h> <c-\><c-n><c-w>h
  tnoremap <M-j> <c-\><c-n><c-w>j
  tnoremap <M-k> <c-\><c-n><c-w>k
  tnoremap <M-l> <c-\><c-n><c-w>l
endif

augroup my_spelling_colors
  " Underline, don't do intrusive red things.
  autocmd!
  " autocmd ColorScheme * hi clear SpellBad
  autocmd ColorScheme * hi SpellBad cterm=underline ctermfg=NONE ctermbg=NONE term=Reverse
  autocmd ColorScheme * hi SpellCap cterm=underline ctermfg=NONE ctermbg=NONE term=Reverse
  autocmd ColorScheme * hi SpellLocal cterm=underline ctermfg=NONE ctermbg=NONE term=Reverse
  autocmd ColorScheme * hi SpellRare cterm=underline ctermfg=NONE ctermbg=NONE term=Reverse
augroup END
set spell spelllang=en
set nospell
autocmd FileType markdown setlocal spell


