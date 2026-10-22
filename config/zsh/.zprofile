# homebrew (highest priority - package manager)
if [ -e /opt/homebrew/bin/brew ] ; then
    eval $(/opt/homebrew/bin/brew shellenv)
fi
export HOMEBREW_NO_ENV_HINTS=true

# System-level package managers
# aqua (binary manager)
# export PATH="${AQUA_ROOT_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/aquaproj-aqua}/bin:$PATH"

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

# Language-specific paths
# rust
[[ -s ${HOME}/.cargo/env ]] && source ${HOME}/.cargo/env

# cargo
export PATH=${CARGO_HOME}/bin:$PATH

# go install
export PATH="$(go env GOPATH)/bin:$PATH"

# User-specific paths

# claude-config: `task build:bin` が cmd/ の Go CLI をここへ出力する。
# hook は同じ実体を絶対パスで起動するので、PATH に載せるのは skill から
# `cc-dream` のように名前で叩くため。
export PATH="$HOME/.claude/bin:$PATH"

# Kubernetes tools
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# Docker CLI completions
fpath=(${HOME}/.docker/completions $fpath)

# Added by Obsidian
export PATH="$PATH:/Applications/Obsidian.app/Contents/MacOS"

autoload -Uz compinit
compinit
