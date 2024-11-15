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

" Folds
map <Leader>z za

" Navigation
map <Leader>g :vs<CR>:ALEGoToDefinition<CR>
map <Leader>t :GFiles<CR>
map <Leader>y :GFiles?<CR>
map <Leader>d :ALEGoToDefinition<CR>
map <Leader>r :ALEFindReferences<CR>
map <Leader>k :Buffers<CR>
map <Leader>f :ALEFix<CR>:ALEComplete<CR>

" General Setings
set scrolloff=5
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
set splitright

" fix the annoying file changed thing
set autoread

set backspace=indent,eol,start
syntax on

" Enable spell check for markdown files
autocmd BufRead,BufNewFile *.md setlocal spell
let g:vim_markdown_folding_disabled=1

" vim-plug
call plug#begin()

" General
Plug 'preservim/nerdtree'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'dense-analysis/ale'
Plug 'vim-airline/vim-airline'
Plug 'tpope/vim-fugitive'
Plug 'github/copilot.vim'

" JavaScript
Plug 'prettier/vim-prettier'
Plug 'pangloss/vim-javascript'

" TypeScript
Plug 'leafgarland/typescript-vim'

" React
Plug 'peitalin/vim-jsx-typescript'
Plug 'maxmellon/vim-jsx-pretty'

" Python
Plug 'michaeljsmith/vim-indent-object'

call plug#end()
"""

filetype plugin indent on

" Fix bug in leafgarland/typescript-vim
hi link typescriptReserved Keyword

set laststatus=2
let g:javascript_plugin_jsdoc = 1

" Configure Airline
let g:airline#extensions#ale#enabled = 1

" Configure ALE
let g:ale_sign_error = '⛔️'
let g:ale_sign_warning = '⚠️ '
let g:ale_echo_msg_error_str = '⛔️'
let g:ale_echo_msg_warning_str = '⚠️ '
let g:ale_echo_msg_format = '[%severity%][%linter%]: %s'
let g:ale_python_auto_virtualenv = 1
let g:ale_fixers = {
\  '*': ['remove_trailing_lines', 'trim_whitespace'],
\  'python': ['black', 'autopep8', 'isort'],
\  'css': ['stylelint', 'css-beautify', 'prettier'],
\  'javascript': ['prettier'],
\  'javascriptreact': ['prettier'],
\  'typescript': ['prettier'],
\  'typescriptreact': ['prettier'],
\}

" Disable pyright linting for python, still uses pyright for nav
let g:ale_linters_ignore = {'python': ['pyright'], 'typescript': ['biome'], 'javascript': ['biome'], 'javascriptreact': ['biome'], 'typescriptreact': ['biome']}

"" ALE - Use quickfix
let g:ale_virtualtext_cursor = 'disabled'
let g:ale_set_loclist = 0
let g:ale_set_quickfix = 1

" Configure Python Folds
autocmd FileType python set foldmethod=indent
autocmd FileType python set foldlevel=99
