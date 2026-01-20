-- Plugin specifications for lazy.nvim

require("lazy").setup({
  -- ============================================
  -- Treesitter
  -- ============================================
  -- {
  --   "nvim-treesitter/nvim-treesitter",
  --   build = ":TSUpdate",
  --   config = function()
  --     local ok, configs = pcall(require, "nvim-treesitter.configs")
  --     if ok then
  --       configs.setup({
  --         ensure_installed = {
  --           "javascript", "typescript", "tsx", "python",
  --           "html", "css", "json", "yaml", "markdown",
  --           "lua", "vim", "vimdoc", "bash",
  --         },
  --         sync_install = false,
  --         auto_install = true,
  --         highlight = { enable = true },
  --         indent = { enable = true },
  --       })
  --     end
  --   end,
  -- },


  -- ============================================
  --- Tokyo Night
  -- ============================================
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    style="night",
    on_colors = function(colors)
      colors.hint = colors.orange
      colors.error = "#ff0000"
    end
  },

  -- ============================================
  -- Mason
  -- ============================================
  {
    "williamboman/mason.nvim",
    lazy = false,
    config = function()
      require("mason").setup({
        ui = {
          icons = {
            package_installed = "[+]",
            package_pending = "[~]",
            package_uninstalled = "[-]",
          },
        },
      })
    end,
  },

  -- ============================================
  -- Formatting
  -- ============================================
  {
    "stevearc/conform.nvim",
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          ["_"] = { "trim_whitespace", "trim_newlines" },
          python = { "black", "isort" },
          javascript = { "prettier" },
          javascriptreact = { "prettier" },
          typescript = { "prettier" },
          typescriptreact = { "prettier" },
          css = { "prettier" },
          json = { "prettier" },
          yaml = { "prettier" },
          markdown = { "prettier" },
        },
        format_on_save = false,
      })
    end,
  },

  -- ============================================
  -- Linting
  -- ============================================
  {
    "mfussenegger/nvim-lint",
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = {}

      -- Only add linters if they exist
      if vim.fn.executable("ruff") == 1 then
        lint.linters_by_ft.python = { "ruff" }
      end
      if vim.fn.executable("eslint_d") == 1 then
        lint.linters_by_ft.javascript = { "eslint_d" }
        lint.linters_by_ft.javascriptreact = { "eslint_d" }
        lint.linters_by_ft.typescript = { "eslint_d" }
        lint.linters_by_ft.typescriptreact = { "eslint_d" }
      elseif vim.fn.executable("eslint") == 1 then
        lint.linters_by_ft.javascript = { "eslint" }
        lint.linters_by_ft.javascriptreact = { "eslint" }
        lint.linters_by_ft.typescript = { "eslint" }
        lint.linters_by_ft.typescriptreact = { "eslint" }
      end

      vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
        callback = function()
          if lint.linters_by_ft[vim.bo.filetype] then
            lint.try_lint()
          end
        end,
      })
    end,
  },

  -- ============================================
  -- Completion
  -- ============================================
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
        }, {
          { name = "buffer" },
          { name = "path" },
        }),
      })
    end,
  },

  -- ============================================
  -- File Explorer
  -- ============================================
  {
    "nvim-tree/nvim-tree.lua",
    lazy = false,
    config = function()
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1

      require("nvim-tree").setup({
        view = { width = 35 },
        filters = { dotfiles = false },
        git = { enable = true, ignore = false },
        renderer = {
          icons = {
            show = {
              file = false,
              folder = false,
              folder_arrow = true,
              git = true,
            },
            glyphs = {
              folder = {
                arrow_closed = ">",
                arrow_open = "v",
              },
              git = {
                unstaged = "M",
                staged = "S",
                unmerged = "U",
                renamed = "R",
                untracked = "?",
                deleted = "D",
                ignored = "I",
              },
            },
          },
        },
      })
    end,
  },

  -- ============================================
  -- Telescope
  -- ============================================
  {
    "nvim-telescope/telescope.nvim",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
  },

  -- ============================================
  -- Status Line (replaces vim-airline)
  -- ============================================
  {
    "nvim-lualine/lualine.nvim",
    lazy = false,
    config = function()
      require("lualine").setup({
        options = {
          icons_enabled = false,
          theme = "tokyonight",
          component_separators = { left = "|", right = "|" },
          section_separators = { left = "", right = "" },
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch", "diff", "diagnostics" },
          lualine_c = { { "filename", path = 1 } },
          lualine_x = { "encoding", "fileformat", "filetype" },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        },
      })
    end,
  },

  -- ============================================
  -- Git
  -- ============================================
  {
    "tpope/vim-fugitive",
    cmd = { "Git", "Gstatus", "Gblame", "Gpush", "Gpull" },
  },
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        signs = {
          add = { text = "+" },
          change = { text = "~" },
          delete = { text = "_" },
          topdelete = { text = "-" },
          changedelete = { text = "~" },
        },
      })
    end,
  },

  -- ============================================
  -- Utilities
  -- ============================================
  {
    "michaeljsmith/vim-indent-object",
    ft = { "python" },
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      require("which-key").setup({ delay = 500 })
    end,
  },
}, {
  checker = { enabled = false },
  change_detection = { notify = false },
})
