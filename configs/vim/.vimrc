" Custom Mappings
map :W :w
map :Q :q
map :Wq :wq
map :WQ :wq

map :grep :Ag<space>
map :ack :Ag<space>
map :ag :Ag<Space>
map :Vs :vs

map <F2> :NERDTreeToggle<CR>
map <F3> :copen<CR>
map <Leader>g :ALEGoToDefinitionInVSplit<CR>
map <Leader>t :Files<CR>
map <Leader>y :GFiles?<CR>

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

call plug#begin()

Plug 'preservim/nerdtree'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'w0rp/ale'
Plug 'vim-airline/vim-airline'
Plug 'tpope/vim-fugitive'
Plug 'pangloss/vim-javascript'
Plug 'mxw/vim-jsx'
Plug 'prettier/vim-prettier'
Plug 'leafgarland/typescript-vim'
Plug 'peitalin/vim-jsx-typescript'

call plug#end()

filetype plugin indent on

set laststatus=2
let g:javascript_plugin_jsdoc = 1

" TODO Re-enable once i figure out why the highlight colors aren't changing
" vim-jsx-typescript
" autocmd BufNewFile,BufRead *.tsx,*.jsx set filetype=typescript.tsx
"
" " dark red
" hi tsxTagName guifg=#E06C75
"
" " orange
" hi tsxCloseString guifg=#F99575
" hi tsxCloseTag guifg=#F99575
" hi tsxCloseTagName guifg=#F99575
" hi tsxAttributeBraces guifg=#F99575
" hi tsxEqual guifg=#F99575
"
" " yellow
" hi tsxAttrib guifg=#F8BD7F
