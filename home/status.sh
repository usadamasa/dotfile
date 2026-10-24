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

# 世代が一致していても、PATH の並びが崩れている (config/zsh/.zprofile を経ていないシェル、macOS 同梱や
# brew の版が前に来る) と別の実体が使われる。home-manager が入れた各コマンドの解決先を見る。
# direnv が読み込む devShell は /nix/store/… の bin (stdenv の bash など) と .direnv/bin を先頭に足すが、
# これはリポジトリの中だけの並びなので外し、ログインシェルと同じ PATH で引く
login_path=
rest="$PATH:"
while [ -n "$rest" ]; do
  entry=${rest%%:*}
  rest=${rest#*:}
  case $entry in
    /nix/store/* | */.direnv/bin) continue ;;
  esac
  login_path="${login_path:+$login_path:}$entry"
done

profile_bin="${XDG_STATE_HOME:-$HOME/.local/state}/nix/profile/bin"
shadowed=()
count=0
for path in "$active"/home-path/bin/*; do
  name=$(basename "$path")
  count=$((count + 1))
  if ! found=$(PATH="$login_path" command -v "$name"); then
    shadowed+=("$name は PATH に無い")
  elif [ "$found" != "$profile_bin/$name" ]; then
    shadowed+=("$name が $found")
  fi
done

if [ "${#shadowed[@]}" -eq 0 ]; then
  printf 'home-manager の PATH: ✓ (%d コマンドが nix の profile を指す)\n' "$count"
else
  printf 'home-manager の PATH: ✗ (%s。新しいログインシェルで確かめるか PATH の並びを見直す)\n' "$(IFS='、'; printf '%s' "${shadowed[*]}")"
fi
