-- Native LSP Configuration for Neovim 0.11+

-- Diagnostic display settings (matches your ALE setup)
vim.diagnostic.config({
  virtual_text = false,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "⛔️",
      [vim.diagnostic.severity.WARN] = "⚠️",
      [vim.diagnostic.severity.HINT] = "💡",
      [vim.diagnostic.severity.INFO] = "ℹ",
    },
  },
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = {
    border = "rounded",
    source = true,
  },
})

-- Capabilities for completion
local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
if ok then
  capabilities = cmp_lsp.default_capabilities(capabilities)
end

-- Configure TypeScript/JavaScript LSP
vim.lsp.config("ts_ls", {
  cmd = { "typescript-language-server", "--stdio" },
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
  capabilities = capabilities,
})

-- Configure Python LSP
vim.lsp.config("pyright", {
  cmd = { "pyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" },
  capabilities = capabilities,
  settings = {
    python = {
      analysis = {
        typeCheckingMode = "off",
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
      },
    },
  },
})

-- Enable servers (only if command exists)
local servers = {
  { name = "ts_ls", cmd = "typescript-language-server" },
  { name = "pyright", cmd = "pyright-langserver" },
}

for _, server in ipairs(servers) do
  if vim.fn.executable(server.cmd) == 1 then
    vim.lsp.enable(server.name)
  end
end

-- LSP Attach - set up keymaps when LSP connects
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    local bufnr = args.buf

    -- Disable ts_ls formatting (use prettier instead)
    if client and client.name == "ts_ls" then
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.documentRangeFormattingProvider = false
    end

    -- Keymaps (buffer-local, only when LSP is attached)
    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
    end

    map("n", "<Leader>d", vim.lsp.buf.definition, "Go to definition")
    map("n", "<Leader>r", vim.lsp.buf.references, "Find references")
    map("n", "<Leader>g", function()
      vim.cmd("vsplit")
      vim.lsp.buf.definition()
    end, "Definition in vsplit")
    map("n", "K", vim.lsp.buf.hover, "Hover docs")
    map("n", "<Leader>rn", vim.lsp.buf.rename, "Rename symbol")
    map("n", "<Leader>ca", vim.lsp.buf.code_action, "Code action")
    map("n", "gd", vim.lsp.buf.definition, "Go to definition")
    map("n", "gr", vim.lsp.buf.references, "Find references")
    map("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
    map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
  end,
})

-- Helper command to check LSP status
vim.api.nvim_create_user_command("LspCheck", function()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    print("No LSP attached. Install servers via :Mason")
    print("  typescript-language-server (JS/TS)")
    print("  pyright (Python)")
  else
    for _, c in ipairs(clients) do
      print("LSP attached: " .. c.name)
    end
  end
end, {})

-- Helper command to send diagnostics to quickfix
vim.api.nvim_create_user_command("DiagnosticsToQf", function()
  vim.diagnostic.setqflist()
end, {})
