#!/usr/bin/env bats
# git bare-clone alias tests
# bare-clone alias の URL パース、ディレクトリ配置、refspec 設定をテストする

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
REAL_GIT_CONFIG="$REPO_ROOT/config/git/config"

setup() {
  TEST_DIR=$(mktemp -d)
  TEST_GHQ_ROOT=$(mktemp -d)

  # テスト用グローバル git config を作成
  # 実際の config を include し、ghq.root だけ上書きする
  TEST_GIT_CONFIG="$TEST_DIR/gitconfig"
  cat > "$TEST_GIT_CONFIG" <<EOF
[include]
  path = $REAL_GIT_CONFIG
[ghq]
  root = $TEST_GHQ_ROOT
[user]
  email = test@example.com
  name = Test User
[init]
  defaultBranch = main
EOF

  export GIT_CONFIG_GLOBAL="$TEST_GIT_CONFIG"
  export HOME="$TEST_DIR"

  # テスト用リモート bare リポジトリを作成
  TEST_REMOTE="$TEST_DIR/remote-repo.git"
  git init --bare "$TEST_REMOTE" >/dev/null 2>&1

  # リモートに初期コミットを追加
  TEMP_CLONE="$TEST_DIR/temp-clone"
  git clone "$TEST_REMOTE" "$TEMP_CLONE" >/dev/null 2>&1
  cd "$TEMP_CLONE"
  echo "initial" > README.md
  git add README.md
  git commit -m "Initial commit" >/dev/null 2>&1
  git push origin main >/dev/null 2>&1
  cd "$TEST_DIR"
  rm -rf "$TEMP_CLONE"
}

teardown() {
  rm -rf "$TEST_DIR" "$TEST_GHQ_ROOT"
  unset GIT_CONFIG_GLOBAL
}

# テスト内で git コマンドを実行するためのダミーリポジトリに cd する
# (git alias は git リポジトリ内でないと実行できない)
enter_dummy_repo() {
  git init "$TEST_DIR/dummy" >/dev/null 2>&1
  cd "$TEST_DIR/dummy"
}

# 呼び出し元となる別リポジトリ用のリモートを作成するヘルパー
setup_caller_remote() {
  CALLER_REMOTE="$TEST_DIR/caller-remote.git"
  git init --bare "$CALLER_REMOTE" >/dev/null 2>&1
  local tmp="$TEST_DIR/tmp-caller"
  git clone "$CALLER_REMOTE" "$tmp" >/dev/null 2>&1
  cd "$tmp"
  echo "caller" > README.md
  git add README.md
  git commit -m "Caller init" >/dev/null 2>&1
  git push origin main >/dev/null 2>&1
  cd "$TEST_DIR"
  rm -rf "$tmp"
}

# 他リポジトリの通常 clone 内に cd する
enter_other_regular_repo() {
  setup_caller_remote
  local clone_dir="$TEST_DIR/caller-regular"
  git clone "$CALLER_REMOTE" "$clone_dir" >/dev/null 2>&1
  cd "$clone_dir"
}

# 他リポジトリの bare repo 内に cd する
enter_other_bare_repo() {
  setup_caller_remote
  local bare_dir="$TEST_DIR/caller-bare"
  git clone --bare "$CALLER_REMOTE" "$bare_dir" >/dev/null 2>&1
  cd "$bare_dir"
}

# 他リポジトリの worktree 内に cd する
enter_other_worktree_repo() {
  setup_caller_remote
  local bare_dir="$TEST_DIR/caller-wt/.git"
  mkdir -p "$TEST_DIR/caller-wt"
  git clone --bare "$CALLER_REMOTE" "$bare_dir" >/dev/null 2>&1
  git -C "$bare_dir" config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
  git -C "$bare_dir" fetch origin >/dev/null 2>&1
  git -C "$bare_dir" remote set-head origin --auto >/dev/null 2>&1
  git -C "$bare_dir" worktree add "$TEST_DIR/caller-wt/main" main >/dev/null 2>&1
  cd "$TEST_DIR/caller-wt/main"
}

# =============================================================================
# URL パースのテスト
# =============================================================================

# URL パースの sed パイプラインを直接テスト
parse_url() {
  echo "$1" | sed -E 's|^[a-z+]*://||; s|^git@||; s|:|/|; s|\.git$||'
}

@test "URL パース: HTTPS URL (.git あり)" {
  result=$(parse_url "https://github.com/owner/repo.git")
  [ "$result" = "github.com/owner/repo" ]
}

@test "URL パース: HTTPS URL (.git なし)" {
  result=$(parse_url "https://github.com/owner/repo")
  [ "$result" = "github.com/owner/repo" ]
}

@test "URL パース: SSH URL (git@形式)" {
  result=$(parse_url "git@github.com:owner/repo.git")
  [ "$result" = "github.com/owner/repo" ]
}

@test "URL パース: SSH URL (ssh://形式)" {
  result=$(parse_url "ssh://git@github.com/owner/repo.git")
  [ "$result" = "github.com/owner/repo" ]
}

@test "URL パース: git:// プロトコル" {
  result=$(parse_url "git://github.com/owner/repo.git")
  [ "$result" = "github.com/owner/repo" ]
}

@test "URL パース: ネストされたパス" {
  result=$(parse_url "https://gitlab.com/group/subgroup/repo.git")
  [ "$result" = "gitlab.com/group/subgroup/repo" ]
}

# =============================================================================
# エラーケース
# =============================================================================

@test "引数なしでエラー" {
  enter_dummy_repo
  run git bare-clone
  [ "$status" -ne 0 ]
  [[ "$output" == *"Usage: git bare-clone"* ]]
}

@test "既存ディレクトリがある場合エラー" {
  mkdir -p "$TEST_GHQ_ROOT/example.com/owner/repo/.git"
  enter_dummy_repo
  run git bare-clone "https://example.com/owner/repo.git"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Already exists"* ]]
}

# =============================================================================
# 正常系: bare clone フロー
# =============================================================================

# file:// URL からパース後のパスを計算するヘルパー
get_clone_target() {
  local parsed_path
  parsed_path=$(echo "file://$TEST_REMOTE" | sed -E 's|^[a-z+]*://||; s|^git@||; s|:|/|; s|\.git$||')
  echo "$TEST_GHQ_ROOT/$parsed_path/.git"
}

get_clone_root() {
  local parsed_path
  parsed_path=$(echo "file://$TEST_REMOTE" | sed -E 's|^[a-z+]*://||; s|^git@||; s|:|/|; s|\.git$||')
  echo "$TEST_GHQ_ROOT/$parsed_path"
}

@test "bare clone でディレクトリが正しく配置される" {
  enter_dummy_repo
  run git bare-clone "file://$TEST_REMOTE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Bare cloned to"* ]]
}

@test "bare clone で .git ディレクトリが bare リポジトリになっている" {
  enter_dummy_repo
  git bare-clone "file://$TEST_REMOTE" >/dev/null 2>&1
  local target
  target=$(get_clone_target)

  [ -f "$target/HEAD" ]
  run git -C "$target" rev-parse --is-bare-repository
  [ "$output" = "true" ]
}

@test "bare clone で refspec が正しく設定される" {
  enter_dummy_repo
  git bare-clone "file://$TEST_REMOTE" >/dev/null 2>&1
  local target
  target=$(get_clone_target)

  run git -C "$target" config remote.origin.fetch
  [ "$output" = "+refs/heads/*:refs/remotes/origin/*" ]
}

@test "bare clone で remote HEAD が設定される" {
  enter_dummy_repo
  git bare-clone "file://$TEST_REMOTE" >/dev/null 2>&1
  local target
  target=$(get_clone_target)

  run git -C "$target" symbolic-ref refs/remotes/origin/HEAD
  [ "$status" -eq 0 ]
  [ "$output" = "refs/remotes/origin/main" ]
}

@test "bare clone でリモートブランチが fetch される" {
  enter_dummy_repo
  git bare-clone "file://$TEST_REMOTE" >/dev/null 2>&1
  local target
  target=$(get_clone_target)

  run git -C "$target" branch -r
  [ "$status" -eq 0 ]
  [[ "$output" == *"origin/main"* ]]
}

# =============================================================================
# worktree 自動作成
# =============================================================================

@test "bare clone でデフォルトブランチの worktree ディレクトリが作成される" {
  enter_dummy_repo
  git bare-clone "file://$TEST_REMOTE" >/dev/null 2>&1
  local root
  root=$(get_clone_root)

  [ -d "$root/main" ]
}

@test "bare clone で worktree に正しいブランチがチェックアウトされている" {
  enter_dummy_repo
  git bare-clone "file://$TEST_REMOTE" >/dev/null 2>&1
  local target
  target=$(get_clone_target)

  run git -C "$target" worktree list
  [ "$status" -eq 0 ]
  [[ "$output" == *"main"* ]]
}

@test "bare clone で worktree にファイルが含まれている" {
  enter_dummy_repo
  git bare-clone "file://$TEST_REMOTE" >/dev/null 2>&1
  local root
  root=$(get_clone_root)

  [ -f "$root/main/README.md" ]
  run cat "$root/main/README.md"
  [ "$output" = "initial" ]
}

@test "bare clone の成功メッセージに worktree 情報が含まれる" {
  enter_dummy_repo
  run git bare-clone "file://$TEST_REMOTE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"(worktree: main)"* ]]
}

# =============================================================================
# 異なるリポジトリコンテキストからの実行 (GIT_DIR リーク防止)
# =============================================================================

@test "他リポジトリの通常 clone 内から実行して worktree が作成される" {
  enter_other_regular_repo
  run git bare-clone "file://$TEST_REMOTE"
  [ "$status" -eq 0 ]
  local root
  root=$(get_clone_root)
  [ -d "$root/main" ]
  [[ "$output" == *"(worktree: main)"* ]]
}

@test "他リポジトリの bare repo 内から実行して worktree が作成される" {
  enter_other_bare_repo
  run git bare-clone "file://$TEST_REMOTE"
  [ "$status" -eq 0 ]
  local root
  root=$(get_clone_root)
  [ -d "$root/main" ]
  [[ "$output" == *"(worktree: main)"* ]]
}

@test "他リポジトリの worktree 内から実行して worktree が作成される" {
  enter_other_worktree_repo
  run git bare-clone "file://$TEST_REMOTE"
  [ "$status" -eq 0 ]
  local root
  root=$(get_clone_root)
  [ -d "$root/main" ]
  [[ "$output" == *"(worktree: main)"* ]]
}
