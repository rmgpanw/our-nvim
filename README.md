# our-nvim

Portable Neovim IDE configuration for R and Python development on HPC clusters (and anywhere else).

Designed to give a VSCode/Positron-like experience in the terminal, with special consideration for:
- **HPC clusters** (UCL Myriad, etc.) — no root access needed
- **iPad via Termius** — tmux for session persistence, mouse support
- **Vim fallback** — minimal `.vimrc` for servers without Neovim

## Quick Start

```bash
git clone https://github.com/rmgpanw/our-nvim.git ~/.dotfiles
~/.dotfiles/setup.sh
source ~/.bashrc
```

That's it. The setup script will:
1. Install Neovim (AppImage, no root needed)
2. Symlink all configs
3. Add shell integration (PATH, aliases, EDITOR)
4. Install plugins headlessly

## Existing Config Files

The setup script creates symlinks for the following paths:

- `~/.config/nvim` — Neovim configuration
- `~/.config/tmux` and `~/.tmux.conf` — tmux configuration
- `~/.vimrc` — Vim fallback

If any of these already exist as real files (not symlinks), they are **automatically backed up** with a timestamped suffix (e.g. `~/.vimrc.bak.1741470000`) before being replaced. Nothing is silently overwritten.

## What You Get

### Editor Features
- **File explorer** (Neo-tree) — `Space+e`
- **Fuzzy finder** (Telescope) — `Space+ff` files, `Space+fg` grep, `Space+fb` buffers
- **LSP** — go-to-definition, hover docs, diagnostics, rename, code actions
- **Autocompletion** (nvim-cmp) — Tab/Shift-Tab to navigate, Enter to confirm
- **Git integration** — gutter signs, which-key hints
- **Buffer tabs** (bufferline) — `Shift+H/L` to navigate
- **Terminal** — `Ctrl+\` to toggle

### R Development (R.nvim)
- `\rf` — Start R console (uses radian if available)
- `\l` — Send current line to R
- `\ss` — Send selection to R (visual mode)
- `\cc` — Send code chunk (Rmd/Quarto)
- `\aa` — Send entire file
- `\ro` — Object browser
- `\rh` — Help for word under cursor
- `Alt+-` — Insert `<-` (assignment)
- `Alt+m` — Insert `|>` (pipe)
- Quarto/Rmd support via otter.nvim (LSP inside code chunks)

### Python Development
- **pyright** — type checking and LSP
- **ruff** — linting and formatting
- Format on save enabled

### tmux (prefix: `Ctrl+Space`)
- `|` and `-` — split panes
- `Alt+arrows` — navigate panes (no prefix needed)
- `Shift+arrows` — switch windows (no prefix needed)
- Mouse support enabled
- Vi copy mode

## R Packages to Install

For full IDE features, install these in R:

```r
install.packages(c("languageserver", "httpgd"), repos = "https://cloud.r-project.org")
```

For a nicer R console (syntax highlighting, multiline editing):

```bash
pip install radian
```

## On HPC Clusters

Load required modules before starting Neovim:

```bash
module load r python  # adjust names for your cluster
```

Install plugins on the **login node** (which has internet). Compute nodes can then use them offline.

## Vim Fallback

On servers with only Vim, the `.vimrc` provides a reasonable experience with:
- Line numbers, syntax highlighting, mouse support
- Space as leader, familiar keymaps
- R/Python filetype settings
- No plugins required

## Structure

```
our-nvim/
├── setup.sh                          # Bootstrap script
├── nvim/.config/nvim/
│   ├── init.lua                      # Entry point
│   └── lua/plugins/
│       ├── editor.lua                # UI, navigation, git
│       ├── lsp.lua                   # LSP, completion, formatting
│       └── r.lua                     # R.nvim + related
├── tmux/.config/tmux/
│   └── tmux.conf                     # tmux configuration
└── vim/
    └── .vimrc                        # Vim fallback
```

## Customising

- Add plugins: create a new file in `nvim/.config/nvim/lua/plugins/` — lazy.nvim auto-loads it
- Override settings: edit `init.lua` options section
- Add language support: add LSP server to mason-lspconfig `ensure_installed` in `lsp.lua`
