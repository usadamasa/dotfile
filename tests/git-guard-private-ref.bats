#!/usr/bin/env bats
# git-guard-private-ref: 業務 org のコミットで個人 skill・個人 OSS への言及を止める guard
# 検出ロジック (pre-commit / commit-msg) と、git 2.56 config-based hook への配線を検証する

SCRIPT="$BATS_TEST_DIRNAME/../config/git/git-guard-private-ref"
PATTERNS_FILE="$BATS_TEST_DIRNAME/../config/git/private-ref-patterns.txt"
GUARD_CONFIG="$BATS_TEST_DIRNAME/../config/git/gitconfig.guard"

setup() {
  TEST_REPO="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$TEST_REPO"
  cd "$TEST_REPO"
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"
  printf 'base\n' > README.md
  git add README.md
  git commit -q -m "initial"
}

stage_line() {
  # $1: 追加する行の内容
  printf '%s\n' "$1" >> README.md
  git add README.md
}

# =============================================================================
# pre-commit: 非検出 (業務でも正当に出る語)
# =============================================================================

@test "pre-commit: 業務でも出る一般語・公式名は通す" {
  while IFS='|' read -r label line; do
    [ -z "$label" ] && continue
    cd "$TEST_REPO"
    git checkout -q -- README.md 2>/dev/null || true
    stage_line "$line"
    run "$SCRIPT" pre-commit
    [ "$status" -eq 0 ] || {
      echo "label=$label output=$output"
      false
    }
    git reset -q HEAD README.md
    git checkout -q -- README.md
  done <<'CASES'
bare-mention|see @usadamasa for review
crit|run crit comment to leave feedback
dotfile|this repo is usadamasa's dotfile setup
go-template|scaffolded from go-template
actions-lock|pin with gh actions-lock / actions.lock
CASES
}

# =============================================================================
# pre-commit: 検出 (owner 付き参照・固有プロジェクト名)
# =============================================================================

@test "pre-commit: owner 付き参照・個人プロジェクト名を検出する" {
  while IFS='|' read -r label line; do
    [ -z "$label" ] && continue
    cd "$TEST_REPO"
    git checkout -q -- README.md 2>/dev/null || true
    stage_line "$line"
    run "$SCRIPT" pre-commit
    [ "$status" -eq 1 ] || {
      echo "label=$label output=$output"
      false
    }
    [[ "$output" == *"README.md"* ]]
    git reset -q HEAD README.md
    git checkout -q -- README.md
  done <<'CASES'
owner-qualified|see usadamasa/gh-manage/actions/verify-actions-lock
github-url|https://github.com/usadamasa/agents-daemon
project-name|agents-daemon のセッション常駐デーモンを使う
CASES
}

@test "pre-commit: クリーンな差分は通す" {
  stage_line "no personal references here"
  run "$SCRIPT" pre-commit
  [ "$status" -eq 0 ]
}

@test "pre-commit: 2 つ目のハンクの行番号も正しく報告する" {
  printf 'line1\nline2\nline3\nline4\nline5\n' > body.txt
  git add body.txt
  git commit -q -m "add body"

  # 1 つ目のハンク (1 行目を無害な変更) と、2 つ目のハンク (5 行目の後に個人参照を追加)
  printf 'line1-changed\nline2\nline3\nline4\nline5\nusadamasa/gh-manage\n' > body.txt
  git add body.txt

  run "$SCRIPT" pre-commit
  [ "$status" -eq 1 ]
  [[ "$output" == *"body.txt:6:"* ]]
}

@test "pre-commit: リネーム+編集で混入した参照も検出する" {
  printf 'line1\nline2\nline3\n' > old-name.txt
  git add old-name.txt
  git commit -q -m "add old-name.txt"

  git mv old-name.txt new-name.txt
  printf 'line1\nline2\nline3\nusadamasa/gh-manage\n' > new-name.txt
  git add new-name.txt

  run "$SCRIPT" pre-commit
  [ "$status" -eq 1 ]
  [[ "$output" == *"new-name.txt"* ]]
}

# =============================================================================
# commit-msg
# =============================================================================

@test "commit-msg: 本文中の個人プロジェクト名を検出する" {
  MSG_FILE="$BATS_TEST_TMPDIR/msg"
  printf 'fix: verify-actions-lock を agents-daemon 経由で呼ぶ\n' > "$MSG_FILE"

  run "$SCRIPT" commit-msg "$MSG_FILE"
  [ "$status" -eq 1 ]
}

@test "commit-msg: コメント行 (#) は無視する" {
  MSG_FILE="$BATS_TEST_TMPDIR/msg"
  {
    printf 'fix: ci を直す\n'
    printf '# Please enter the commit message...\n'
    printf '# agents-daemon への言及はコメント行なので無視される\n'
  } > "$MSG_FILE"

  run "$SCRIPT" commit-msg "$MSG_FILE"
  [ "$status" -eq 0 ]
}

@test "commit-msg: scissors 行より下 (commit -v の差分) は無視する" {
  MSG_FILE="$BATS_TEST_TMPDIR/msg"
  {
    printf 'fix: ci を直す\n'
    printf '# ------------------------ >8 ------------------------\n'
    printf '# Do not modify or remove the line above.\n'
    printf '+usadamasa/agents-daemon への言及を含む既存コードの差分\n'
  } > "$MSG_FILE"

  run "$SCRIPT" commit-msg "$MSG_FILE"
  [ "$status" -eq 0 ]
}

# =============================================================================
# パターンファイルの読み込み
# =============================================================================

@test "パターンファイルが存在しない場合はエラー終了する" {
  # スクリプトは自身と同じディレクトリの private-ref-patterns.txt を読む。
  # コピー先には置かないので「見つからない」状態を再現できる。
  cp "$SCRIPT" "$BATS_TEST_TMPDIR/script-copy"
  chmod +x "$BATS_TEST_TMPDIR/script-copy"

  run "$BATS_TEST_TMPDIR/script-copy" pre-commit
  [ "$status" -eq 1 ]
  [[ "$output" == *"パターンファイル"* ]]
}

# =============================================================================
# git config-based hook への配線 (git 2.56 hook.<name>.command / .event)
# =============================================================================

setup_guard_home() {
  GUARD_HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$GUARD_HOME/.config"
  ln -s "$BATS_TEST_DIRNAME/../config/git" "$GUARD_HOME/.config/git"

  GUARD_GLOBAL_CONFIG="$BATS_TEST_TMPDIR/gitconfig.global"
  WORK_DIR="$BATS_TEST_TMPDIR/work"
  mkdir -p "$WORK_DIR"
  # includeIf の gitdir: は linked worktree からだと realpath で比較される
  # (config/git/CLAUDE.md 参照)。$TMPDIR 自体が symlink (macOS の /tmp -> /private/tmp) なので
  # symlink のままのパスを書くと worktree からの一致だけが抜け落ちる
  WORK_DIR_REAL=$(cd "$WORK_DIR" && pwd -P)

  cat > "$GUARD_GLOBAL_CONFIG" <<CONF
[includeIf "gitdir:$WORK_DIR_REAL/"]
  path = ~/.config/git/gitconfig.guard
CONF

  export HOME="$GUARD_HOME"
  export GIT_CONFIG_GLOBAL="$GUARD_GLOBAL_CONFIG"
  export GIT_CONFIG_NOSYSTEM=1
}

@test "config-based hook: 業務 org 配下では pre-commit に guard が配線される" {
  setup_guard_home
  REPO="$WORK_DIR/some-repo"
  mkdir -p "$REPO"
  cd "$REPO"
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"

  run git hook list pre-commit --show-scope
  [ "$status" -eq 0 ]
  [[ "$output" == *"guard-private-ref-pre-commit"* ]]
}

@test "config-based hook: 業務 org 配下のリポジトリでは個人参照のコミットが拒否される" {
  setup_guard_home
  REPO="$WORK_DIR/some-repo"
  mkdir -p "$REPO"
  cd "$REPO"
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"

  printf 'usadamasa/agents-daemon の harness を使う\n' > NOTES.md
  git add NOTES.md
  run git commit -m "add notes"
  [ "$status" -ne 0 ]
}

@test "config-based hook: 業務 org 配下では linked worktree でも guard が配線される" {
  setup_guard_home
  REPO="$WORK_DIR/some-repo"
  mkdir -p "$REPO"
  cd "$REPO"
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"
  printf 'base\n' > README.md
  git add README.md
  git commit -q -m "initial"
  git branch feature

  WT="$BATS_TEST_TMPDIR/some-repo-wt"
  git worktree add -q "$WT" feature
  cd "$WT"

  run git hook list pre-commit --show-scope
  [ "$status" -eq 0 ]
  [[ "$output" == *"guard-private-ref-pre-commit"* ]]
}

@test "config-based hook: 業務 org 配下でなければ guard は配線されない" {
  setup_guard_home
  REPO="$BATS_TEST_TMPDIR/outside-repo"
  mkdir -p "$REPO"
  cd "$REPO"
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"

  run git hook list pre-commit --show-scope
  [[ "$output" != *"guard-private-ref-pre-commit"* ]]
}
