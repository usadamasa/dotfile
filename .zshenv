# Enable XDG Base Directory Specification
export XDG_CONFIG_HOME="$HOME/.config"

# Set zsh configuration directory
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# Set vim configuration directory
export VIMINIT='let $MYVIMRC="$XDG_CONFIG_HOME/vim/vimrc" | source $MYVIMRC'
export VIMDOTDIR="$XDG_CONFIG_HOME/vim"
