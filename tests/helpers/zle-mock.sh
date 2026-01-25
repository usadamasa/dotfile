#!/usr/bin/env bash
# zle のモック

# zle 関連変数のモック
BUFFER=""
LBUFFER=""

# zle コマンドのモック
zle() {
  local cmd="$1"
  case "$cmd" in
    accept-line)
      # accept-line は何もしない
      ;;
    reset-prompt)
      # reset-prompt は何もしない
      ;;
    clear-screen)
      # clear-screen は何もしない
      ;;
    -N)
      # ウィジェット登録は何もしない
      ;;
    *)
      # 未知のコマンドは無視
      ;;
  esac
}

# bindkey コマンドのモック
bindkey() {
  # 何もしない
  :
}

export -f zle
export -f bindkey
export BUFFER LBUFFER
