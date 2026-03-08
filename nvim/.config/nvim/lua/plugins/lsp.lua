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
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },

  -- ── Mason: portable LSP/tool installer ────────────────────────────────
  {
    "mason-org/mason.nvim",
    opts = {},
  },

  -- ── LSP configuration (nvim 0.11+ vim.lsp.config API) ────────────────
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
    },
    config = function()
      -- Capabilities (enhanced with cmp if available)
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
      if ok then
        capabilities = vim.tbl_deep_extend("force", capabilities, cmp_lsp.default_capabilities())
      end

      -- Configure LSP servers using vim.lsp.config (nvim 0.11+)
      vim.lsp.config("pyright", {
        capabilities = capabilities,
      })

      vim.lsp.config("ruff", {
        capabilities = capabilities,
      })

      vim.lsp.config("r_language_server", {
        capabilities = capabilities,
        cmd = { "R", "--no-echo", "-e", "languageserver::run()" },
      })

      vim.lsp.config("lua_ls", {
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

      -- Enable configured servers
      vim.lsp.enable({ "pyright", "ruff", "r_language_server", "lua_ls" })

      -- Mason-lspconfig: auto-install servers
      require("mason-lspconfig").setup({
        ensure_installed = {
          "pyright",
          "ruff",
          "lua_ls",
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
      },
      format_on_save = function(bufnr)
        if vim.api.nvim_buf_line_count(bufnr) > 5000 then return end
        return { timeout_ms = 2000, lsp_format = "fallback" }
      end,
    },
  },
}
