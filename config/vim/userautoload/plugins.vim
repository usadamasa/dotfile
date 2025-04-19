" Start vim-plug
call plug#begin('$XDG_DATA_HOME/vim/plugged')

" Plugins
Plug 'Shougo/deoplete.nvim'
Plug 'vim-scripts/sudo.vim'
Plug 'vim-scripts/pyte'
Plug 'vim-scripts/quickfixstatus.vim'

" powerline
Plug 'davidhalter/jedi-vim'
Plug 'tpope/vim-fugitive'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" key-assist
Plug 'Shougo/neocomplcache'
Plug 'Townk/vim-autoclose'
Plug 'h1mesuke/vim-alignta'

" go
Plug 'fatih/vim-go'

" syntax
Plug 'elzr/vim-json'

" misc
Plug 'mechatroner/rainbow_csv'

call plug#end()
" End vim-plug