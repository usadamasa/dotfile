# homebrew (highest priority - package manager)
if [ -e /opt/homebrew/bin/brew ] ; then
    eval $(/opt/homebrew/bin/brew shellenv)
fi
export HOMEBREW_NO_ENV_HINTS=true

# nix の profile を /usr/bin と /opt/homebrew/bin より前に戻す。
# .zshenv (nix-daemon.sh) で先頭に置いても、ログインシェルでは /etc/zprofile の path_helper が /usr/bin などを
# 前に並べ直し、上の brew shellenv がさらに前に付く。macOS 同梱 (/usr/bin/jq) や brew に残った版より
# home-manager (home/packages.nix) の版を使うため、path_helper の後のここでもう一度前に置く。
# NIX_PROFILES は nix-daemon.sh が export する (default と user の profile、空白区切り)。
# 順に先頭へ足すので、後ろの user profile が先頭になる (nix-daemon.sh と同じ並び)
for profile in ${=NIX_PROFILES}; do
  export PATH="$profile/bin:$PATH"
done

# System-level package managers
# aqua (binary manager)
# export PATH="${AQUA_ROOT_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/aquaproj-aqua}/bin:$PATH"

# Language version managers (order matters for precedence)
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
