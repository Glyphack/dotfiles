nnoremap <C-p> :<C-u>FZF<CR>

packadd minpac
call minpac#init()

call minpac#add('morhetz/gruvbox')
call minpac#add('junegunn/fzf')

:tnoremap <Esc> <C-\><C-n>
let g:gruvbox_italics=1
colorschem gruvbox

command! PackUpdate call minpac#update()
command! PackClean call minpac#clean()
