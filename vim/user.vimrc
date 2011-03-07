colorscheme BusyBee
" Always show tabs
set showtabline=2
" Everything I write uses spaces
set expandtab

" In case I forget to start as root
cmap w!! w !sudo tee % >/dev/null<CR>:e!<CR><CR>

" For Vim as man
let $PAGER=''

" Python Complete
autocmd FileType python set complete+=k~/.vim/syntax/python.vim
autocmd FileType python iab slef self

autocmd FileType mail set spell
autocmd FileType mail map q :wq<CR>
autocmd FileType mail set showtabline=0
autocmd FileType mail unmap t
autocmd FileType mail set whichwrap=b,s,<,>,[,]
autocmd FileType mail set nonumber

autocmd FileType rst let @h = "yypVr"

highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$/
autocmd BufWinEnter * match ExtraWhitespace /\s\+$/
autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
autocmd InsertLeave * match ExtraWhitespace /\s\+$/
autocmd BufWinLeave * call clearmatches()

map <C-p> "+p
map <C-y> "+y
no Q q
map q :q<CR>
vmap i <ESC>i

set mouse=a

fun Ranger()
  silent !ranger --choosefile=/tmp/chosen
  if filereadable('/tmp/chosen')
    exec 'edit ' . system('cat /tmp/chosen')
    call system('rm /tmp/chosen')
  endif
  redraw!
endfun
map <C-o> :call Ranger()<CR>
