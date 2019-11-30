" Start dein.vim
if &compatible
  set nocompatible
endif
set runtimepath+=~/.cache/dein/repos/github.com/Shougo/dein.vim

if dein#load_state('~/.cache/dein')
    call dein#begin('~/.cache/dein')

    call dein#add('Shougo/deoplete.nvim')

    " dein.vim
    " dein自体もdein.vimで管理する
    call dein#add('Shougo/dein.vim')

    call dein#add('vim-scripts/sudo.vim')
    call dein#add('vim-scripts/pyte')
    call dein#add('vim-scripts/quickfixstatus.vim')

    " powerline
    call dein#add('davidhalter/jedi-vim')
    call dein#add('taichouchou2/alpaca_powertabline')
    call dein#add('vim-airline/vim-airline')
    call dein#add('vim-airline/vim-airline-themes')

    " key-assist
    call dein#add('Shougo/neocomplcache')
    call dein#add('Townk/vim-autoclose')
    call dein#add('h1mesuke/vim-alignta')

    " go
    call dein#add('fatih/vim-go')

    " syntax
    call dein#add('elzr/vim-json')

    " misc
    call dein#add('mechatroner/rainbow_csv')

    " 終わり
    call dein#end()
    call dein#save_state()
endif

filetype plugin indent on

" 未インストールのプラグインがあったらインストールする
if dein#check_install()
  call dein#install()
endif
" End dein.vim

