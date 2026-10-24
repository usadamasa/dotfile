#!/usr/bin/env bash
# 新しい Mac の初回セットアップ。何も入っていない状態から次の 1 行で流す。
#
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/usadamasa/dotfile/main/bootstrap.sh)"
#
# `curl | bash` ではなく `bash -c "$(curl …)"` にしてあるので、stdin は端末のまま残り、
# Homebrew と Nix のインストーラが sudo のパスワードや確認を読める。途中までの取得で実行が始まることもない。
# macOS 同梱の bash (3.2) で動く構文だけを使う。
#
# ここでやるのは devShell の task が使えるようになるまで (Homebrew、Nix、clone)。残りは task setup に任せる。
# 導入済みのものは飛ばすので、途中で止まっても打ち直せる
set -euo pipefail

# テストから差し替えるために変数にしてある (tests/bootstrap.bats)
BREW_BIN="${BREW_BIN:-/opt/homebrew/bin/brew}"
NIX_BIN="${NIX_BIN:-/nix/var/nix/profiles/default/bin/nix}"
DOTFILE_DIR="$HOME/src/github.com/usadamasa/dotfile"
DOTFILE_URL="https://github.com/usadamasa/dotfile.git"

step() {
  printf '\n==> %s\n' "$1"
}

# Homebrew のインストーラが Xcode Command Line Tools も入れるので、clone に使う git はここで手に入る。
# シェルの設定への追記はしない (config/zsh/.zprofile が brew shellenv を持つ)
if [ ! -x "$BREW_BIN" ]; then
  step "Homebrew をインストールする (sudo のパスワードを求められる)"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$("$BREW_BIN" shellenv)"

# /etc/nix/nix.conf は Determinate Nix が管理する。設定は task setup が /etc/nix/nix.custom.conf へ置く
if [ ! -x "$NIX_BIN" ]; then
  step "Determinate Nix をインストールする (sudo のパスワードを求められる)"
  curl -fsSL https://install.determinate.systems/nix | sh -s -- install
fi
# shellcheck disable=SC1091
. "${NIX_BIN%/bin/nix}/etc/profile.d/nix-daemon.sh"

# ghq の配置 (ghq.root = ~/src) と同じパスへ置く。ghq 自体は home-manager で入るので、clone は git で行う
if [ ! -d "$DOTFILE_DIR/.git" ]; then
  step "dotfile を $DOTFILE_DIR へ clone する"
  git clone "$DOTFILE_URL" "$DOTFILE_DIR"
fi

# task はリポジトリの devShell (flake.nix) にある。direnv はまだ無いので nix develop で呼ぶ
step "task setup を実行する"
cd "$DOTFILE_DIR"
nix develop --command task setup

step "完了。新しいターミナルを開き、$DOTFILE_DIR で direnv allow を実行する"
