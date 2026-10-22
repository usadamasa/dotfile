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

# npm global packages
# node 本体は nix の profile (home/packages.nix)。global install 先は config/npm/npmrc の prefix で固定なので、
# `npm prefix --location=global` を呼ばずに同じパスを書く (npm が無い状態でも command not found にならない)
export PATH="$XDG_DATA_HOME/npm/bin:$PATH"

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
