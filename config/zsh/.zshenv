# ZDOTDIR を引き継いだ zsh は ~/.zshenv ではなくこのファイルを読むので、本体をここから読む。
# ZDOTDIR が無い zsh は ~/.zshenv だけを読み、このファイルは読まない
source "$HOME/.zshenv"
