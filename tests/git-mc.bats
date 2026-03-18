#!/usr/bin/env bats
# git-mc スクリプトのテスト
# worktree/非worktree 環境での分岐動作を検証

SCRIPT="$BATS_TEST_DIRNAME/../config/git/git-mc"

setup() {
  TEST_DIR=$(mktemp -d)
  export MOCK_LOG="$TEST_DIR/calls.log"

  # コマンド呼び出しを記録するディレクトリ
  MOCK_BIN="$TEST_DIR/mock-bin"
  mkdir -p "$MOCK_BIN"

  # git モック: サブコマンドごとに動作を切り替え
  cat > "$MOCK_BIN/git" <<'MOCK'
#!/usr/bin/env bash
case "$1" in
  symbolic-ref)
    echo "refs/remotes/origin/main"
    ;;
  rev-parse)
    if [ "$2" = "--git-dir" ]; then
      echo "${MOCK_GIT_DIR:-.git}"
    elif [ "$2" = "--git-common-dir" ]; then
      echo "${MOCK_GIT_COMMON_DIR:-.git}"
    fi
    ;;
  switch)
    echo "CALLED: git switch $2" >> "$MOCK_LOG"
    ;;
  wt)
    echo "CALLED: git wt $2" >> "$MOCK_LOG"
    ;;
  pull)
    shift; echo "CALLED: git pull $*" >> "$MOCK_LOG"
    ;;
esac
MOCK
  chmod +x "$MOCK_BIN/git"

  # gh モック
  cat > "$MOCK_BIN/gh" <<'MOCK'
#!/usr/bin/env bash
echo "CALLED: gh $*" >> "$MOCK_LOG"
MOCK
  chmod +x "$MOCK_BIN/gh"

  export PATH="$MOCK_BIN:$PATH"
}

teardown() {
  rm -rf "$TEST_DIR"
}

# =============================================================================
# 構文チェック
# =============================================================================

@test "スクリプトの構文が正しい" {
  run bash -n "$SCRIPT"
  [ "$status" -eq 0 ]
}

# =============================================================================
# 通常リポジトリ (git-dir == git-common-dir)
# =============================================================================

@test "通常リポジトリでは git switch が呼ばれる" {
  export MOCK_GIT_DIR=".git"
  export MOCK_GIT_COMMON_DIR=".git"

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]

  # git switch が呼ばれたことを確認
  run cat "$MOCK_LOG"
  [[ "$output" == *"git switch main"* ]]
  # git wt が呼ばれていないことを確認
  [[ "$output" != *"git wt"* ]]
}

# =============================================================================
# worktree 環境 (git-dir != git-common-dir)
# =============================================================================

@test "worktree 環境では git wt が呼ばれる" {
  export MOCK_GIT_DIR="/path/to/repo/.git/worktrees/feature"
  export MOCK_GIT_COMMON_DIR="/path/to/repo/.git"

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]

  # git wt が呼ばれたことを確認
  run cat "$MOCK_LOG"
  [[ "$output" == *"git wt main"* ]]
  # git switch が呼ばれていないことを確認
  [[ "$output" != *"git switch"* ]]
}

# =============================================================================
# 共通動作
# =============================================================================

@test "git pull --tags origin HEAD が実行される" {
  export MOCK_GIT_DIR=".git"
  export MOCK_GIT_COMMON_DIR=".git"

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]

  run cat "$MOCK_LOG"
  [[ "$output" == *"git pull --tags origin HEAD"* ]]
}

@test "gh poi が実行される" {
  export MOCK_GIT_DIR=".git"
  export MOCK_GIT_COMMON_DIR=".git"

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]

  run cat "$MOCK_LOG"
  [[ "$output" == *"gh poi"* ]]
}
