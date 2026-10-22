#!/usr/bin/env bash
# 適用済みの home-manager の世代が、flake が今指す世代と同じ store path かを出す。
# home-manager に status に当たるコマンドは無いので、activationPackage の outPath (評価だけでビルドしない) と
# profile の実体を比べる。一致すれば home-manager 管理の設定ファイルとパッケージはすべて配置済み
set -euo pipefail

cd "$(dirname "$0")/.."

profile="${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles/home-manager"
if [ ! -L "$profile" ]; then
  printf 'home-manager: ✗ (未適用。task hm:switch で適用する)\n'
  exit 0
fi
generation=$(readlink "$profile")
active=$(readlink -f "$profile")

if ! wanted=$(nix eval --raw ".#homeConfigurations.${USER:?}.activationPackage"); then
  printf 'home-manager: ✗ (flake の評価に失敗)\n'
  exit 1
fi

if [ "$active" = "$wanted" ]; then
  printf 'home-manager: ✓ (%s が flake と一致)\n' "$generation"
else
  printf 'home-manager: ✗ (%s が flake と違う。task hm:switch で合わせる)\n' "$generation"
fi
