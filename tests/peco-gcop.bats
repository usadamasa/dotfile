#!/usr/bin/env bats
# peco-gcop unit tests

# Load test helpers and fixtures
setup() {
  DOTFILE_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

  # Load fixtures
  load 'fixtures/git-setup.sh'

  # Load mocks first (mock bindkey and zle before loading target)
  load 'helpers/zle-mock.sh'
  load 'helpers/peco-mock.sh'

  # Load target source
  source "$DOTFILE_DIR/config/zsh/funcs/peco-src.sh"
}

teardown() {
  cleanup_test_repo
}

# =============================================================================
# Error cases
# =============================================================================

@test "returns error when not in a git repository" {
  cd "$(mktemp -d)"

  run _peco_gcop_list_branches

  [ "$status" -ne 0 ]
  [[ "$output" == *"Not in a git repository"* ]]
}

# =============================================================================
# Branch listing
# =============================================================================

@test "local branch gets (local) label" {
  create_test_repo
  create_local_branch "feature-local"

  run _peco_gcop_list_branches

  [ "$status" -eq 0 ]
  [[ "$output" == *"feature-local (local)"* ]]
}

@test "remote-only branch has no label" {
  create_test_repo
  create_remote_only_branch "feature-remote"

  run _peco_gcop_list_branches

  [ "$status" -eq 0 ]
  [[ "$output" == *"feature-remote"* ]]
  [[ "$output" != *"feature-remote (local)"* ]]
  [[ "$output" != *"feature-remote (current)"* ]]
}

@test "duplicate branches are removed when local and remote exist" {
  create_test_repo
  create_local_branch "feature-both"

  git checkout feature-both >/dev/null 2>&1
  git push origin feature-both >/dev/null 2>&1
  git checkout main >/dev/null 2>&1 || git checkout master >/dev/null 2>&1

  run _peco_gcop_list_branches

  [ "$status" -eq 0 ]
  local count=$(echo "$output" | grep -c "feature-both")
  [ "$count" -eq 1 ]
}

@test "current branch gets (current) label" {
  create_test_repo
  create_local_branch "feature-current"
  git checkout feature-current >/dev/null 2>&1

  run _peco_gcop_list_branches

  [ "$status" -eq 0 ]
  [[ "$output" == *"feature-current (current)"* ]]
}

# =============================================================================
# Worktree support
# =============================================================================

@test "worktree branch gets (worktree) label" {
  create_test_repo
  create_worktree "feature-worktree" "worktree-dir"

  run _peco_gcop_list_branches

  [ "$status" -eq 0 ]
  [[ "$output" == *"feature-worktree (worktree)"* ]]
}

@test "worktree branch selection sets cd command in BUFFER" {
  create_test_repo
  create_worktree "feature-worktree" "worktree-dir"

  # Run directly without 'run' to check BUFFER changes
  BUFFER=""
  _peco_gcop_checkout "feature-worktree"
  local status=$?

  [ "$status" -eq 0 ]
  [[ "$BUFFER" == *"cd"* ]]
  [[ "$BUFFER" == *"$WORKTREE_PATH"* ]]
}

# =============================================================================
# Checkout
# =============================================================================

@test "can checkout local branch" {
  create_test_repo
  create_local_branch "feature-checkout"

  run _peco_gcop_checkout "feature-checkout"

  [ "$status" -eq 0 ]
  local current=$(git symbolic-ref --short HEAD)
  [ "$current" = "feature-checkout" ]
}

@test "can checkout remote branch" {
  create_test_repo
  create_remote_only_branch "feature-remote-checkout"

  run _peco_gcop_checkout "feature-remote-checkout"

  [ "$status" -eq 0 ]
  local current=$(git symbolic-ref --short HEAD)
  [ "$current" = "feature-remote-checkout" ]
}

# =============================================================================
# Cancel handling
# =============================================================================

@test "peco cancel does not cause error" {
  create_test_repo

  PECO_MOCK_SELECTION=""

  run peco-gcop

  [ "$status" -eq 0 ]
}
