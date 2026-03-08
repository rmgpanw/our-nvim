#!/usr/bin/env bash
set -euo pipefail

# our-nvim: portable Neovim IDE setup for R/Python on HPC clusters
# Usage: git clone https://github.com/rmgpanw/our-nvim.git ~/.dotfiles && ~/.dotfiles/setup.sh

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
LOCAL_BIN="$HOME/.local/bin"
NVIM_VERSION="v0.10.3"

info()  { printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
error() { printf '\033[1;31m[ERROR]\033[0m %s\n' "$*"; }

mkdir -p "$LOCAL_BIN"

# ── 1. Install Neovim (AppImage, no root needed) ────────────────────────────
install_neovim() {
    if command -v nvim &>/dev/null; then
        local current
        current="$(nvim --version | head -1)"
        info "Neovim already installed: $current"
        read -rp "Reinstall? [y/N] " ans
        [[ "$ans" =~ ^[Yy]$ ]] || return 0
    fi

    info "Installing Neovim ${NVIM_VERSION}..."
    local appimage="$LOCAL_BIN/nvim.appimage"

    if ! command -v curl &>/dev/null && ! command -v wget &>/dev/null; then
        error "Neither curl nor wget found. Install Neovim manually."
        return 1
    fi

    # AppImage filename changed across versions:
    #   v0.10.x and earlier: nvim.appimage
    #   v0.11.0+: nvim-linux-x86_64.appimage
    local urls=(
        "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-x86_64.appimage"
        "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim.appimage"
    )

    local downloaded=false
    for url in "${urls[@]}"; do
        info "Trying $url..."
        if command -v curl &>/dev/null; then
            if curl -fLo "$appimage" "$url" 2>/dev/null; then
                downloaded=true
                break
            fi
        else
            if wget -O "$appimage" "$url" 2>/dev/null; then
                downloaded=true
                break
            fi
        fi
    done

    if [ "$downloaded" = false ]; then
        error "Failed to download Neovim AppImage. Check your internet connection or download manually."
        return 1
    fi
    chmod u+x "$appimage"

    # Try running as AppImage first; if FUSE unavailable, extract
    if "$appimage" --version &>/dev/null 2>&1; then
        info "AppImage works directly (FUSE available)"
        ln -sf "$appimage" "$LOCAL_BIN/nvim"
    else
        info "FUSE not available, extracting AppImage..."
        cd /tmp
        "$appimage" --appimage-extract &>/dev/null
        mkdir -p "$HOME/.local/share"
        rm -rf "$HOME/.local/share/nvim-appimage"
        mv squashfs-root "$HOME/.local/share/nvim-appimage"
        ln -sf "$HOME/.local/share/nvim-appimage/usr/bin/nvim" "$LOCAL_BIN/nvim"
        rm -f "$appimage"
        cd "$DOTFILES_DIR"
    fi

    info "Neovim installed: $("$LOCAL_BIN/nvim" --version | head -1)"
}

# ── 2. Symlink configs ──────────────────────────────────────────────────────
link_configs() {
    info "Linking configuration files..."

    # Neovim
    mkdir -p "$HOME/.config"
    if [ -e "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
        warn "Backing up existing nvim config to ~/.config/nvim.bak"
        mv "$HOME/.config/nvim" "$HOME/.config/nvim.bak.$(date +%s)"
    fi
    ln -sfn "$DOTFILES_DIR/nvim/.config/nvim" "$HOME/.config/nvim"

    # tmux
    if [ -e "$HOME/.config/tmux" ] && [ ! -L "$HOME/.config/tmux" ]; then
        mv "$HOME/.config/tmux" "$HOME/.config/tmux.bak.$(date +%s)"
    fi
    ln -sfn "$DOTFILES_DIR/tmux/.config/tmux" "$HOME/.config/tmux"
    # Also link to ~/.tmux.conf for older tmux versions
    ln -sf "$DOTFILES_DIR/tmux/.config/tmux/tmux.conf" "$HOME/.tmux.conf"

    # Vim fallback
    if [ -e "$HOME/.vimrc" ] && [ ! -L "$HOME/.vimrc" ]; then
        mv "$HOME/.vimrc" "$HOME/.vimrc.bak.$(date +%s)"
    fi
    ln -sf "$DOTFILES_DIR/vim/.vimrc" "$HOME/.vimrc"

    info "Configs linked."
}

# ── 3. Shell integration ────────────────────────────────────────────────────
setup_shell() {
    local marker="# >>> our-nvim >>>"
    local shell_rc="$HOME/.bashrc"
    [ -n "${ZSH_VERSION:-}" ] && shell_rc="$HOME/.zshrc"

    if grep -q "$marker" "$shell_rc" 2>/dev/null; then
        info "Shell integration already present in $shell_rc"
        return 0
    fi

    info "Adding shell integration to $shell_rc..."
    cat >> "$shell_rc" << 'SHELL_BLOCK'

# >>> our-nvim >>>
export PATH="$HOME/.local/bin:$PATH"
if command -v nvim &>/dev/null; then
    alias vim='nvim'
    alias vi='nvim'
    export EDITOR='nvim'
    export VISUAL='nvim'
else
    export EDITOR='vim'
    export VISUAL='vim'
fi
# <<< our-nvim <<<
SHELL_BLOCK

    info "Shell integration added. Run 'source $shell_rc' or start a new shell."
}

# ── 4. Install Neovim plugins (headless) ─────────────────────────────────────
install_plugins() {
    info "Installing Neovim plugins (this may take a minute)..."
    local nvim_cmd="$LOCAL_BIN/nvim"
    [ ! -x "$nvim_cmd" ] && nvim_cmd="nvim"

    # lazy.nvim bootstraps itself; just open and quit to trigger install
    "$nvim_cmd" --headless "+Lazy! sync" +qa 2>/dev/null || true

    # Install treesitter parsers
    "$nvim_cmd" --headless "+TSInstall r python lua bash markdown markdown_inline yaml json toml" +qa 2>/dev/null || true

    info "Plugins installed."
}

# ── 5. Check R/Python tooling ────────────────────────────────────────────────
check_tooling() {
    info "Checking R/Python tooling..."

    if command -v R &>/dev/null; then
        info "R found: $(R --version | head -1)"
        info "Tip: install R packages for IDE features:"
        info "  R -e \"install.packages(c('languageserver', 'httpgd'), repos='https://cloud.r-project.org')\""
        info "  For radian console: pip install radian"
    else
        warn "R not found. On HPC, try: module load R"
    fi

    if command -v python3 &>/dev/null; then
        info "Python found: $(python3 --version)"
    else
        warn "Python not found. On HPC, try: module load python"
    fi

    if command -v tmux &>/dev/null; then
        info "tmux found: $(tmux -V)"
    else
        warn "tmux not found. Install it or use Neovim's built-in terminal."
    fi
}

# ── Main ─────────────────────────────────────────────────────────────────────
main() {
    info "our-nvim setup starting..."
    info "Dotfiles directory: $DOTFILES_DIR"
    echo

    install_neovim
    echo
    link_configs
    echo
    setup_shell
    echo
    install_plugins
    echo
    check_tooling

    echo
    info "Setup complete!"
    info ""
    info "Quick start:"
    info "  1. source ~/.bashrc"
    info "  2. tmux new -s work"
    info "  3. nvim myfile.R"
    info ""
    info "Key R.nvim bindings (leader = Space):"
    info "  \\rf  - Start R console"
    info "  \\l   - Send current line to R"
    info "  \\ss  - Send selection to R (visual mode)"
    info "  \\cc  - Send code chunk (Rmd/Quarto)"
    info "  \\ro  - Open object browser"
    info "  \\rh  - View help for word under cursor"
}

main "$@"
