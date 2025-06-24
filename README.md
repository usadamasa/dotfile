# dotfiles

macOS開発環境用のdotfilesリポジトリです。XDG Base Directory仕様に準拠し、[Homebrew](https://brew.sh/)と[go-task](https://taskfile.dev/)を使用して自動化されたセットアップを提供します。

## 🚀 クイックスタート

### 初回セットアップ（推奨）

```sh
# リポジトリをクローン（Homebrewがない場合は先にインストール）
# /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install \
  ghq \
  git \
  go-task

export GHQ_ROOT=~/src
ghq get https://github.com/usadamasa/dotfile.git
cd ~/src/github.com/usadamasa/dotfile

# 初回セットアップを実行（Homebrew + go-task + 完全セットアップ）
task bootstrap
```

### 通常セットアップ（go-taskがインストール済みの場合）

```sh
# セットアップを実行
task setup

# セットアップ状況を確認
task status
```

## 📋 利用可能なタスク

```sh
# 初回セットアップ（Homebrew + go-task + 完全セットアップ）
task bootstrap

# 完全セットアップ
task setup

# セットアップ状況確認
task status

# 設定クリーンアップ（注意：設定ファイルが削除されます）
task clean

# 利用可能なタスク一覧
task --list
```

## 🛠️ 管理されるツール

### Homebrewで管理されるツール

- **Git関連**: git, gh, ghq, git-now, tig
- **開発ツール**: jq, direnv, peco
- **シェル**: zsh
- **Python**: pipx (powerline-shell用)
- **タスクランナー**: go-task
- **フォント**: font-cica
- **IDE/エディタ**: jetbrains-toolbox, visual-studio-code

### 手動インストールが必要なツール

- [sdkman](https://sdkman.io/) - Java環境管理
- [google-cloud-sdk](https://cloud.google.com/sdk/downloads) - GCP CLI
- 各種ランタイム管理ツール (nvm, pyenv, rbenv)

## 📁 ディレクトリ構成

```tree
dotfile/
├── Taskfile.yml       # タスク定義（セットアップ自動化）
├── .zshenv           # XDG Base Directory設定
└── config/           # 各種設定ファイル
    ├── git/          # Git設定
    ├── npm/          # npm設定
    ├── vim/          # Vim設定
    └── zsh/          # Zsh設定
```

## 🔧 トラブルシューティング

### セットアップが失敗した場合

```sh
# 現在の状況を確認
task status

# 設定をクリーンアップして再実行
task clean
task setup
```

### 特定のツールのみ再インストール

```sh
# 主要ツールの再インストール
task install-core-tools

# oh-my-zshプラグインの再インストール
task setup-zsh-plugins
```
