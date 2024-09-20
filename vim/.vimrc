set nocompatible

let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin()
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rhubarb'
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-sleuth'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'fxn/vim-monochrome'
Plug 'itchyny/lightline.vim'
Plug 'mbbill/undotree'
Plug 'junegunn/goyo.vim'
Plug 'wellle/context.vim'
Plug 'junegunn/fzf.vim'
call plug#end()

let mapleader = " "

filetype plugin on
filetype indent on
syntax enable

" Disable bell sound" 
set visualbell
set noerrorbells
set t_vb=
set tm=500

" Linebreak on 500 characters
set lbr
set tw=500
set ai " Auto indent
set si " Smart indent
set wrap " Wrap lines
set ruler " Cursor position

" Behaviour
set history=1000                " remember more commands and search history
set undolevels=1000             " use many muchos levels of undo
if v:version >= 730
    set undofile                " keep a persistent backup file
    set undodir=~/.vim/.undo,~/tmp,/tmp
endif
set nobackup                    " do not keep backup files, it's 70's style cluttering
set noswapfile                  " do not write annoying intermediate swap files,
                                "    who did ever restore from swap files anyway?
set directory=~/.vim/.tmp,~/tmp,/tmp
                                " store swap files in one of these directories
                                "    (in case swapfile is ever turned on)
set viminfo='20,\"80            " read/write a .viminfo file, don't store more
                                "    than 80 lines of registers
set wildmenu                    " make tab completion for files/buffers act like bash
set wildmode=list:full          " show a list when pressing tab and complete
                                "    first full match

set number relativenumber
set autoread " Read file when changed externally
set tabstop=4
set softtabstop=4
set shiftwidth=4
set smarttab
set expandtab!
set scrolloff=8
set cursorline
set smartcase
set hlsearch
set incsearch
set magic
set showmatch " Set show matching parenthesis
set breakindent
set mouse=a " Enable mouse mode
" change cursor to line when inser
let &t_SI = "\e[6 q"
let &t_EI = "\e[2 q"

" Configure backspace so it acts as it should act
set backspace=eol,start,indent
set whichwrap+=<,>,h,l

" sync clipboard between os and neovim.
set clipboard=unnamedplus

" set completeopt to have a better completion experience
set completeopt=menuone,noselect

" editor layout
try
  colorscheme retrobox
catch
  colorscheme slate
endtry
set background=dark
let g:lightline = {
      \ 'colorscheme': 'nord',
      \ }
" set termguicolors
" set signcolumn=yes
" set foldcolumn=1 " Add a bit extra margin to the left
" set showmode " Always show what mode we're currently editing in

set termencoding=utf-8
set encoding=utf-8
set lazyredraw                  " don't update the display while executing macros
set laststatus=2                " tell VIM to always put a status line in, even
                                "    if there is only one window
set cmdheight=1                 " use a status bar that is 1 rows high
set noshowmode " accommodated by lightline

" white space characters
set nolist
set listchars=eol:$,tab:.\ ,trail:.,extends:>,precedes:<,nbsp:_
highlight SpecialKey term=standout ctermfg=darkgray guifg=darkgray
" display white space characters with F3
nnoremap <F3> :set list! list?<CR>

" move blocks
vnoremap J :m'>+<CR>gv=gv
vnoremap K :m-2<CR>gv=gv
" keymap to add new line without entering insert mode
nmap <leader>o o<Esc>0\"_D
nmap <leader>O O<Esc>0\"_D
" better join lines
nmap J mzJ`z'
" centred page scroll
nmap <C-d> <C-d>zz 
nmap <C-u> <C-u>zz 
" centred search result
nmap n nzzzv
nmap N Nzzzv
" paster without buffer replace
vnoremap <leader>p "_dP
" plugin keys
function! SwapTheme()
  if g:colors_name == 'quiet'
    try
      colorscheme retrobox
    catch
      colorscheme slate
    endtry
    set background=dark
  else
    colorscheme quiet
    set background=light
  endif
endfunction

nmap <leader><Home> <Cmd>Goyo<cr>
nmap <leader><End> <Cmd>call SwapTheme()<cr>
nnoremap <leader>F <Cmd>UndotreeToggle<cr>

" === Goyo
" changing from the default 80 to accomodate for UndoTree panel
let g:goyo_width = 104
function! s:goyo_enter()
  set number relativenumber
endfunction

function! s:goyo_leave()
endfunction

autocmd! User GoyoEnter nested call <SID>goyo_enter()
autocmd! User GoyoLeave nested call <SID>goyo_leave()

" === UndoTree
" using relative positioning instead
let g:undotree_CustomUndotreeCmd='vertical 32 new'
let g:undotree_CustomDiffpanelCmd='belowright 12 new'
" let g:undotree_WindowLayout=3
" let g:undotree_ShortIndicators=1

autocmd vimenter * Goyo 
autocmd vimenter * UndotreeToggle 
