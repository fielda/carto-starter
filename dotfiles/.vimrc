if &compatible " if not already set
    " Use Vim defaults (easier, more user friendly than vi defaults).
    " This must be first because it changes other options as a side effect.
    set nocompatible
endif

" It's OK to have an unwritten buffer that's no longer visible.
" See http://usevim.com/2012/10/19/vim101-set-hidden/
" Vim keeps us safe from quitting altogether while having unwritten buffers,
" so there's no chance of accidentally losing data.
" Reminders:
"   1. Edit multiple buffers using :bufdo
"   2. Use :wa to write all
set hidden

" Remove ALL autocommands to prevent them from being loaded twice.
if has('autocmd')
    autocmd!
endif

if has('syntax')
    syntax on " of course
endif

" Set Vim-specific sequences for RGB 24-bit colors.
" This works in xterm when $TERM is 'xterm-256color'
" let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
" let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
" set termguicolors

set t_Co=256                   " tell Vim that the terminal supports 256 colors
set vb                         " visual beep, no audible beep
set cursorline                 " highlight current line
set showmatch                  " briefly jump to the matching brace when you insert one
set incsearch                  " search as characters are typed
set ignorecase                 " ignore case when searching
set smartcase                  " ignore case if search pattern is all lowercase
set hlsearch                   " highlight matches
set nowrap                     " wrapping is ugly, off by default
set linebreak                  " but if you switch to wrapping, try not to wrap in the middle of words
set ruler                      " show line number, row/column, or whatever is defined by rulerformat
set title                      " show xterm title, does nothing in GVim
set backspace=indent,eol,start " allow the backspace key to erase previously entered text, autoindent, and newlines
set autoindent                 " autocopy the indentation from the previous line
set nrformats=hex              " because I literally never deal with octal, incrementing 06 (CTRL-A) should result in 07
set foldcolumn=1               " add some left margin
set encoding=utf8              " the Vim default is Latin-1, yikes! see http://unix.stackexchange.com/a/23414
set history=500                " keep a longer history, 20 is the default
set scrolloff=3                " start scrolling a few lines before the border (more context around the cursor)
set sidescrolloff=3            " don't scroll any closer to the left or right
set laststatus=2               " always show the status line
set autoread                   " auto reload files changed outside of Vim
set synmaxcol=600              " limit syntax highlighing
set number                     " show line numbers
set showcmd                    " show the current command hence the leader key for as long as it is active

" Open new split panes to the right and bottom, which feels more natural.
set splitbelow
set splitright

" Time out on mapping after 2 seconds, time out on key codes after 100ms.
" See ':help timeoutlen' and tpope/sensible-vim
set timeout timeoutlen=2000 ttimeoutlen=100

if has('spell') " spell checking was added in Vim 7
    set spelllang=en_us
    set spellsuggest=best,10 " show only the top 10
    if has('autocmd')
        " turn on by default for files < 20K
        autocmd Filetype * if getfsize(@%) < 20480 | set spell | endif
    endif
endif

" Show special characters.
if v:version >= 700
    set list listchars=tab:»-,trail:·,extends:→
endif

" These line wrap settings look better if number or relativenumber are on.
set cpoptions+=n     " start line wrapping in the line-number area.
set showbreak=-->\ | " keep a space between \ and |

set background=dark " this only tells Vim what the terminal's background color looks like

" Command line completion, try it with ':color <Tab>'.
set wildmenu
" Complete till the longest common string and start wildmenu, subsequent tabs cycle the menu options.
set wildmode=longest:full,full
" Ignore various binary/compiled/transient files.
set wildignore=*.o,*.obj,*~,*.py[cod],*.swp
set wildignore+=*.exe,*.msi,*.dll,*.pdb
set wildignore+=*.png,*.jpg,*.jpeg,*.gif,*.pdf,*.zip,*.7z

if exists('+undofile')
    set undolevels=500   " muchos levels of undo
    set undoreload=10000 " max lines to save for undo on a buffer reload
    set undofile
endif

" Expand tabs to spaces by default.
setlocal expandtab
setlocal shiftwidth=4
setlocal softtabstop=4
setlocal tabstop=4

" We default to LF line endings for new files.
" http://vim.wikia.com/wiki/Change_end-of-line_format_for_dos-mac-unix
" This will not change the format of existing files, use dos2unix for that.
set fileformat=unix
set fileformats=unix,dos

" Better line jumping with wrapped lines.
" See https://www.reddit.com/r/vim/comments/2k4cbr/problem_with_gj_and_gk/
nnoremap <expr> k (v:count == 0 ? 'gk' : 'k')
nnoremap <expr> j (v:count == 0 ? 'gj' : 'j')

if v:version >= 704 && has('patch235')
    " ; gets stuck on a t command, but this was fixed in 7.3.235
    " Make sure we allow the fix (don't use compatibility mode for ;)
    " http://stackoverflow.com/a/15669344
    set cpo-=;
endif

" In insert mode, pressing Ctrl-u deletes text you've typed in t
" current line, and Ctrl-w deletes the word before the cursor.
" You can't undo these deletions! Fix that.
inoremap <c-u> <c-g>u<c-u>
inoremap <c-w> <c-g>u<c-w>

" Make <space> in normal mode add a space.
nnoremap <space> i<space><esc>l

" Never engage Ex mode (make Q harmless).
" http://www.bestofvim.com/tip/leave-ex-mode-good/
nnoremap Q <nop>

" <Esc> is so so far away, use this `jj` home row sequence instead.
" Note that comments cannot go after the inoremap (insert no recursion map) sequence
" else they become part of it, thus these comments are above the command itself.
inoremap jj <esc>

" nopaste is the default but we set it here explicitly as a reminder that
" setting the 'paste' option will disable other options like inoremap, see :help 'paste'
set nopaste

" Build our custom status line.
set statusline=
set statusline+=%-3.3n\        " buffer number
set statusline+=%f\            " filename
set statusline+=%h%m%r%w       " status flags
set statusline+=\[%{strlen(&ft)?&ft:'none'}, " file type
set statusline+=%{strlen(&fenc)?&fenc:&enc}, " encoding
set statusline+=%{&fileformat}]              " file format
set statusline+=%=              " right align the remainder
set statusline+=%-14(%l,%c%V%)  " line, character
set statusline+=%<%P            " file position
set statusline+=\ \             " spacer
set statusline+=%#error#               " switch to error highlighting
set statusline+=%{&paste?'[paste]':''} " warn if &paste is set
set statusline+=%*                     " return to normal highlighting

" Potential lag fix, https://redd.it/1p0e46
let g:matchparen_insert_timeout=5

" We wrap the N n mappings in a function to call it on VimEnter.
" Something is overwriting them if we don't.
function! Nn()
    " Keep search matches in the middle of the window:
    " zz scrolls the cursor to center
    " zv opens just enough folds to make that line not folded
    " nnoremap n nzzzv
    " nnoremap N Nzzzv

    " This rewires n and N to do some fancy highlighting.
    " h/t https://github.com/greg0ire/more-instantly-better-vim
    nnoremap <silent> n nzzzv:call HighlightPosition(0.2)<cr>
    nnoremap <silent> N Nzzzv:call HighlightPosition(0.2)<cr>
endfunction

if has('autocmd')
    augroup nn_setup
        " Clear the autocmds of the current group to prevent them from piling
        " up each time we reload vimrc.
        autocmd!
        autocmd VimEnter * call Nn()
    augroup END
endif

" Keep this last.
set secure
