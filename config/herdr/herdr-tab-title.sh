#!/usr/bin/env bash
# Claude Code の UserPromptSubmit フックとして動き、送信したプロンプトの先頭を
# herdr のタブ名に反映する。
#
# 制約:
#   - UserPromptSubmit の標準出力はモデルのコンテキストへ注入されるため、
#     このスクリプトは標準出力へ一切書かない。診断は標準エラーへ出す。
#   - フックの失敗でプロンプト送信を妨げないよう、常に exit 0 で終える。
#     このため `set -e` は使わず、失敗は個別に捕捉して標準エラーへ記録する。
set -uo pipefail

# タブ名の最大文字数 (超過分は末尾を … に置き換える)
MAX_TITLE_CHARS=20
readonly MAX_TITLE_CHARS

# タブ名にするプロンプトの先頭を取り出す。空白は 1 個に潰す。
extract_title() {
  jq -r --argjson max "$MAX_TITLE_CHARS" '
    (.prompt // "")
    | gsub("\\s+"; " ")
    | sub("^ +"; "")
    | sub(" +$"; "")
    | if length == 0 then empty
      elif length > $max then .[0:($max - 1)] + "…"
      else .
      end
  '
}

# どのタブを rename するかを決める。曖昧なときは何も返さない。
#
#   1. herdr が claude 連携フックから受け取ったセッション ID と一致するペイン
#   2. セッション ID が未登録で、cwd が一致する claude ペインがちょうど 1 つ
#
# HERDR_TAB_ID / HERDR_PANE_ID は共有デーモン配下で古い値のまま残ることがあり、
# 実際のタブとずれるため使わない。
resolve_tab_id() {
  local session_id="$1"
  local cwd="$2"

  jq -r --arg sid "$session_id" --arg cwd "$cwd" '
    (.result.snapshot.panes // []) as $panes
    | ($panes | map(select(
        ($sid | length) > 0 and ((.agent_session.value? // "") == $sid)
      ))) as $exact
    | if ($exact | length) > 0 then
        $exact[0].tab_id
      else
        ($panes | map(select(
          .agent == "claude"
          and (.agent_session == null)
          and ($cwd | length) > 0
          and ((.cwd == $cwd) or (.foreground_cwd == $cwd))
        ))) as $by_cwd
        | if ($by_cwd | length) == 1 then $by_cwd[0].tab_id else empty end
      end
  '
}

main() {
  local input title session_id cwd snapshot tab_id

  input=$(cat)

  # herdr のペインの外や、必要なコマンドが無い環境では何もしない
  [ "${HERDR_ENV:-}" = "1" ] || return 0
  command -v herdr >/dev/null 2>&1 || return 0
  command -v jq >/dev/null 2>&1 || return 0

  # サブエージェントのプロンプトはタブ名に反映しない
  if [ -n "$(printf '%s' "$input" | jq -r '.agent_id // empty')" ]; then
    return 0
  fi

  title=$(printf '%s' "$input" | extract_title)
  [ -n "$title" ] || return 0

  session_id=$(printf '%s' "$input" | jq -r '.session_id // empty')
  cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')

  if ! snapshot=$(herdr api snapshot 2>&1); then
    printf '%s\n' "herdr api snapshot に失敗しました: $snapshot" >&2
    return 0
  fi

  tab_id=$(printf '%s' "$snapshot" | resolve_tab_id "$session_id" "$cwd")
  if [ -z "$tab_id" ]; then
    printf '%s\n' "このセッションに対応する herdr のタブを特定できません" >&2
    return 0
  fi

  local result
  if ! result=$(herdr tab rename "$tab_id" "$title" 2>&1); then
    printf '%s\n' "タブ名の変更に失敗しました: $result" >&2
    return 0
  fi
}

main "$@"
exit 0
