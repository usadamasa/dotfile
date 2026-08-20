#!/usr/bin/env bats
# herdr-new-agent.sh のテスト
# ペイン分割の向きの判定と、エージェント起動までの呼び出しを検証

SCRIPT="$BATS_TEST_DIRNAME/../config/herdr/herdr-new-agent.sh"

setup() {
  export MOCK_LOG="$BATS_TEST_TMPDIR/calls.log"

  MOCK_BIN="$BATS_TEST_TMPDIR/mock-bin"
  mkdir -p "$MOCK_BIN"

  # herdr モック: 呼び出しを記録しつつ、API と同じ形の JSON を返す
  cat > "$MOCK_BIN/herdr" <<'MOCK'
#!/usr/bin/env bash
printf 'CALLED: %s\n' "$*" >> "$MOCK_LOG"
case "$1 $2" in
  "pane layout")
    printf '{"result":{"layout":{"panes":[{"pane_id":"%s","rect":{"width":%s,"height":%s}}]}}}\n' \
      "${MOCK_PANE_ID:-wA:p1}" "${MOCK_PANE_WIDTH:-135}" "${MOCK_PANE_HEIGHT:-42}"
    ;;
  "pane split")
    if [ "${MOCK_SPLIT_FAILS:-0}" = "1" ]; then
      printf '{"error":{"code":"pane_not_found"}}\n' >&2
      exit 1
    fi
    printf '{"result":{"pane":{"pane_id":"wA:p2"}}}\n'
    ;;
esac
MOCK
  chmod +x "$MOCK_BIN/herdr"

  export PATH="$MOCK_BIN:$PATH"
  # スクリプトは "${HERDR_BIN_PATH:-herdr}" を呼ぶ。herdr のペイン内で実行すると
  # 実環境の HERDR_BIN_PATH (本物のバイナリ) が漏れてモックが使われないため、
  # 実環境と同じくこの変数を明示し、モックを指すようにする。
  export HERDR_BIN_PATH="$MOCK_BIN/herdr"
  export HERDR_ACTIVE_PANE_ID="wA:p1"
  export HERDR_ACTIVE_PANE_CWD="/repo/a"
}

# =============================================================================
# 構文チェック
# =============================================================================

@test "スクリプトの構文が正しい" {
  run bash -n "$SCRIPT"
  [ "$status" -eq 0 ]
}

# =============================================================================
# 分割の向き
# =============================================================================

@test "横長のペインは right に分割する" {
  export MOCK_PANE_WIDTH=135
  export MOCK_PANE_HEIGHT=42

  run bash "$SCRIPT" claude
  [ "$status" -eq 0 ]

  run cat "$MOCK_LOG"
  [[ "$output" == *"--direction right"* ]]
}

@test "正方形に近いペインは down に分割する" {
  export MOCK_PANE_WIDTH=80
  export MOCK_PANE_HEIGHT=42

  run bash "$SCRIPT" claude
  [ "$status" -eq 0 ]

  run cat "$MOCK_LOG"
  [[ "$output" == *"--direction down"* ]]
}

@test "レイアウトを取得できないときは right にフォールバックする" {
  cat > "$MOCK_BIN/herdr" <<'MOCK'
#!/usr/bin/env bash
printf 'CALLED: %s\n' "$*" >> "$MOCK_LOG"
case "$1 $2" in
  "pane layout")
    printf 'server unavailable\n' >&2
    exit 1
    ;;
  "pane split")
    printf '{"result":{"pane":{"pane_id":"wA:p2"}}}\n'
    ;;
esac
MOCK
  chmod +x "$MOCK_BIN/herdr"

  run bash "$SCRIPT" claude
  [ "$status" -eq 0 ]

  run cat "$MOCK_LOG"
  [[ "$output" == *"--direction right"* ]]
}

# =============================================================================
# エージェントの起動
# =============================================================================

@test "分割したペインで指定した種類のエージェントを起動する" {
  run bash "$SCRIPT" claude
  [ "$status" -eq 0 ]

  run cat "$MOCK_LOG"
  [[ "$output" == *"agent start claude-p2 --kind claude --pane wA:p2"* ]]
}

@test "種類を省略すると claude を起動する" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]

  run cat "$MOCK_LOG"
  [[ "$output" == *"--kind claude"* ]]
}

@test "呼び出し元ペインの cwd を引き継ぐ" {
  run bash "$SCRIPT" claude
  [ "$status" -eq 0 ]

  run cat "$MOCK_LOG"
  [[ "$output" == *"--cwd /repo/a"* ]]
}

# =============================================================================
# 異常系
# =============================================================================

@test "HERDR_ACTIVE_PANE_ID が空なら通知して失敗する" {
  export HERDR_ACTIVE_PANE_ID=""

  run bash "$SCRIPT" claude
  [ "$status" -eq 1 ]

  run cat "$MOCK_LOG"
  [[ "$output" == *"notification show"* ]]
  [[ "$output" != *"pane split"* ]]
}

@test "ペインの分割に失敗したら通知して失敗する" {
  export MOCK_SPLIT_FAILS=1

  run bash "$SCRIPT" claude
  [ "$status" -eq 1 ]

  run cat "$MOCK_LOG"
  [[ "$output" == *"notification show"* ]]
  [[ "$output" != *"agent start"* ]]
}
