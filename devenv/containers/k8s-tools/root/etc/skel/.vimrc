"######################################################
" Name: .vimrc
" Description: Custom vim configuration settings
" NOTES:
"       :scriptnames is useful for debugging :)
"######################################################

"######################################################

" 1. Load Plugins
"source ~/.vim/rc/plugins.vim

" 2. Load Functions
"source ~/.vim/rc/functions.vim

" 3. Load Auto commands
"source ~/.vim/rc/autocmds.vim

" 4. Load remap
"source ~/.vim/rc/remap.vim

" 5. Load Color Schemes
"source ~/.vim/rc/colors.vim

" 6. Load Rust tweaks
"source ~/.vim/rc/rust.vim

"######################################################

" I have no idea what this means but fixes weird terminal issue.
let &t_TI = ""
let &t_TE = ""

set encoding=utf-8                              " Encoding
let mapleader = " "                             " Leader
set backspace=2                                 " Backspace deletes like most programs in insert mode
"set history=100                                 " Set the number of commands to store in the history
set ruler                                       " show the cursor position all the time
set showcmd                                     " display incomplete commands
set incsearch                                   " do incremental searching
set laststatus=2                                " Always display the status line
set autowrite                                   " Automatically :write before running commands
"set modelines=0                                 " Disable modelines as a security precaution
"set nomodeline                                  " Disable reading and processing modelines

" Secure defaults
set noswapfile                                  " Disable the swapfile
set nobackup                                    " Disable creation of vim backup files
set nowritebackup                               " Don't write to existing backup files
set viminfo=                                    " Disable vimingo file from copying from current session
set clipboard=                                  " Disable copying to system clipboard

if !exists("g:syntax_on")
syntax enable
filetype on
endif

filetype plugin on
filetype indent on

set guifont=Monospace\ 12                       " set the font family and size
"set number                                      " show line numbers
"set mouse=a                                     " enable mouse usage
"set mousehide                                   " hide the mouse cursor when typing
"set spell                                       " Enable spell check
set nospell                                     " Disable spell check
set backspace=indent,eol,start                  " Backspace for dummies
set linespace=0                                 " No extra spaces between rows
set showmatch                                   " Show matching brackets/parenthesis
set incsearch                                   " Find as you type search
set hlsearch                                    " Highlight search terms
set winminheight=0                              " Windows can be 0 line high
"set ignorecase                                  " Case insensitive search
"set smartcase                                   " Case sensitive when uc present
set wildmenu                                    " Show list instead of just completing
set wildmode=list:longest,full                  " Command <Tab> completion, list matches, then longest common part, then all.
set whichwrap=b,s,h,l,<,>,[,]                   " Backspace and cursor keys wrap too
set scrolljump=5                                " Lines to scroll when cursor leaves screen
set scrolloff=3                                 " Minimum lines to keep above and below cursor
set foldenable                                  " Auto fold code
set list                                        " Enable list
"set listchars=eol:$,tab:>>,trail:-,extends:>,precedes:<,nbsp:+ " Show problematic whitespace
set listchars=tab:>>,trail:-,extends:>,precedes:<,nbsp:+ " Show problematic whitespace
set nowrap                                      " Don't automatically wrap long lines
set wrap!                                       " Really, don't automatically wrap long lines
set autoindent                                  " Indent at the same level of the previous line
"set shiftwidth=4                                " Use indents of 4 spaces
"set expandtab                                   " Tabs are spaces, not tabs
"set tabstop=4                                   " An indentation every four columns
set softtabstop=4                               " Let backspace delete entire indent
set nojoinspaces                                " Prevents inserting two spaces after punctuation on a join (J)
set splitright                                  " Puts new vertical split windows to the right of the current
set splitbelow                                  " Puts new horizontal split windows below the current
set pastetoggle=<F12>                           " paste toggle sets sane indentation on paste when using the shortcut
set timeoutlen=1000                             " Sets the timeout for mapping delays
set ttimeoutlen=0                               " Set the timeout for key code delays
