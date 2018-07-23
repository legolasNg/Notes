call plug#begin('~/.vim/plugged')

Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

Plug 'tpope/vim-fugitive'
Plug 'gregsexton/gitv'

Plug 'MarcWeber/vim-addon-mw-utils'
Plug 'tomtom/tlib_vim'
Plug 'garbas/vim-snipmate'
Plug 'honza/vim-snippets'

Plug 'majutsushi/tagbar'
Plug 'kien/ctrlp.vim'
Plug 'rking/ag.vim'

Plug 'scrooloose/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'

Plug 'godlygeek/tabular'
Plug 'plasticboy/vim-markdown'

call plug#end()

set nocompatible
" encoding
set encoding=utf-8
set fileencodings=utf-8,gbk,default,latin1
" filetype and syntax
filetype plugin indent on
syntax on

" normal
set number
set ruler
set history=1000
" indent
set autoindent
set smartindent
set tabstop=4
set softtabstop=4
set shiftwidth=4
set expandtab
" search
set hlsearch
set incsearch
set smartcase

" tagBar
nmap <F8> :TagbarToggle<CR>

" nerdTree
map <F4> :NERDTreeToggle<CR>
let NERDTreeWinPos="left"
let NERDTreeIgnore=['\.svn$','\.git$', '\.swp$']
autocmd VimEnter * NERDTree

" ctrlp
let g:ctrlp_map = '<c-p>'
let g:ctrlp_cmd = 'CtrlP'
let g:ctrlp_working_path_mode = 'ra'

" airline
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#formatter = 'default'
