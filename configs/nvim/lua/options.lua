-- General Settings (matching your vimrc)

-- Colorscheme
vim.cmd("colorscheme default")

-- Display
vim.opt.scrolloff = 5
vim.opt.number = true
vim.opt.showmatch = true
vim.opt.ruler = true
vim.opt.title = true
vim.opt.laststatus = 2
vim.opt.signcolumn = "yes"
vim.opt.termguicolors = true

-- Indentation
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.expandtab = true

-- Search
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Splits
vim.opt.splitright = true

-- Encoding
vim.opt.encoding = "utf-8"

-- Backspace
vim.opt.backspace = "indent,eol,start"

-- Auto-reload
vim.opt.autoread = true

-- Spell
vim.opt.spelllang = "en_us"
vim.opt.spelloptions = "camel"

-- Word boundaries
vim.opt.iskeyword:append("_")

-- Syntax
vim.cmd("syntax on")
vim.cmd("filetype plugin indent on")
