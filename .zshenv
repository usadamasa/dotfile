# ZDOTDIR を決めて本体を読むだけにする。
# ZDOTDIR を引き継いだ zsh は ~/.zshenv を読まずに $ZDOTDIR/.zshenv を読むので、本体はそちらに置く
export ZDOTDIR="$HOME/.config/zsh"
source "$ZDOTDIR/.zshenv"
