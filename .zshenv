# Enable XDG Base Directory Specification
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# XDG for Tools

# zsh
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# vim
export VIMINIT='let $MYVIMRC="$XDG_CONFIG_HOME/vim/vimrc" | source $MYVIMRC'
export VIMDOTDIR="$XDG_CONFIG_HOME/vim"

# less
export LESSHISTFILE="$XDG_STATE_HOME/less/history"
mkdir -p "$XDG_STATE_HOME/less"

# Docker
# https://github.com/usadamasa/dotfile/issues/14
# export DOCKER_CONFIG="${XDG_CONFIG_HOME}/docker"
# mkdir -p "$DOCKER_CONFIG"
# export MACHINE_STORAGE_PATH="$XDG_DATA_HOME"/docker-machine
# mkdir -p "$MACHINE_STORAGE_PATH"

# Languages

# js
export NPM_CONFIG_USERCONFIG=$XDG_CONFIG_HOME/npm/npmrc
mkdir -p "$XDG_CONFIG_HOME/npm"
export NVM_DIR="$HOME/.nvm"
export VOLTA_HOME="$HOME/.volta"

# golang
export GOPATH="$XDG_DATA_HOME/go"
mkdir -p "$GOPATH"

# Java
export GRADLE_USER_HOME="$XDG_DATA_HOME"/gradle
mkdir -p "$GRADLE_USER_HOME"
export SDKMAN_DIR="$XDG_DATA_HOME/sdkman"

# Python
export PYENV_ROOT="$XDG_DATA_HOME/pyenv"
mkdir -p "$PYENV_ROOT"
export PIPX_HOME=$XDG_DATA_HOME/pipx
mkdir -p "$PIPX_HOME"
