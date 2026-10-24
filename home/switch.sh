#!/usr/bin/env bash
# home-manager の設定をビルドして適用する。
# `nix run home-manager -- switch` は claude-config の guard-bash が止めるため、flake の packages に置いた
# home-manager CLI をビルドし、その `switch --flake .` を呼ぶ。CLI は $USER の homeConfigurations を選ぶ。
# 初回も 2 回目以降も同じ経路
set -euo pipefail

# 新しいマシンの task setup (bootstrap.sh から) は .zshenv を経ていないので、nix が PATH に無いことも
# XDG_STATE_HOME が未設定のこともある。CLI は PATH の nix を呼び、世代の置き場を XDG_STATE_HOME から決める
if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

cd "$(dirname "$0")/.."

if ! hm=$(nix build --no-link --print-out-paths .#home-manager); then
  printf 'home-manager CLI のビルドに失敗した\n' >&2
  exit 1
fi
"$hm/bin/home-manager" switch --flake .
