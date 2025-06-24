# homebrew
if [ -e /opt/homebrew/bin/brew ] ; then
    eval $(/opt/homebrew/bin/brew shellenv)
fi
export HOMEBREW_NO_ENV_HINTS=true

# sdkman
export SDKMAN_DIR="${HOME}/.sdkman"
[[ -s "${SDKMAN_DIR}/bin/sdkman-init.sh" ]] && source "${SDKMAN_DIR}/bin/sdkman-init.sh"

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init --path)"
fi

# Created by `pipx`
export PATH="$PATH:${HOME}/.local/bin"

# k8s
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# rust lang
[[ -s ${HOME}/.cargo/env ]] && source ${HOME}/.cargo/env

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"
[ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm"

# volta
export VOLTA_HOME="$HOME/.volta"
export PATH="${VOLTA_HOME}/bin:$PATH"

# npm
export PATH=$PATH:$(npm prefix --location=global)/bin

# ruby
[[ -d ~/.rbenv  ]] && \
  export PATH=${HOME}/.rbenv/bin:${PATH} && \
  eval "$(rbenv init -)"

# Docker CLI completions.
fpath=(/Users/usadamasa/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions

export PATH="${HOME}/local/bin:$PATH"

# aqua
export PATH="${AQUA_ROOT_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/aquaproj-aqua}/bin:$PATH"

