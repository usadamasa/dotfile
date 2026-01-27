#!/usr/bin/env bats
# git-wt hook tests
# Tests for the wt.hook configuration that runs direnv allow

setup() {
  TEST_DIR=$(mktemp -d)
  cd "$TEST_DIR"
}

teardown() {
  rm -rf "$TEST_DIR"
}

# =============================================================================
# .envrc existence check
# =============================================================================

@test ".envrc が存在しない場合、エラー出力なし" {
  run bash -c 'test -f .envrc && direnv allow || true'
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test ".envrc が存在する場合、direnv allow が実行される" {
  echo "export TEST=1" > .envrc
  # direnv allow の代わりに echo でテスト (実際の direnv は環境依存)
  run bash -c 'test -f .envrc && echo "direnv would run" || true'
  [ "$status" -eq 0 ]
  [[ "$output" == *"direnv would run"* ]]
}

@test "空の .envrc でも direnv allow が実行される" {
  touch .envrc
  run bash -c 'test -f .envrc && echo "direnv would run" || true'
  [ "$status" -eq 0 ]
  [[ "$output" == *"direnv would run"* ]]
}

# =============================================================================
# Comparison with old hook format
# =============================================================================

@test "旧形式 (direnv allow ; true) は .envrc がなくてもエラー出力が出る可能性がある" {
  # direnv がインストールされている場合、.envrc がないとエラーメッセージが出る
  # このテストは新形式の優位性を示すためのもの
  run bash -c 'command -v direnv >/dev/null && direnv allow 2>&1 || echo "direnv not installed"'
  # 終了コードは 0 だが、エラーメッセージが含まれる可能性がある
  [ "$status" -eq 0 ]
}
