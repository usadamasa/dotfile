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

  # refs/remotes/origin/HEAD を設定(デフォルトブランチの判定に必要)
  git remote set-head origin --auto >/dev/null 2>&1

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

# リモートに新しいコミットを追加
add_remote_commit() {
  local original_dir=$(pwd)
  local tmp_clone=$(mktemp -d)
  git clone "$TEST_REMOTE" "$tmp_clone" >/dev/null 2>&1
  cd "$tmp_clone" || return 1
  git config user.email "test@example.com"
  git config user.name "Test User"
  echo "new content $(date +%s)" >> README.md
  git add README.md
  git commit -m "Add new commit" >/dev/null 2>&1
  git push origin main >/dev/null 2>&1 || git push origin master >/dev/null 2>&1
  cd "$original_dir" || return 1
  rm -rf "$tmp_clone"

  # 元のリポジトリでfetch
  cd "$TEST_REPO" && git fetch origin >/dev/null 2>&1
  cd "$original_dir" || return 1
}

# デフォルトブランチ名を取得
get_default_branch() {
  git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'
}

# デフォルトブランチのworktreeパスを取得
get_default_branch_worktree_path() {
  local default_branch
  default_branch=$(get_default_branch)
  # git worktree list の出力から、デフォルトブランチを持つworktreeのパスを取得
  # 形式: /path/to/repo  abc1234 [branch-name]
  git worktree list | grep "\\[$default_branch\\]" | awk '{print $1}'
}

# git mc コマンドのラッパー(テスト用)
# worktree環境ではデフォルトブランチが別worktreeでチェックアウト中の場合、
# そのworktreeにcdしてpullし、元のディレクトリに戻る。
git_mc() {
  local default_branch
  default_branch=$(get_default_branch)
  local current_branch
  current_branch=$(git rev-parse --abbrev-ref HEAD)

  if [ "$current_branch" = "$default_branch" ]; then
    # デフォルトブランチにいる場合はそのままpull
    git pull origin HEAD && gh poi
  else
    # デフォルトブランチのworktreeを探す
    local default_wt_path
    default_wt_path=$(get_default_branch_worktree_path)
    local original_dir
    original_dir=$(pwd)

    if [ -n "$default_wt_path" ] && [ -d "$default_wt_path" ]; then
      # worktreeが見つかった場合はそこにcdしてpull
      cd "$default_wt_path" && git pull origin HEAD && cd "$original_dir" && gh poi
    else
      # worktreeが見つからない場合(mainがどこにもチェックアウトされてない)
      # git fetch origin main:main でローカルmainを更新
      git fetch origin "$default_branch:$default_branch" && gh poi
    fi
  fi
}
