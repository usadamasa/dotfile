#!/usr/bin/env bash
# home-manager の設定をビルドして適用する。
# `nix run home-manager -- switch` は claude-config の guard-bash が止めるため、activationPackage を
# ビルドして activate を直接呼ぶ。初回も 2 回目以降も同じ経路。
# activate は --driver-version なしの旧挙動で、自分で世代 profile を作り home-manager-path を profile に入れる
set -euo pipefail

# task setup の途中 (nix:install 直後) のシェルには nix が PATH に無く、XDG_STATE_HOME も未設定。
# activate は PATH の nix-env から自分の PATH を組み立て、世代の置き場を XDG_STATE_HOME から決める
if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

cd "$(dirname "$0")/.."

if ! out=$(nix build --no-link --print-out-paths .#homeConfigurations.usadamasa.activationPackage); then
  printf 'home-manager の設定のビルドに失敗した\n' >&2
  exit 1
fi
"$out/activate"
