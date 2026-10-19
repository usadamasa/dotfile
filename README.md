# dotfiles

macOS 開発環境用の dotfiles リポジトリです。[go-task](https://taskfile.dev/) でセットアップを自動化し、
日常使いのツールは [Homebrew](https://brew.sh/)、このリポジトリの開発ツールは [Nix](https://nixos.org/) の devShell で管理します。

## 🚀 セットアップ

```sh
# リポジトリをクローン
brew install git ghq
export GHQ_ROOT=~/src
ghq get https://github.com/usadamasa/dotfile.git
cd ~/src/github.com/usadamasa/dotfile

# 初回セットアップ (Homebrew・Nix のインストールに sudo のパスワードを求められる)
task bootstrap

# セットアップ状況確認
task status
```

## 📋 コマンド

```sh
task                  # タスク一覧表示
task bootstrap        # 初回セットアップ
task setup            # 完全セットアップ
task status           # 状況確認
task clean            # 設定削除
task test             # bats でシェルスクリプトのテストを実行
task format           # editorconfig-checker でチェック
task nix:check-flake  # flake.nix の devShell を検証
task nix:update       # flake.lock の nixpkgs を更新
```

## 🛠️ ツールの管理

- **Homebrew**: 日常使いのツールとフォント。一覧は [Brewfile](Brewfile)。
- **Nix**: [Determinate Nix](https://determinate.systems/) を入れ、このリポジトリのテストと lint のツールを
  [flake.nix](flake.nix) の devShell に置く。direnv (`.envrc` の `use flake`) がリポジトリに入ったときに読み込む。

## 📁 構成

```tree
dotfile/
├── Brewfile      # Homebrew で入れるツール
├── Taskfile.yml  # セットアップ自動化
├── flake.nix     # 開発ツールの devShell
├── .zshenv       # XDG Base Directory 設定
├── config/       # 各種設定ファイル (~/.config へ symlink する)
│   ├── direnv/
│   ├── git/
│   ├── nix/      # nix.conf と nix 関連の task
│   ├── npm/
│   ├── vim/
│   └── zsh/
└── tests/        # bats のテスト
```
