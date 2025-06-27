# Enable XDG Base Directory Specification
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# Tools

# Set zsh configuration directory
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# Set vim configuration directory
export VIMINIT='let $MYVIMRC="$XDG_CONFIG_HOME/vim/vimrc" | source $MYVIMRC'
export VIMDOTDIR="$XDG_CONFIG_HOME/vim"

# Set XDG Base Directory Specification for less
export LESSHISTFILE="$XDG_STATE_HOME/less/history"
mkdir -p "$XDG_STATE_HOME/less"

# Set XDG Base Directory Specification for Docker
# https://github.com/usadamasa/dotfile/issues/14
# export DOCKER_CONFIG="${XDG_CONFIG_HOME}/docker"
# mkdir -p "$DOCKER_CONFIG"
# export MACHINE_STORAGE_PATH="$XDG_DATA_HOME"/docker-machine
# mkdir -p "$MACHINE_STORAGE_PATH"

# Languages

# Set XDG Base Directory Specification for npm
export NPM_CONFIG_USERCONFIG=$XDG_CONFIG_HOME/npm/npmrc
mkdir -p "$XDG_CONFIG_HOME/npm"

# Set XDG Base Directory Specification for golang
export GOPATH="$XDG_DATA_HOME/go"
mkdir -p "$GOPATH"

# Set XDG Base Directory Specification for Java tools
export GRADLE_USER_HOME="$XDG_DATA_HOME"/gradle
mkdir -p "$GRADLE_USER_HOME"
export SDKMAN_DIR="$XDG_DATA_HOME/sdkman"

# Set XDG Base Directory Specification for python tools
export PYENV_ROOT="$XDG_DATA_HOME/pyenv"
mkdir -p "$PYENV_ROOT"
export PIPX_HOME=$XDG_DATA_HOME/pipx
mkdir -p "$PIPX_HOME"

export NVM_DIR="$HOME/.nvm"
export VOLTA_HOME="$HOME/.volta"
