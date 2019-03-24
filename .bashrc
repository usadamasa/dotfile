# 新規作成のファイルのパーミッションを常に644に設定
umask 022

# coreファイルの作成を抑止
ulimit -c 0

# エンコーディング
export LANG=ja_JP.utf-8
export LC_ALL=ja_JP.utf-8

#ブロックサイズの単位
export BLOCKSIZE=k

export EDITOR=/opt/local/bin/vim
export NEXINIT=set exrc

# git commit EDITOR
GIT_EDITOR=vim
export GIT_EDITOR


# ページ送りにless
export PAGER="less -R"

# lsをカラーリング
alias ls='ls -G'

# grep実行時に必ず付与
export GREP_OPTIONS="--color=auto"

# lessのステータス行にファイル名、行数、パーセンテージ表示
export LESS='-X -i -P ?f%f:(stdin). ?lb%lb?L/%L.. [?eEOF:?pb%pb\%..]'


##
# alias and functions
#

# GNU
alias date="gdate"

alias ll="ls -al"

# colordiff
alias diff='colordiff'

export PIPENV_VENV_IN_PROJECT=true

