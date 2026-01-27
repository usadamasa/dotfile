---
name: git-worktree
description: git-wt を使用した Git worktree 管理ガイド。worktree の作成、切り替え、削除、設定について説明します。
---

# git-worktree

git-wt は Git worktree をより便利に扱うためのツールです。ブランチ間の移動や複数ブランチの同時作業を効率化します。

## git-wt とは

Git worktree は同一リポジトリの複数ブランチを別ディレクトリで同時に開く機能です。git-wt はこれをシンプルなコマンドで操作できるようにします。

### インストール

```bash
brew install k1LoW/tap/git-wt
```

## 基本コマンド

### worktree 一覧表示

```bash
git wt
```

現在の worktree 一覧を表示します。

### worktree 作成/切り替え

```bash
git wt <branch>
```

- 既存のブランチ: そのブランチの worktree に切り替え（なければ作成）
- 新規ブランチ: worktree を作成してそこに移動

### worktree 削除

```bash
# 通常の削除
git wt -d <branch>

# 強制削除
git wt -D <branch>
```

## シェル統合

zsh で `git wt` 後に自動的にディレクトリ移動するには、以下を `.zshrc` に追加:

```bash
eval "$(git wt --init zsh)"
```

bash の場合:

```bash
eval "$(git wt --init bash)"
```

## 設定オプション

`~/.config/git/config` または各リポジトリの `.git/config` で設定できます。

### 設定項目

| 設定 | 説明 | デフォルト |
|------|------|----------|
| `wt.basedir` | worktree の作成先ディレクトリ | `../worktrees/{gitroot}` |
| `wt.copyignored` | .gitignore ファイルをコピー | false |
| `wt.copyuntracked` | 未追跡ファイルをコピー | false |
| `wt.copymodified` | 変更済みファイルをコピー | false |
| `wt.hook` | worktree 作成後に実行するコマンド | なし |

### 推奨設定例

```ini
[wt]
    copyignored = true
    copyuntracked = true
    copymodified = true
    hook = test -f .envrc && direnv allow || true
    basedir = ../worktrees/{gitroot}
```

**設定の解説:**

- `copyignored/copyuntracked/copymodified = true`: 作業中のファイルを新しい worktree にコピー。環境設定ファイルなどを引き継げる
- `hook = test -f .envrc && direnv allow || true`: direnv 環境変数を自動で許可。`.envrc` がない場合はスキップ
- `basedir = ../worktrees/{gitroot}`: worktree を親ディレクトリの `worktrees/` 以下に配置

## 使用例

### 機能開発中に別ブランチの作業が必要になった場合

```bash
# 現在のブランチで作業中
git wt hotfix-123
# → ../worktrees/myrepo/hotfix-123 に移動して作業

# 作業完了後、元のブランチに戻る
git wt feature-abc
```

### 複数の PR を同時にレビュー

```bash
# PR #1 のブランチを確認
git wt pr-1-branch
# レビュー...

# PR #2 のブランチを確認（別ウィンドウで）
git wt pr-2-branch
# レビュー...
```

## トラブルシューティング

### direnv エラーが出る

worktree 作成時に `.envrc: No such file or directory` のようなエラーが出る場合、hook 設定を確認してください:

```ini
# 修正前（.envrc がないとエラー出力）
hook = direnv allow ; true

# 修正後（.envrc がない場合はスキップ）
hook = test -f .envrc && direnv allow || true
```

### worktree が見つからない

```bash
# worktree の一覧と場所を確認
git worktree list
```

## 関連リンク

- [git-wt GitHub](https://github.com/k1LoW/git-wt)
- [Git worktree 公式ドキュメント](https://git-scm.com/docs/git-worktree)
