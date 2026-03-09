-- Optional RStudio-like keybindings
-- Delete this file or rename to .lua.disabled to disable

-- NOTE: Some RStudio shortcuts use Ctrl/Alt combos that may not work
-- in all terminal emulators (especially on iPad). These are best-effort.

return {
  {
    "R-nvim/R.nvim",
    keys = {
      -- ── RStudio-style keybindings ─────────────────────────────────────
      -- Ctrl+Enter: send current line/selection to R (like RStudio)
      { "<C-CR>", "<Plug>RSendLine", ft = { "r", "rmd", "quarto" }, desc = "Send line to R" },
      { "<C-CR>", "<Plug>RSendSelection", ft = { "r", "rmd", "quarto" }, mode = "v", desc = "Send selection to R" },

      -- Ctrl+Shift+Enter: send entire chunk (Rmd/Quarto) or file (R)
      { "<C-S-CR>", "<Plug>RSendChunk", ft = { "rmd", "quarto" }, desc = "Send chunk to R" },
      { "<C-S-CR>", "<Plug>RSendFile", ft = { "r" }, desc = "Send file to R" },

      -- Ctrl+Shift+M: pipe operator (RStudio default)
      { "<C-S-m>", function() vim.api.nvim_put({ " |> " }, "c", true, true) end, ft = { "r", "rmd", "quarto" }, mode = "i", desc = "Insert |>" },
    },
  },

  -- ── General RStudio-like keybindings (work in all file types) ─────────
  {
    dir = ".",
    name = "rstudio-general-keys",
    lazy = false,
    config = function()
      -- Ctrl+S: save file
      vim.keymap.set({ "n", "i" }, "<C-s>", "<cmd>w<CR>", { desc = "Save file" })

      -- Ctrl+Shift+F: search in files (like RStudio's Find in Files)
      vim.keymap.set("n", "<C-S-f>", function()
        require("telescope.builtin").live_grep()
      end, { desc = "Search in files" })

      -- Ctrl+P: command palette / find files
      vim.keymap.set("n", "<C-p>", function()
        require("telescope.builtin").find_files()
      end, { desc = "Find files" })

      -- Ctrl+Shift+P: command palette
      vim.keymap.set("n", "<C-S-p>", function()
        require("telescope.builtin").commands()
      end, { desc = "Command palette" })

      -- Alt+-: assignment operator <- (already set in R.nvim config, this adds it globally for R files)
      -- Alt+m: pipe |> (already set in R.nvim config)
    end,
  },
}
