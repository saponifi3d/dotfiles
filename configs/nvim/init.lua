-- Neovim 0.11+ Configuration
-- Migrated from vim

-- Set leader key FIRST
vim.g.mapleader = "\\"
vim.g.maplocalleader = "\\"

-- Add Mason bin to PATH so LSP servers are found
vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Load modules
require("options")
require("plugins")
require("keymaps")
require("lsp-config")
require("autocmds")
