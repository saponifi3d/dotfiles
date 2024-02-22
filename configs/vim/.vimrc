" Typo fixes
map :W :w
map :Q :q
map :Wq :wq
map :WQ :wq
map :Vs :vs
map :Bd :bd

" FZF
map :grep :Ag<space>
map :ack :Ag<space>
map :ag :Ag<Space>

map <F2> :NERDTreeToggle<CR>
map <F3> :copen<CR>
map <Leader>o :copen<CR>

" Navigation
map <Leader>g :vs<CR>:ALEGoToDefinition<CR>
map <Leader>t :GFiles<CR>
map <Leader>y :GFiles?<CR>
map <Leader>d :ALEGoToDefinition<CR>
map <Leader>r :ALEFindReferences<CR>
map <Leader>k :Buffers<CR>

" General Setings
set scrolloff=3
set tabstop=2
set shiftwidth=2

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

set backspace=indent,eol,start
syntax on

" Enable spell check for markdown files
autocmd BufRead,BufNewFile *.md setlocal spell
let g:vim_markdown_folding_disabled=1

" vim-plug
call plug#begin()

Plug 'preservim/nerdtree'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'dense-analysis/ale'
Plug 'vim-airline/vim-airline'
Plug 'tpope/vim-fugitive'
Plug 'pangloss/vim-javascript'
Plug 'mxw/vim-jsx'
Plug 'prettier/vim-prettier'
Plug 'leafgarland/typescript-vim'
Plug 'peitalin/vim-jsx-typescript'
Plug 'tpope/vim-fugitive'
Plug 'github/copilot.vim'

call plug#end()
"""

filetype plugin indent on

set laststatus=2
let g:javascript_plugin_jsdoc = 1

" Configure Airline
let g:airline#extensions#ale#enabled = 1

" Configure ALE
let g:ale_echo_msg_error_str = 'Error'
let g:ale_echo_msg_warning_str = 'Warning'
let g:ale_echo_msg_format = '[%severity%][%linter%]: %s'

"" ALE - Use quickfix
let g:ale_virtualtext_cursor = 'disabled'
let g:ale_set_loclist = 0
let g:ale_set_quickfix = 1

" Configure Python Folds
autocmd FileType python set foldmethod=indent
autocmd FileType python set foldlevel=99
