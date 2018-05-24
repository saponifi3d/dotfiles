" Custom Mappings
map :W :w
map :Q :q
map :Wq :wq
map :WQ :wq

map :grep :Ag<space>
map :ack :Ag<space>
map :ag :Ag<Space>

map <F2> :NERDTreeToggle<CR>
map <F3> :copen<CR>

" General Setings
set scrolloff=3
set tabstop=4
set shiftwidth=4

set nu
set autoindent
set smartindent
set expandtab
set showmatch
set encoding=utf-8

set guioptions-=T
set ruler

set ignorecase
set smartcase
set title

" fix the annoying file changed thing
set autoread

"character limit
" let &colorcolumn=join(range(20,999),',')
" highlight ColorColumn ctermbg=235 guibg=#0a0a0a


" Setup ag / searching
set grepprg=ag
set tags=./.tags

" Command-T
set wildignore+=node_modules,coverage,jest,.dist,dist,build
" set g:CommandTAcceptSelectionVSplitCommand=1
" set g:python_pep8_indent_multiline_string=0

set backspace=indent,eol,start
syntax on

" Enable spell check for markdown files
autocmd BufRead,BufNewFile *.md setlocal spell
let g:vim_markdown_folding_disabled=1

" Enable Guten-tags
let g:gutentags_enabled=1
let g:gutentags_ctags_tagfile='./.tags'

filetype plugin on
runtime macros/matchit.vim

" Turn on pathogen
execute pathogen#infect()
filetype plugin indent on

set laststatus=2
