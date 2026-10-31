# dotfiles

macOS の開発環境を組む dotfiles。セットアップの手順は [go-task](https://taskfile.dev/) の task にまとめてある。
日常使いのパッケージと設定ファイルの配置は [home-manager](https://nix-community.github.io/home-manager/) が担い、
このリポジトリの開発ツールは [Nix](https://nixos.org/) の devShell に置く。
[Homebrew](https://brew.sh/) で入れるものは [Brewfile](Brewfile) に並べる。

## 🚀 セットアップ

新しい Mac では、何も入れずに次の 1 行を流す (Homebrew・Nix のインストールに sudo のパスワードを求められる)。
[bootstrap.sh](bootstrap.sh) が Homebrew と Determinate Nix を入れ、
`~/src/github.com/usadamasa/dotfile` へ clone し、devShell の task で `task setup` を実行する。
導入済みのものは飛ばすので、途中で止まっても打ち直せる。

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/usadamasa/dotfile/main/bootstrap.sh)"
```

終わったら新しいターミナルを開き、リポジトリで `direnv allow` する。以後は `task` が使える。

```sh
cd ~/src/github.com/usadamasa/dotfile
direnv allow
task status   # セットアップ状況確認
```

## 📋 コマンド

```sh
task                  # タスク一覧表示
task setup            # 完全セットアップ (導入済みのマシンで設定を収束させる)
task status           # 状況確認
task test             # bats でシェルスクリプトのテストを実行
task lint             # yamllint で YAML を検査
task format           # editorconfig-checker でチェック
task nix:check-flake  # flake.nix の devShell を検証
task nix:update       # flake.lock の nixpkgs を更新
task nix:install-custom-conf  # config/nix/nix.custom.conf を /etc/nix へ配置 (sudo)
task hm:switch        # home-manager の設定をビルドして適用
task hm:check         # home-manager の設定を全ユーザー分評価だけする (CI が使う)
```

flake.lock は Dependabot ([.github/dependabot.yml](.github/dependabot.yml)) も週次で更新する。

## 🛠️ ツールの管理

### Homebrew

一覧は [Brewfile](Brewfile)。`task setup` が `brew bundle install` で入れる。

### Nix

[Determinate Nix](https://determinate.systems/) を入れ、設定は [config/nix/nix.custom.conf](config/nix/nix.custom.conf) に置く。

- **devShell**: このリポジトリのテストと lint のツール。[flake.nix](flake.nix) に置き、direnv が読み込む。
- **home-manager**: 日常使いのパッケージと設定ファイル。モジュールは [home/](home/)、適用は `task hm:switch`。

## 📁 構成

```tree
dotfile/
├── bootstrap.sh  # 新しい Mac の初回セットアップ (curl で取得して実行する)
├── Brewfile      # Homebrew で入れるツール
├── Taskfile.yml  # セットアップ自動化
├── flake.nix     # 開発ツールの devShell と homeConfigurations
├── home/         # home-manager のモジュールと switch.sh / status.sh
├── config/       # 各種設定ファイル
└── tests/        # bats のテスト
```
