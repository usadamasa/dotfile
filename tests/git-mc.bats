#!/usr/bin/env bats
# git-mc スクリプトのテスト
# worktree/非worktree 環境での分岐動作を検証

SCRIPT="$BATS_TEST_DIRNAME/../config/git/git-mc"

setup() {
  TEST_DIR="$BATS_TEST_TMPDIR"
  export MOCK_LOG="$TEST_DIR/calls.log"

  # origin/HEAD の指す先。テスト本体から書き換えて stale な状態を作る
  export MOCK_ORIGIN_HEAD_FILE="$TEST_DIR/origin_head"
  printf '%s\n' "refs/remotes/origin/main" > "$MOCK_ORIGIN_HEAD_FILE"

  # コマンド呼び出しを記録するディレクトリ
  MOCK_BIN="$TEST_DIR/mock-bin"
  mkdir -p "$MOCK_BIN"

  # git モック: サブコマンドごとに動作を切り替え
  cat > "$MOCK_BIN/git" <<'MOCK'
#!/usr/bin/env bash
case "$1" in
  symbolic-ref)
    origin_head=$(cat "$MOCK_ORIGIN_HEAD_FILE")
    [ -n "$origin_head" ] || exit 1
    echo "$origin_head"
    ;;
  remote)
    shift; echo "CALLED: git remote $*" >> "$MOCK_LOG"
    if [ "${MOCK_SET_HEAD_FIXES:-1}" = "1" ]; then
      printf '%s\n' "refs/remotes/origin/main" > "$MOCK_ORIGIN_HEAD_FILE"
    else
      : > "$MOCK_ORIGIN_HEAD_FILE"
    fi
    ;;
  rev-parse)
    if [ "$2" = "--git-dir" ]; then
      echo "${MOCK_GIT_DIR:-.git}"
    elif [ "$2" = "--git-common-dir" ]; then
      echo "${MOCK_GIT_COMMON_DIR:-.git}"
    elif [ "$2" = "--verify" ]; then
      # 実在するリモート追跡ブランチは main だけ
      [ "$4" = "refs/remotes/origin/main" ]
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

@test "git pull --tags --force origin main が実行される" {
  export MOCK_GIT_DIR=".git"
  export MOCK_GIT_COMMON_DIR=".git"

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]

  run cat "$MOCK_LOG"
  [[ "$output" == *"git pull --tags --force origin main"* ]]
}

# =============================================================================
# origin/HEAD が古い場合の再解決
# =============================================================================

@test "origin/HEAD が消えたブランチを指すとき再解決してから switch する" {
  export MOCK_GIT_DIR=".git"
  export MOCK_GIT_COMMON_DIR=".git"
  printf '%s\n' "refs/remotes/origin/init/import-tenant-assets" > "$MOCK_ORIGIN_HEAD_FILE"

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]

  run cat "$MOCK_LOG"
  [[ "$output" == *"git remote set-head origin --auto"* ]]
  [[ "$output" == *"git switch main"* ]]
  [[ "$output" != *"git switch init/import-tenant-assets"* ]]
}

@test "origin/HEAD が存在しないときも再解決する" {
  export MOCK_GIT_DIR=".git"
  export MOCK_GIT_COMMON_DIR=".git"
  : > "$MOCK_ORIGIN_HEAD_FILE"

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]

  run cat "$MOCK_LOG"
  [[ "$output" == *"git remote set-head origin --auto"* ]]
  [[ "$output" == *"git switch main"* ]]
}

@test "再解決しても既定ブランチが分からなければエラー終了する" {
  export MOCK_GIT_DIR=".git"
  export MOCK_GIT_COMMON_DIR=".git"
  export MOCK_SET_HEAD_FIXES=0
  : > "$MOCK_ORIGIN_HEAD_FILE"

  run bash "$SCRIPT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"cannot resolve the default branch"* ]]

  # 既定ブランチが不明なまま switch や pull へ進まない
  run cat "$MOCK_LOG"
  [[ "$output" != *"git switch"* ]]
  [[ "$output" != *"git pull"* ]]
}

# =============================================================================
# 共通動作 (続き)
# =============================================================================

@test "gh poi が実行される" {
  export MOCK_GIT_DIR=".git"
  export MOCK_GIT_COMMON_DIR=".git"

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]

  run cat "$MOCK_LOG"
  [[ "$output" == *"gh poi"* ]]
}
