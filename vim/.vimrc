" our-nvim: Minimal vim fallback for servers without Neovim
" Provides a reasonable editing experience with no plugins required

" ── Core ─────────────────────────────────────────────────────────────────────
set nocompatible
filetype plugin indent on
syntax enable

" ── Display ──────────────────────────────────────────────────────────────────
set number
set relativenumber
set cursorline
set showmatch
set laststatus=2
set ruler
set showcmd
set wildmenu
set wildmode=longest:list,full
set scrolloff=10
set signcolumn=yes

" ── Search ───────────────────────────────────────────────────────────────────
set incsearch
set hlsearch
set ignorecase
set smartcase
nnoremap <Esc> :nohlsearch<CR>

" ── Indentation ──────────────────────────────────────────────────────────────
set tabstop=2
set shiftwidth=2
set expandtab
set smartindent
set autoindent

" ── Editing ──────────────────────────────────────────────────────────────────
set backspace=indent,eol,start
set mouse=a
set clipboard=unnamedplus
set hidden
set undofile
set undodir=~/.vim/undodir
set noswapfile

" Create undo directory if it doesn't exist
if !isdirectory(expand("~/.vim/undodir"))
  call mkdir(expand("~/.vim/undodir"), "p")
endif

" ── Splits ───────────────────────────────────────────────────────────────────
set splitright
set splitbelow
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" ── Leader ───────────────────────────────────────────────────────────────────
let mapleader = " "

" Quick buffer switching
nnoremap <S-h> :bprevious<CR>
nnoremap <S-l> :bnext<CR>
nnoremap <leader>bd :bdelete<CR>

" Quick file explorer
nnoremap <leader>e :Explore<CR>

" ── Statusline ───────────────────────────────────────────────────────────────
set statusline=%f\ %m%r%h%w\ %=%y\ [%l/%L,%c]\ %p%%

" ── Filetype-specific ────────────────────────────────────────────────────────
autocmd FileType python setlocal tabstop=4 shiftwidth=4
autocmd FileType r,rmd setlocal tabstop=2 shiftwidth=2
