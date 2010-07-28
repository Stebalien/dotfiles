" Always show tabs
set showtabline=2
" Everything I write uses spaces
set expandtab

" In case I forget to start as root
cmap w!! w !sudo tee % >/dev/null<CR>:e!<CR><CR>

" For Vim as man
let $PAGER=''

" Pydoc
autocmd FileType python set complete+=k~/.vim/syntax/python.vim isk+=.,(

autocmd FileType mail set spell
autocmd FileType mail map q :wq<CR>
autocmd FileType mail set showtabline=0
autocmd FileType mail unmap t
