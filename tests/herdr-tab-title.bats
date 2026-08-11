#!/usr/bin/env bats
# herdr-tab-title.sh のテスト
# Claude Code のフック入力から、どの herdr タブを rename するかの判定を検証

SCRIPT="$BATS_TEST_DIRNAME/../config/herdr/herdr-tab-title.sh"

setup() {
  export MOCK_LOG="$BATS_TEST_TMPDIR/calls.log"
  export SNAPSHOT_FILE="$BATS_TEST_TMPDIR/snapshot.json"

  MOCK_BIN="$BATS_TEST_TMPDIR/mock-bin"
  mkdir -p "$MOCK_BIN"

  # herdr モック: api snapshot はフィクスチャを返し、tab rename は記録する
  cat > "$MOCK_BIN/herdr" <<'MOCK'
#!/usr/bin/env bash
case "$1 $2" in
  "api snapshot")
    cat "$SNAPSHOT_FILE"
    ;;
  "tab rename")
    shift 2
    printf 'CALLED: tab rename %s\n' "$*" >> "$MOCK_LOG"
    ;;
  *)
    printf 'CALLED: %s\n' "$*" >> "$MOCK_LOG"
    ;;
esac
MOCK
  chmod +x "$MOCK_BIN/herdr"

  export PATH="$MOCK_BIN:$PATH"
  export HERDR_ENV=1

  # 既定のスナップショット:
  #   wA:p1 … セッション ID 登録済み
  #   wB:p1 … セッション ID 未登録
  cat > "$SNAPSHOT_FILE" <<'JSON'
{
  "result": {
    "snapshot": {
      "panes": [
        {
          "agent": "claude",
          "pane_id": "wA:p1",
          "tab_id": "wA:t1",
          "cwd": "/repo/a",
          "foreground_cwd": "/repo/a",
          "agent_session": {
            "source": "herdr:claude",
            "agent": "claude",
            "kind": "session_id",
            "value": "sess-aaa"
          }
        },
        {
          "agent": "claude",
          "pane_id": "wB:p1",
          "tab_id": "wB:t1",
          "cwd": "/repo/b",
          "foreground_cwd": "/repo/b",
          "agent_session": null
        }
      ]
    }
  }
}
JSON
}

# フック入力の JSON を組み立てる
hook_input() {
  local prompt="$1" session_id="${2:-}" cwd="${3:-}" agent_id="${4:-}"
  jq -n \
    --arg prompt "$prompt" \
    --arg session_id "$session_id" \
    --arg cwd "$cwd" \
    --arg agent_id "$agent_id" \
    '{hook_event_name: "UserPromptSubmit", prompt: $prompt, session_id: $session_id, cwd: $cwd}
    + (if ($agent_id | length) > 0 then {agent_id: $agent_id} else {} end)'
}

# =============================================================================
# 構文チェック
# =============================================================================

@test "スクリプトの構文が正しい" {
  run bash -n "$SCRIPT"
  [ "$status" -eq 0 ]
}

# =============================================================================
# タブの特定
# =============================================================================

@test "セッション ID が一致するペインのタブを rename する" {
  run bash "$SCRIPT" <<< "$(hook_input "請求書の集計" "sess-aaa" "/repo/a")"
  [ "$status" -eq 0 ]

  run cat "$MOCK_LOG"
  [[ "$output" == *"tab rename wA:t1 請求書の集計"* ]]
}

@test "セッション ID 未登録でも cwd が一意に一致すれば rename する" {
  run bash "$SCRIPT" <<< "$(hook_input "テストを直す" "sess-unknown" "/repo/b")"
  [ "$status" -eq 0 ]

  run cat "$MOCK_LOG"
  [[ "$output" == *"tab rename wB:t1 テストを直す"* ]]
}

@test "cwd が一致しなければ rename しない" {
  run bash "$SCRIPT" <<< "$(hook_input "テストを直す" "sess-unknown" "/repo/zzz")"
  [ "$status" -eq 0 ]
  [ ! -f "$MOCK_LOG" ]
}

@test "cwd が一致する候補が複数あれば rename しない" {
  cat > "$SNAPSHOT_FILE" <<'JSON'
{
  "result": {
    "snapshot": {
      "panes": [
        {"agent": "claude", "pane_id": "wA:p1", "tab_id": "wA:t1",
          "cwd": "/repo/a", "foreground_cwd": "/repo/a", "agent_session": null},
        {"agent": "claude", "pane_id": "wA:p2", "tab_id": "wA:t2",
          "cwd": "/repo/a", "foreground_cwd": "/repo/a", "agent_session": null}
      ]
    }
  }
}
JSON

  run bash "$SCRIPT" <<< "$(hook_input "テストを直す" "sess-unknown" "/repo/a")"
  [ "$status" -eq 0 ]
  [ ! -f "$MOCK_LOG" ]
}

@test "claude 以外のエージェントのペインは cwd 一致でも対象にしない" {
  cat > "$SNAPSHOT_FILE" <<'JSON'
{
  "result": {
    "snapshot": {
      "panes": [
        {"agent": "codex", "pane_id": "wA:p1", "tab_id": "wA:t1",
          "cwd": "/repo/a", "foreground_cwd": "/repo/a", "agent_session": null}
      ]
    }
  }
}
JSON

  run bash "$SCRIPT" <<< "$(hook_input "テストを直す" "sess-unknown" "/repo/a")"
  [ "$status" -eq 0 ]
  [ ! -f "$MOCK_LOG" ]
}

# =============================================================================
# タブ名の整形
# =============================================================================

@test "20 文字を超えるプロンプトは末尾を … に置き換える" {
  run bash "$SCRIPT" <<< "$(hook_input "あいうえおかきくけこさしすせそたちつてとなにぬねの" "sess-aaa" "/repo/a")"
  [ "$status" -eq 0 ]

  run cat "$MOCK_LOG"
  [[ "$output" == *"tab rename wA:t1 あいうえおかきくけこさしすせそたちつて…"* ]]
}

@test "改行と連続する空白は 1 個の空白に潰す" {
  run bash "$SCRIPT" <<< "$(hook_input $'テストを\n\n  直す' "sess-aaa" "/repo/a")"
  [ "$status" -eq 0 ]

  run cat "$MOCK_LOG"
  [[ "$output" == *"tab rename wA:t1 テストを 直す"* ]]
}

@test "空白だけのプロンプトでは rename しない" {
  run bash "$SCRIPT" <<< "$(hook_input $'  \n  ' "sess-aaa" "/repo/a")"
  [ "$status" -eq 0 ]
  [ ! -f "$MOCK_LOG" ]
}

# =============================================================================
# ガード節
# =============================================================================

@test "HERDR_ENV が 1 でなければ何もしない" {
  unset HERDR_ENV

  run bash "$SCRIPT" <<< "$(hook_input "請求書の集計" "sess-aaa" "/repo/a")"
  [ "$status" -eq 0 ]
  [ ! -f "$MOCK_LOG" ]
}

@test "サブエージェントのプロンプトでは rename しない" {
  run bash "$SCRIPT" <<< "$(hook_input "請求書の集計" "sess-aaa" "/repo/a" "agent-1")"
  [ "$status" -eq 0 ]
  [ ! -f "$MOCK_LOG" ]
}

# =============================================================================
# 出力
# =============================================================================

@test "標準出力には何も書かない" {
  output=$(bash "$SCRIPT" 2>/dev/null <<< "$(hook_input "請求書の集計" "sess-aaa" "/repo/a")")
  [ -z "$output" ]
}

@test "herdr api snapshot が失敗しても exit 0 で終わる" {
  cat > "$MOCK_BIN/herdr" <<'MOCK'
#!/usr/bin/env bash
printf 'server unavailable\n' >&2
exit 1
MOCK
  chmod +x "$MOCK_BIN/herdr"

  run bash "$SCRIPT" <<< "$(hook_input "請求書の集計" "sess-aaa" "/repo/a")"
  [ "$status" -eq 0 ]
}
