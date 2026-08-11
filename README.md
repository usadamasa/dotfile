# dotfiles

macOS開発環境用のdotfilesリポジトリです。[Homebrew](https://brew.sh/)と[go-task](https://taskfile.dev/)で自動化されたセットアップを提供します。

## 🚀 セットアップ

```sh
# リポジトリをクローン
brew install git ghq
export GHQ_ROOT=~/src
ghq get https://github.com/usadamasa/dotfile.git
cd ~/src/github.com/usadamasa/dotfile

# 初回セットアップ
task bootstrap

# セットアップ状況確認
task status
```

## 📋 コマンド

```sh
task              # タスク一覧表示
task bootstrap    # 初回セットアップ
task setup        # 完全セットアップ
task status       # 状況確認
task clean        # 設定削除
```

## 🛠️ 管理ツール

- **Git関連**: git, gh, ghq, git-now, tig
- **開発ツール**: jq, direnv, peco, zsh, pipx
- **ターミナル**: herdr, tmux, iterm2
- **GUI**: font-cica, jetbrains-toolbox, visual-studio-code

## 📁 構成

```tree
dotfile/
├── Taskfile.yml  # セットアップ自動化
├── .zshenv      # XDG Base Directory設定
└── config/      # 各種設定ファイル
    ├── git/
    ├── herdr/   # config.toml のみ (socket・ログは ~/.config/herdr に残す)
    ├── npm/
    ├── vim/
    └── zsh/
```
