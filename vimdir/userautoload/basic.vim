" swapファイル、backupファイル格納場所の指定
set swapfile
set directory=~/.vim/.tmp/.vimswap
set backup
set backupdir=~/.vim/.tmp/.vimbackup

" [Backspace]で既存の文字を削除できるように設定
" start	-既存の文字を削除できるように設定
" eol	-行頭で[Backspace]を使用した場合、上の行と連結
" indent-オートインデントモードでインデントを削除できるように設定
set backspace=start,eol,indent

" **********************
" キーマッピング
" **********************
" 特定のキーに行頭および行末の回り込み移動を許可する設定
" b	-[Backspace]	ノーマルモード	ビジュアルモード
" s	-[Space]		ノーマルモード	ビジュアルモード
" < -[←]			ノーマルモード	ビジュアルモード
" >	-[→]			ノーマルモード	ビジュアルモード
" [	-[←]			挿入モード		置換モード
" ]	-[→]			挿入モード		置換モード
" ~	-~				ノーマルモード
set whichwrap=b,s,[,]<,>,~
" デフォルトキーマップの無効
nnoremap Q <Nop>

" シンタックスハイライト
syntax on

" 検索キーワードをハイライトから除外
set nohlsearch
" カーソルラインの強調表示を有効化
set cursorline 
" 行番号を表示
set number
" ルーラー表示
set ruler
" カーソルを常にウィンドウの中央に
set scrolloff=999
" view inputting command
set showcmd
" 空白文字の表示
set list
" 空白文字の記号
set listchars=tab:»\ ,eol:↓,trail:_,extends:»,precedes:«,nbsp:%
" タブラインの常時表示
set showtabline=2

" 全角スペースのハイライト
highlight zenkakuda cterm=underline ctermfg=black guibg=black
match zenkakuda /　/ "←全角スペース

" ステータスラインを常に表示
set laststatus=2
" ステータスラインの内容
" %M 編集済み表示 %r 読取のみ %F フルパス %l 現在行 %L 全体行 %p 行パーセンテージ
"set statusline=[%1(%M%r%)][%F]%l/%L(%p%%)
" モード表示
set showmode

" クリップボードをOSと共有
set clipboard+=unnamed,autoselect

" インクリメンタル検索を有効化
set incsearch

" オートインデントモード
" 改行時に現在の行と同レベルでインデント
set autoindent

" 閉じ括弧と対応する開き括弧をハイライト
set showmatch

set backup
" タブの挿入幅" 
set tabstop=4
" タブの表示幅
set shiftwidth=4
" タブをスペースに展開
set expandtab
" 新しいウィンドウを下に開く
set splitbelow

" 補完時の一覧表示機能の有効化
set wildmenu wildmode=list:full

" シンタクス読み込み
autocmd BufRead,BufNewFile *.mkd setfiletype mkd
autocmd BufRead,BufNewFile *.md setfiletype mkd
