---
name: usadamasa-git-context-testing
description: git alias やシェルスクリプトなど git 関連機能の開発時に、異なるリポジトリコンテキスト(通常 clone、bare repo、worktree)からの実行をテストする bats テストケースの追加を促すスキル。git alias の実装、git 関連のシェルスクリプト作成、worktree/bare 操作を含む機能開発時にプロアクティブに使用する。
---

# Git コンテキストテスト

git の `!` エイリアスは実行時に `GIT_DIR` 環境変数をセットする。worktree 内では絶対パス (`.../.git/worktrees/<name>`) になるため、`git -C` では上書きされず別リポジトリの操作に干渉する。この問題を防ぐため、git 関連機能は複数のリポジトリコンテキストからテストする。

## 必須テストコンテキスト

git alias やスクリプトのテストには、以下の3コンテキストからの実行テストを含める:

| コンテキスト | GIT_DIR の挙動 | リスク |
| --- | --- | --- |
| 通常 clone 内 | 相対パス (`.git`) | 低 |
| bare repo 内 | bare repo パス | 中 |
| worktree 内 | 絶対パス (`.../.git/worktrees/<name>`) | 高 |

## bats ヘルパーパターン

```bash
# 呼び出し元となる別リポジトリ用のリモートを作成
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

# 通常 clone 内に cd
enter_other_regular_repo() {
  setup_caller_remote
  local clone_dir="$TEST_DIR/caller-regular"
  git clone "$CALLER_REMOTE" "$clone_dir" >/dev/null 2>&1
  cd "$clone_dir"
}

# bare repo 内に cd
enter_other_bare_repo() {
  setup_caller_remote
  local bare_dir="$TEST_DIR/caller-bare"
  git clone --bare "$CALLER_REMOTE" "$bare_dir" >/dev/null 2>&1
  cd "$bare_dir"
}

# worktree 内に cd
enter_other_worktree_repo() {
  setup_caller_remote
  local bare_dir="$TEST_DIR/caller-wt/.git"
  mkdir -p "$TEST_DIR/caller-wt"
  git clone --bare "$CALLER_REMOTE" "$bare_dir" >/dev/null 2>&1
  git -C "$bare_dir" config remote.origin.fetch \
    "+refs/heads/*:refs/remotes/origin/*"
  git -C "$bare_dir" fetch origin >/dev/null 2>&1
  git -C "$bare_dir" remote set-head origin --auto >/dev/null 2>&1
  git -C "$bare_dir" worktree add \
    "$TEST_DIR/caller-wt/main" main >/dev/null 2>&1
  cd "$TEST_DIR/caller-wt/main"
}
```

## テストケース命名規則

```bash
@test "他リポジトリの通常 clone 内から実行して <期待動作>" { ... }
@test "他リポジトリの bare repo 内から実行して <期待動作>" { ... }
@test "他リポジトリの worktree 内から実行して <期待動作>" { ... }
```

## GIT_DIR リーク対策

`!` エイリアスでは関数冒頭で環境変数をクリアする:

```gitconfig
alias = "!f() { \
    unset GIT_DIR GIT_WORK_TREE; \
    ...
}; f"
```
