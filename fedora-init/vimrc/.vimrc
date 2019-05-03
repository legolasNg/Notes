call plug#begin('~/.vim/plugged')

Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'yggdroot/indentline'

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
Plug 'mbbill/undotree'

Plug 'valloric/youcompleteme'
Plug 'rdnetto/YCM-Generator', { 'branch': 'stable'}

Plug 'airblade/vim-gitgutter'
Plug 'scrooloose/nerdcommenter'
Plug 'scrooloose/syntastic'
Plug 'easymotion/vim-easymotion'

Plug 'morhetz/gruvbox'
Plug 'tomasr/molokai'
Plug 'cocopon/iceberg.vim'
Plug 'altercation/vim-colors-solarized'

call plug#end()

set nocompatible
" encoding
set encoding=utf-8
set fileencodings=utf-8,gbk,default,latin1
" filetype and syntax
filetype plugin indent on
syntax on

" theme
set background=dark
colorscheme gruvbox

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

" undotree
nnoremap <F5> :UndotreeToggle<CR>

" nerdTree
map <F4> :NERDTreeToggle<CR>
let NERDTreeWinPos="left"
let NERDTreeIgnore=['\.svn$','\.git$', '\.swp$']
autocmd VimEnter * NERDTree
autocmd VimEnter * NERDTree
wincmd w
autocmd VimEnter * wincmd w

" ctrlp
let g:ctrlp_map = '<c-p>'
let g:ctrlp_cmd = 'CtrlP'
let g:ctrlp_working_path_mode = 'ra'

" airline
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#formatter = 'default'

" YCM
let g:ycm_global_ycm_extra_conf = '/home/legolas/.vim/plugged/youcompleteme/third_party/ycmd/.ycm_extra_conf.py'

" comment
" Add spaces after comment delimiters by default
let g:NERDSpaceDelims = 1
" Use compact syntax for prettified multi-line comments
let g:NERDCompactSexyComs = 1
" Align line-wise comment delimiters flush left instead of following code indentation
let g:NERDDefaultAlign = 'left'
" Set a language to use its alternate delimiters by default
let g:NERDAltDelims_java = 1
" Add your own custom formats or override the defaults
let g:NERDCustomDelimiters = { 'c': { 'left': '/**','right': '*/' } }
" Allow commenting and inverting empty lines (useful when commenting a region)
let g:NERDCommentEmptyLines = 1
" Enable trimming of trailing whitespace when uncommenting
let g:NERDTrimTrailingWhitespace = 1
" Enable NERDCommenterToggle to check all selected lines is commented or not 
let g:NERDToggleCheckAllLines = 1

" indent
let g:indentLine_enabled = 1
let g:indentLine_char = '┆'
