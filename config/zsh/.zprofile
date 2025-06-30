# homebrew (highest priority - package manager)
if [ -e /opt/homebrew/bin/brew ] ; then
    eval $(/opt/homebrew/bin/brew shellenv)
fi
export HOMEBREW_NO_ENV_HINTS=true

# System-level package managers
# aqua (binary manager)
export PATH="${AQUA_ROOT_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/aquaproj-aqua}/bin:$PATH"

# Language version managers (order matters for precedence)
# pyenv (Python)
export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init --path)"
fi

# rbenv (Ruby)
[[ -d ~/.rbenv  ]] && \
  export PATH=${HOME}/.rbenv/bin:${PATH} && \
  eval "$(rbenv init -)"

# sdkman (Java/JVM)
[[ -s "${SDKMAN_DIR}/bin/sdkman-init.sh" ]] && source "${SDKMAN_DIR}/bin/sdkman-init.sh"

# Node.js version managers
# nvm
[ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"
[ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm"

# volta (alternative Node.js manager)
export PATH="${VOLTA_HOME}/bin:$PATH"

# Language-specific paths
# rust
[[ -s ${HOME}/.cargo/env ]] && source ${HOME}/.cargo/env

# npm global packages
export PATH=$PATH:$(npm prefix --location=global)/bin

# User-specific paths

# Kubernetes tools
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# Docker CLI completions
fpath=(${HOME}/.docker/completions $fpath)
autoload -Uz compinit
compinit
