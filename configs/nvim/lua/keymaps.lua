-- Keymaps (matching your vimrc workflow)

-- Command typo fixes
vim.cmd([[
  cnoreabbrev W w
  cnoreabbrev Q q
  cnoreabbrev Wq wq
  cnoreabbrev WQ wq
  cnoreabbrev Vs vs
  cnoreabbrev Bd bd
]])

-- Helper function
local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { noremap = true, silent = true, desc = desc })
end

-- ============================================
-- File Explorer (F2 = NERDTree)
-- ============================================
map("n", "<F2>", "<cmd>NvimTreeToggle<CR>", "Toggle file explorer")

-- ============================================
-- Quickfix
-- ============================================
map("n", "<F3>", "<cmd>copen<CR>", "Open quickfix")
map("n", "<Leader>o", "<cmd>copen<CR>", "Open quickfix")
map("n", "<Leader>c", "<cmd>copen<CR>", "Open quickfix")
map("n", "<Leader>q", "<cmd>cclose<CR>", "Close quickfix")

-- ============================================
-- Toggles
-- ============================================
map("n", "<Leader>n", "<cmd>setlocal number!<CR>", "Toggle line numbers")
map("n", "<Leader>S", "<cmd>setlocal spell!<CR>", "Toggle spell check")
map("n", "<Leader>z", "za", "Toggle fold")

-- ============================================
-- Telescope (replaces fzf.vim)
-- ============================================

-- File finder: tries git_files, falls back to find_files
map("n", "<Leader>t", function()
  local builtin = require("telescope.builtin")
  local ok = pcall(builtin.git_files, { show_untracked = true })
  if not ok then
    builtin.find_files()
  end
end, "Find files")

map("n", "<Leader>p", function()
  require("telescope.builtin").find_files()
end, "Find all files")

map("n", "<Leader>y", function()
  require("telescope.builtin").git_status()
end, "Git status")

map("n", "<Leader>k", function()
  require("telescope.builtin").buffers()
end, "List buffers")

map("n", "<Leader>s", function()
  require("telescope.builtin").live_grep()
end, "Search in files (grep)")

-- :Ag command alias
vim.api.nvim_create_user_command("Ag", function(opts)
  require("telescope.builtin").live_grep({ default_text = opts.args })
end, { nargs = "?" })

-- ============================================
-- LSP (set as defaults, overridden in lsp-config.lua when LSP attaches)
-- ============================================
map("n", "<Leader>d", function()
  print("LSP not attached. Run :LspCheck")
end, "Go to definition (needs LSP)")

map("n", "<Leader>r", function()
  print("LSP not attached. Run :LspCheck")
end, "Find references (needs LSP)")

map("n", "<Leader>g", function()
  print("LSP not attached. Run :LspCheck")
end, "Definition in vsplit (needs LSP)")

-- ============================================
-- Formatting
-- ============================================
map("n", "<Leader>f", function()
  require("conform").format({ async = true, lsp_fallback = true })
end, "Format file")

-- ============================================
-- Diagnostics
-- ============================================
map("n", "<Leader>a", function()
  local enabled = vim.diagnostic.is_enabled()
  vim.diagnostic.enable(not enabled)
  print("Diagnostics " .. (enabled and "disabled" or "enabled"))
end, "Toggle diagnostics")

map("n", "[d", vim.diagnostic.goto_prev, "Previous diagnostic")
map("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")
map("n", "<Leader>e", vim.diagnostic.open_float, "Show diagnostic")
map("n", "<Leader>l", vim.diagnostic.setloclist, "Diagnostics to loclist")
