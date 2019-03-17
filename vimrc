:let $VIMFILE_DIR = '.vim'

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

