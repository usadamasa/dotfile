# CLAUDE.md

<!-- このファイルは上位のCLAUDE.mdを継承しています -->
<!-- 上位CLAUDE.md: ../../CLAUDE.md -->

## このディレクトリについて

Git のグローバル設定ファイル群を管理するディレクトリ。`~/.config/git/` にシンプリンクされ、XDG Base Directory 準拠の配置で動作する。

## ディレクトリ構造

| ファイル | 役割 |
| --- | --- |
| `config` | メインの gitconfig。include で他ファイルを読み込む |
| `gitconfig.local` | デフォルトのユーザー情報 (会社用) |
| `gitconfig.private` | 個人リポジトリ用ユーザー情報。`includeIf gitdir` で自動適用 |
| `ignore` | グローバル gitignore |

## 設定の仕組み

### ユーザー自動切替

`config` 内の `includeIf` ディレクティブにより、`gitdir` ベースでユーザー情報を自動切替する:

- **デフォルト**: `gitconfig.local` (環境固有アカウント)
- **`~/src/github.com/usadamasa/` 配下**: `gitconfig.private` (個人アカウント)

### 主要な設定値

- `pull.rebase = true`, `pull.ff = only` - fast-forward のみの pull + rebase 戦略
- `merge.conflictStyle = diff3` - 3-way diff でコンフリクト表示
- `fetch.prune = true` - fetch 時にリモート削除済みブランチを自動削除
- `ghq.root = ~/src` - ghq のリポジトリルート
- `init.defaultBranch = main`

### カスタムエイリアス

- `git clone-bare <url>` - bare clone を `<ghq.root>/<host>/<owner>/<repo>/.git` に配置｡refspec 設定 & fetch & HEAD 自動設定まで一括実行
- `git mc` - メインブランチに切替 + pull + `gh poi` でマージ済みブランチ削除

### git-wt (worktree) 設定

`[wt]` セクションで worktree 作成時の挙動を制御:

- ignored/untracked/modified ファイルをコピー
- `.envrc` があれば `direnv allow` を自動実行
- worktree の配置先: `../worktrees/{gitroot}`

## その他の注意事項

- `gitconfig.private` にはメールアドレス等の個人情報が含まれるため、コミット時に内容を確認すること
- `config` 内のパスは `~/.config/git/` を基準にしているため、シンプリンク先を意識すること
- `ignore` の変更は全リポジトリに影響する
