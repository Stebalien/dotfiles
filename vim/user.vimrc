call pathogen#runtime_append_all_bundles()
call pathogen#helptags()

colorscheme BusyBee
set cursorline
" Always show tabs
set showtabline=2
" Everything I write uses spaces
set expandtab

" In case I forget to start as root
cmap w!! w !sudo tee % >/dev/null<CR>:e!<CR><CR>

" For Vim as man
let $PAGER=''

" Python
autocmd FileType python iab slef self
let g:pydiction_location = '~/.vim/bundle/pydiction/complete-dict'

" Mail
autocmd FileType mail set spell
autocmd FileType mail map q :wq<CR>
autocmd FileType mail set showtabline=0
autocmd FileType mail unmap t
autocmd FileType mail set whichwrap=b,s,<,>,[,]
autocmd FileType mail set nonumber

" Rst
autocmd FileType rst let @h = "yypVr"

" HTML
autocmd FileType html,htmldjango,jinjahtml,eruby,mako let b:closetag_html_style=1
autocmd FileType html,xhtml,xml,htmldjango,jinjahtml,eruby,mako source ~/.vim/bundle/closetag/plugin/closetag.vim

"highlight ExtraWhitespace ctermbg=red guibg=red
"match ExtraWhitespace /\s\+$/
"autocmd BufWinEnter * match ExtraWhitespace /\s\+$/
"autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
"autocmd InsertLeave * match ExtraWhitespace /\s\+$/
"autocmd BufWinLeave * call clearmatches()

let g:showmarks_ignore_type="hmpr"
let g:showmarks_textother="\t"
let g:showmarks_textlower="\t"
let g:showmarks_textother="\t"
highlight ShowMarksHLl ctermfg=148 ctermbg=234
highlight ShowMarksHLu ctermfg=148 ctermbg=234
highlight ShowMarksHLo ctermfg=237 ctermbg=234

map <C-p> "*p
map <C-y> "*y
no Q q
map q :q<CR>
vmap ii <ESC>i

set mouse=a

"autocmd FileType python map <F5> :wa<CR>:!vidle -l %<CR><CR>
"autocmd FileType python vmap <F4> :!vidle -s %s<CR><CR>

fun Ranger()
  silent !ranger --choosefile=/tmp/chosen
  if filereadable('/tmp/chosen')
    exec 'edit ' . system('cat /tmp/chosen')
    call system('rm /tmp/chosen')
  endif
  redraw!
endfun
map <C-o> :call Ranger()<CR>
