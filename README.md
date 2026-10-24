# dotfiles

macOS 開発環境用の dotfiles リポジトリです。[go-task](https://taskfile.dev/) でセットアップを自動化し、
日常使いのツールは [Homebrew](https://brew.sh/)、このリポジトリの開発ツールは [Nix](https://nixos.org/) の devShell で管理します。
ホーム環境 (パッケージと設定ファイルの配置) は [home-manager](https://nix-community.github.io/home-manager/) へ
段階的に移しています ([#105](https://github.com/usadamasa/dotfile/issues/105))。

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
task format           # editorconfig-checker でチェック
task nix:check-flake  # flake.nix の devShell を検証
task nix:update       # flake.lock の nixpkgs を更新
task nix:install-custom-conf  # config/nix/nix.custom.conf を /etc/nix へ配置 (sudo)
task hm:switch        # home-manager の設定をビルドして適用
task hm:check         # home-manager の設定を全ユーザー分評価だけする (CI が使う)
```

flake.lock は Dependabot ([.github/dependabot.yml](.github/dependabot.yml)) も週次で更新する。

## 🛠️ ツールの管理

- **Homebrew**: 日常使いのツールとフォント。一覧は [Brewfile](Brewfile)。
- **Nix**: [Determinate Nix](https://determinate.systems/) を入れ、このリポジトリのテストと lint のツールを
  [flake.nix](flake.nix) の devShell に置く。direnv (`.envrc` の `use flake`) がリポジトリに入ったときに読み込む。
  nix の設定は `/etc/nix/nix.conf` を Determinate Nix が管理するので、
  [config/nix/nix.custom.conf](config/nix/nix.custom.conf) を `/etc/nix/nix.custom.conf` へコピーして
  `!include` させる (`task nix:install-custom-conf`)。
- **home-manager**: `flake.nix` の `homeConfigurations.<ユーザー名>` を [home/](home/) のモジュールで組む
  (端末ごとのユーザー名は `flake.nix` の `users` に並べる)。
  設定ファイルは `mkOutOfStoreSymlink` でリポジトリの作業ツリーへ symlink する (編集が即反映される)。
  適用は `task hm:switch` (`home/switch.sh` が flake の `home-manager` CLI をビルドして `switch --flake .` を呼ぶ)。
  世代の確認と戻しは profile に入る `home-manager generations` / `home-manager switch --rollback`。

## 📁 構成

```tree
dotfile/
├── bootstrap.sh  # 新しい Mac の初回セットアップ (curl で取得して実行する)
├── Brewfile      # Homebrew で入れるツール
├── Taskfile.yml  # セットアップ自動化
├── flake.nix     # 開発ツールの devShell と homeConfigurations
├── .zshenv       # XDG Base Directory 設定
├── home/         # home-manager のモジュールと switch.sh / status.sh
├── config/       # 各種設定ファイル
│   ├── direnv/
│   ├── git/
│   ├── nix/      # nix.custom.conf (/etc/nix へコピーする) と nix 関連の task
│   ├── npm/
│   ├── vim/
│   └── zsh/
└── tests/        # bats のテスト
```
