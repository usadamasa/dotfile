#!/usr/bin/env bats
# git mc unit tests
# worktree対応版 git mc コマンドのテスト

setup() {
  DOTFILE_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  load 'fixtures/git-setup.sh'
  load 'helpers/gh-poi-mock.sh'
  setup_gh_poi_mock
}

teardown() {
  cleanup_gh_poi_mock
  cleanup_test_repo
}

# =============================================================================
# デフォルトブランチでの動作
# =============================================================================

@test "on default branch: pulls and runs gh poi" {
  create_test_repo
  cd "$TEST_REPO"

  run git_mc

  [ "$status" -eq 0 ]
  gh_poi_was_called
}

@test "on default branch: pulls latest changes" {
  create_test_repo
  cd "$TEST_REPO"

  # リモートに新しいコミットを追加
  add_remote_commit
  local remote_sha=$(git rev-parse origin/main 2>/dev/null || git rev-parse origin/master)

  run git_mc

  [ "$status" -eq 0 ]
  local local_sha=$(git rev-parse HEAD)
  [ "$local_sha" = "$remote_sha" ]
}

# =============================================================================
# worktree での動作
# =============================================================================

@test "in worktree: fetches default branch without switching" {
  create_test_repo
  cd "$TEST_REPO"
  create_worktree "feature-wt" "wt-dir"
  cd "$WORKTREE_PATH"

  local before_branch=$(git rev-parse --abbrev-ref HEAD)
  run git_mc
  local after_branch=$(git rev-parse --abbrev-ref HEAD)

  [ "$status" -eq 0 ]
  [ "$before_branch" = "$after_branch" ]
  [ "$before_branch" = "feature-wt" ]
}

@test "in worktree: gh poi is called" {
  create_test_repo
  cd "$TEST_REPO"
  create_worktree "feature-wt" "wt-dir"
  cd "$WORKTREE_PATH"

  run git_mc

  [ "$status" -eq 0 ]
  gh_poi_was_called
}

@test "in worktree: default branch is updated via cd" {
  create_test_repo
  cd "$TEST_REPO"
  create_worktree "feature-wt" "wt-dir"

  # リモートに新しいコミットを追加
  add_remote_commit
  local remote_sha=$(git rev-parse origin/main 2>/dev/null || git rev-parse origin/master)

  cd "$WORKTREE_PATH"
  run git_mc

  [ "$status" -eq 0 ]
  # cd方式でデフォルトブランチのworktreeに移動してpullするので、ローカルmainも最新化される
  local local_sha=$(git rev-parse main 2>/dev/null || git rev-parse master)
  [ "$local_sha" = "$remote_sha" ]
}

@test "in worktree: returns to original directory after git mc" {
  create_test_repo
  cd "$TEST_REPO"
  create_worktree "feature-wt" "wt-dir"
  cd "$WORKTREE_PATH"

  local original_dir=$(pwd)
  run git_mc
  local after_dir=$(pwd)

  [ "$status" -eq 0 ]
  [ "$original_dir" = "$after_dir" ]
}

# =============================================================================
# 通常のfeatureブランチでの動作
# =============================================================================

@test "on feature branch: stays on current branch" {
  create_test_repo
  cd "$TEST_REPO"
  create_local_branch "feature-test"
  git checkout feature-test >/dev/null 2>&1

  run git_mc

  [ "$status" -eq 0 ]
  local current=$(git rev-parse --abbrev-ref HEAD)
  [ "$current" = "feature-test" ]
}

@test "on feature branch: default branch is updated" {
  create_test_repo
  cd "$TEST_REPO"
  create_local_branch "feature-test"
  git checkout feature-test >/dev/null 2>&1

  # リモートに新しいコミットを追加
  add_remote_commit
  local remote_sha=$(git rev-parse origin/main 2>/dev/null || git rev-parse origin/master)

  run git_mc

  [ "$status" -eq 0 ]
  # featureブランチでもmainのworktreeにcdしてpullするので、ローカルmainも最新化される
  local local_sha=$(git rev-parse main 2>/dev/null || git rev-parse master)
  [ "$local_sha" = "$remote_sha" ]
}

@test "on feature branch: gh poi is called" {
  create_test_repo
  cd "$TEST_REPO"
  create_local_branch "feature-test"
  git checkout feature-test >/dev/null 2>&1

  run git_mc

  [ "$status" -eq 0 ]
  gh_poi_was_called
}
