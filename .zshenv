# Enable XDG Base Directory Specification
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# Set zsh configuration directory
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# Set vim configuration directory
export VIMINIT='let $MYVIMRC="$XDG_CONFIG_HOME/vim/vimrc" | source $MYVIMRC'
export VIMDOTDIR="$XDG_CONFIG_HOME/vim"

# Set XDG Base Directory Specification for Docker
export DOCKER_CONFIG="${XDG_CONFIG_HOME}/docker"

# Set XDG Base Directory Specification for Gradle
export GRADLE_USER_HOME="$XDG_DATA_HOME"/gradle

# Set XDG Base Directory Specification for npm
export NPM_CONFIG_USERCONFIG=$XDG_CONFIG_HOME/npm/npmrc
