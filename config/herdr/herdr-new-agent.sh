#!/usr/bin/env bash
# herdr のカスタムコマンド ([[keys.command]] type = "shell") から呼ばれ、
# 現在のペインを分割して新しいエージェントを起動する。
#
# herdr は type = "shell" のコマンドを /bin/sh -lc で detached 実行するため、
# 標準エラー出力はどこにも表示されない。失敗はトーストで通知する。
set -euo pipefail

KIND="${1:-claude}"
readonly KIND

HERDR_BIN="${HERDR_BIN_PATH:-herdr}"
readonly HERDR_BIN

# 失敗をユーザーに見える形で伝える
notify_error() {
  local message="$1"
  printf '%s\n' "$message" >&2
  if ! "$HERDR_BIN" notification show "新しい ${KIND} を起動できません" \
    --body "$message" --sound none >/dev/null 2>&1; then
    printf '%s\n' "トースト通知にも失敗しました" >&2
  fi
}

# 端末のセルは縦長なので、幅が高さのおよそ 2 倍を超えるときだけ横に割る。
# レイアウトを取得できないときは right にフォールバックする。
split_direction() {
  local pane_id="$1"
  local layout rect width height

  if ! layout=$("$HERDR_BIN" pane layout --pane "$pane_id" 2>&1); then
    printf '%s\n' "ペインのレイアウト取得に失敗しました: $layout" >&2
    printf '%s\n' "right"
    return 0
  fi

  rect=$(printf '%s' "$layout" | jq -r --arg pane "$pane_id" '
    .result.layout.panes // []
    | map(select(.pane_id == $pane))
    | if length == 1 then "\(.[0].rect.width) \(.[0].rect.height)" else empty end
  ')
  if [ -z "$rect" ]; then
    printf '%s\n' "right"
    return 0
  fi

  width=${rect%% *}
  height=${rect##* }
  if [ "$width" -gt $((height * 2)) ]; then
    printf '%s\n' "right"
  else
    printf '%s\n' "down"
  fi
}

main() {
  local pane_id cwd direction response new_pane agent_name

  pane_id="${HERDR_ACTIVE_PANE_ID:-}"
  if [ -z "$pane_id" ]; then
    notify_error "HERDR_ACTIVE_PANE_ID が空です"
    exit 1
  fi
  cwd="${HERDR_ACTIVE_PANE_CWD:-$HOME}"

  direction=$(split_direction "$pane_id")

  if ! response=$("$HERDR_BIN" pane split \
    --pane "$pane_id" \
    --direction "$direction" \
    --cwd "$cwd" \
    --focus 2>&1); then
    notify_error "ペインの分割に失敗しました: $response"
    exit 1
  fi

  new_pane=$(printf '%s' "$response" | jq -r '.result.pane.pane_id // empty')
  if [ -z "$new_pane" ]; then
    notify_error "分割したペインの ID を取得できません: $response"
    exit 1
  fi

  # 同一タブ内で名前が衝突しないよう、ペイン ID の末尾を付ける
  agent_name="${KIND}-${new_pane##*:}"

  if ! response=$("$HERDR_BIN" agent start "$agent_name" \
    --kind "$KIND" \
    --pane "$new_pane" 2>&1); then
    notify_error "${KIND} の起動に失敗しました: $response"
    exit 1
  fi
}

main "$@"
