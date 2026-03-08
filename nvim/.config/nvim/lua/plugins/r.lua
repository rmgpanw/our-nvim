-- R development: R.nvim + related plugins

return {
  -- ── R.nvim (send code to R, object browser, help, Rmd/Quarto) ──────────
  {
    "R-nvim/R.nvim",
    ft = { "r", "rmd", "quarto", "rnoweb", "rhelp", "rdoc" },
    config = function()
      local opts = {
        -- Use tmux for R console if available, otherwise built-in terminal
        -- R.nvim auto-detects tmux; when inside tmux it uses a tmux split
        R_args = { "--quiet", "--no-save" },

        -- Use radian if available (nicer R console with syntax highlighting)
        -- Set to just "R" if radian is not installed
        R_app = vim.fn.executable("radian") == 1 and "radian" or "R",
        R_cmd = "R", -- always use R for behind-the-scenes commands

        hook = {
          on_filetype = function()
            -- R-specific keymaps are set by R.nvim using localleader (\)
            -- Common ones:
            --   \rf  Start R
            --   \rq  Quit R
            --   \l   Send line
            --   \ss  Send selection
            --   \cc  Send chunk
            --   \aa  Send entire file
            --   \ro  Object browser
            --   \rh  Help on word
            --   \rv  View data (head)

            vim.keymap.set("n", "<leader>rs", "<Plug>RStart", { buffer = true, desc = "Start R" })
            vim.keymap.set("n", "<leader>rq", "<Plug>RClose", { buffer = true, desc = "Quit R" })
          end,
        },

        -- Minimum width for the R console pane
        min_editor_width = 72,
        rconsole_width = 0, -- 0 = split below; positive = split right with N columns

        -- Object browser
        objbr_place = "console,below",
        objbr_opendf = true,

        -- Assignment operator
        assignment_keymap = "<M-->", -- Alt+- like RStudio

        -- Pipe operator
        pipe_keymap = "<M-m>", -- Alt+m inserts |>
        pipe_version = "native", -- use |> not %>%
      }
      require("r").setup(opts)
    end,
  },

  -- ── otter.nvim: LSP in embedded code chunks (Quarto/Rmd) ──────────────
  {
    "jmbuhr/otter.nvim",
    ft = { "quarto", "rmd", "markdown" },
    dependencies = { "neovim/nvim-lspconfig" },
    opts = {},
  },
}
