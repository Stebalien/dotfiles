" All system-wide defaults are set in $VIMRUNTIME/archlinux.vim (usually just
" /usr/share/vim/vimfiles/archlinux.vim) and sourced by the call to :runtime
" you can find below.  If you wish to change any of those settings, you should
" do it in this file (/etc/vimrc), since archlinux.vim will be overwritten
" everytime an upgrade of the vim packages is performed.  It is recommended to
" make changes after sourcing archlinux.vim since it alters the value of the
" 'compatible' option.

" This line should not be removed as it ensures that various options are
" properly set to work with the Vim-related packages.
runtime! archlinux.vim

" If you prefer the old-style vim functionalty, add 'runtime! vimrc_example.vim'
" Or better yet, read /usr/share/vim/vim73/vimrc_example.vim or the vim manual
" and configure vim to your own liking!

" Syntax
syntax on
filetype plugin indent on
set ofu=syntaxcomplete#Complete

" Look and feel
set background="dark"
colors busybee
set number
set hls
set autoindent


" Highlight problematic whitespace (spaces before tabs)
hi RedundantSpaces ctermfg=214 ctermbg=160 cterm=bold
match RedundantSpaces / \+\ze\t/

" Toggle Numbering
function TogglePaste()
    set nonumber!
    set foldcolumn=0
    set paste!
endfunction
com Paste call TogglePaste()

" View Man page
source /usr/share/vim/vim73/ftplugin/man.vim

" Tabbing
set shiftwidth=4
set tabstop=4

" Autocomplete
set completeopt=longest,menuone
inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
inoremap <expr> <C-n> pumvisible() ? '<C-n>' :
  \ '<C-n><C-r>=pumvisible() ? "\<lt>Down>" : ""<CR>'
inoremap <expr> <M-,> pumvisible() ? '<C-n>' :
  \ '<C-x><C-o><C-n><C-p><C-r>=pumvisible() ? "\<lt>Down>" : ""<CR>'
highlight Pmenu ctermbg=blue ctermfg=white


" Tabs
imap <C-t> <Esc>:tabnew<CR>
map t :tabnew<CR>:e 
map <Tab> :tabn<CR>
map <S-Tab> :tabp<CR>
map [Z :tabp<CR>
