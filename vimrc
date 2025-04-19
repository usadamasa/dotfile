:let $VIMFILE_DIR = '.vim'

let $CACHE = expand('~/.cache')
if !($CACHE->isdirectory())
  call mkdir($CACHE, 'p')
endif
if &runtimepath !~# '/dein.vim'
  let s:dir = 'dein.vim'->fnamemodify(':p')
  if !(s:dir->isdirectory())
    let s:dir = $CACHE .. '/dein/repos/github.com/Shougo/dein.vim'
    if !(s:dir->isdirectory())
      execute '!git clone https://github.com/Shougo/dein.vim' s:dir
    endif
  endif
  execute 'set runtimepath^='
        \ .. s:dir->fnamemodify(':p')->substitute('[/\\]$', '', '')
endif

" 自動的にファイルを読み込むパスを設定 ~/$VIMFILE_DIR/userautoload/*.vim
set runtimepath+=~/$VIMFILE_DIR/
runtime! userautoload/*.vim

" -------------------------------------------
" 以下プラグイン向けの設定
" -------------------------------------------

" -------------------------------------------
" Powerline向けフォントを指定
" -------------------------------------------
let g:Powerline_synbols = 'fancy'
set t_Co=256
