# find repo with ghq
function peco-src () {
  local selected_dir=$(ghq list -p | peco --query "$LBUFFER")
  if [ -n "$selected_dir" ]; then
    BUFFER="cd ${selected_dir}"
    zle accept-line
  fi
  zle clear-screen
}
zle -N peco-src
bindkey '^]' peco-src

# find a branch
function peco-gcop() {
  git branch -a --sort=-authordate |
    grep -v -e '->' -e '*' |
    perl -pe 's/^\h+//g' |
    perl -pe 's#^remotes/origin/##' |
    perl -nle 'print if !$c{$_}++' |
    peco |
    xargs git checkout
}
zle -N peco-gcop
bindkey '^[' peco-gcop
