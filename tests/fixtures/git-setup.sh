#!/usr/bin/env bash
# テスト用Gitリポジトリのセットアップ

# テスト用リポジトリを作成
# 戻り値: TEST_REPO と TEST_REMOTE を設定
create_test_repo() {
  TEST_REMOTE=$(mktemp -d)
  TEST_REPO=$(mktemp -d)

  # bare リポジトリ(remote用)を作成
  git init --bare "$TEST_REMOTE" >/dev/null 2>&1

  # 作業リポジトリを作成
  git clone "$TEST_REMOTE" "$TEST_REPO" >/dev/null 2>&1
  cd "$TEST_REPO" || return 1

  # Git設定
  git config user.email "test@example.com"
  git config user.name "Test User"

  # 初期コミットを作成
  echo "initial" > README.md
  git add README.md
  git commit -m "Initial commit" >/dev/null 2>&1

  # リモートにプッシュ
  git push origin main >/dev/null 2>&1 || git push origin master >/dev/null 2>&1

  export TEST_REPO TEST_REMOTE
}

# ローカルブランチを作成
# $1: ブランチ名
create_local_branch() {
  local branch_name="$1"
  git checkout -b "$branch_name" >/dev/null 2>&1
  echo "$branch_name content" > "$branch_name.txt"
  git add "$branch_name.txt"
  git commit -m "Add $branch_name" >/dev/null 2>&1
  git checkout main >/dev/null 2>&1 || git checkout master >/dev/null 2>&1
}

# リモートブランチを作成(ローカルにはない)
# $1: ブランチ名
create_remote_only_branch() {
  local branch_name="$1"
  local original_dir=$(pwd)

  # 一時ディレクトリでリモートにプッシュ
  local tmp_clone=$(mktemp -d)
  git clone "$TEST_REMOTE" "$tmp_clone" >/dev/null 2>&1
  cd "$tmp_clone" || return 1
  git config user.email "test@example.com"
  git config user.name "Test User"
  git checkout -b "$branch_name" >/dev/null 2>&1
  echo "$branch_name content" > "$branch_name.txt"
  git add "$branch_name.txt"
  git commit -m "Add $branch_name" >/dev/null 2>&1
  git push origin "$branch_name" >/dev/null 2>&1

  cd "$original_dir" || return 1
  rm -rf "$tmp_clone"

  # 元のリポジトリでfetch
  git fetch origin >/dev/null 2>&1
}

# worktree を作成
# $1: ブランチ名
# $2: worktree パス名(一意なパスが自動生成される)
create_worktree() {
  local branch_name="$1"
  local worktree_name="$2"

  # まずブランチを作成
  create_local_branch "$branch_name"

  # 一意な worktree パスを生成
  local worktree_dir=$(mktemp -d)
  rm -rf "$worktree_dir"  # mktemp で作成されたディレクトリを削除(git worktree add が作成するため)

  # worktree を追加
  git worktree add "$worktree_dir" "$branch_name" >/dev/null 2>&1

  export WORKTREE_PATH="$worktree_dir"
}

# テスト用リポジトリをクリーンアップ
cleanup_test_repo() {
  # worktree ディレクトリを削除
  if [ -n "$WORKTREE_PATH" ] && [ -d "$WORKTREE_PATH" ]; then
    rm -rf "$WORKTREE_PATH"
  fi
  if [ -n "$TEST_REPO" ] && [ -d "$TEST_REPO" ]; then
    # worktree を先に削除
    cd "$TEST_REPO" 2>/dev/null && git worktree prune 2>/dev/null
    rm -rf "$TEST_REPO"
  fi
  if [ -n "$TEST_REMOTE" ] && [ -d "$TEST_REMOTE" ]; then
    rm -rf "$TEST_REMOTE"
  fi
  unset TEST_REPO TEST_REMOTE WORKTREE_PATH
}
