-- LSP, completion, and formatting

return {
  -- ── Treesitter (syntax highlighting, text objects) ──────────────────────
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "r", "python", "lua", "bash", "markdown", "markdown_inline",
          "yaml", "json", "toml", "html", "css", "vim", "vimdoc", "query",
        },
        auto_install = false, -- set true if you have internet
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },

  -- ── LSP configuration ──────────────────────────────────────────────────
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      -- Mason: portable LSP/tool installer
      { "mason-org/mason.nvim", opts = {} },
      "mason-org/mason-lspconfig.nvim",
    },
    config = function()
      -- Servers to auto-install via mason (R languageserver is installed via R itself)
      require("mason-lspconfig").setup({
        ensure_installed = {
          "pyright",    -- Python type checker
          "ruff",       -- Python linter/formatter
          "lua_ls",     -- Lua (for editing nvim config)
        },
      })

      local lspconfig = require("lspconfig")
      local capabilities = vim.lsp.protocol.make_client_capabilities()

      -- Try to enhance capabilities with cmp if available
      local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
      if ok then
        capabilities = vim.tbl_deep_extend("force", capabilities, cmp_lsp.default_capabilities())
      end

      -- Python
      lspconfig.pyright.setup({ capabilities = capabilities })
      lspconfig.ruff.setup({ capabilities = capabilities })

      -- R (requires: install.packages("languageserver") in R)
      lspconfig.r_language_server.setup({
        capabilities = capabilities,
        -- Use the R on PATH (works with module system)
        cmd = { "R", "--no-echo", "-e", "languageserver::run()" },
      })

      -- Lua (for editing neovim config)
      lspconfig.lua_ls.setup({
        capabilities = capabilities,
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            workspace = {
              checkThirdParty = false,
              library = { vim.env.VIMRUNTIME },
            },
          },
        },
      })

      -- ── LSP keymaps (active when LSP attaches) ───────────────────────
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
          end
          map("gd", vim.lsp.buf.definition, "Go to definition")
          map("gr", vim.lsp.buf.references, "References")
          map("gI", vim.lsp.buf.implementation, "Go to implementation")
          map("K", vim.lsp.buf.hover, "Hover documentation")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action")
          map("<leader>cr", vim.lsp.buf.rename, "Rename symbol")
          map("<leader>cd", vim.diagnostic.open_float, "Line diagnostics")
          map("[d", vim.diagnostic.goto_prev, "Prev diagnostic")
          map("]d", vim.diagnostic.goto_next, "Next diagnostic")
        end,
      })
    end,
  },

  -- ── Autocompletion ──────────────────────────────────────────────────────
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      require("luasnip.loaders.from_vscode").lazy_load()

      cmp.setup({
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<C-d>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = {
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
          -- R.nvim adds its own cmp source automatically
        },
      })
    end,
  },

  -- ── Formatting ──────────────────────────────────────────────────────────
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    keys = {
      { "<leader>cf", function() require("conform").format({ async = true }) end, desc = "Format buffer" },
    },
    opts = {
      formatters_by_ft = {
        python = { "ruff_format" },
        lua = { "stylua" },
        -- R formatting: use styler via conform or format on save via LSP
      },
      format_on_save = function(bufnr)
        -- Disable for large files
        if vim.api.nvim_buf_line_count(bufnr) > 5000 then return end
        return { timeout_ms = 2000, lsp_format = "fallback" }
      end,
    },
  },
}
