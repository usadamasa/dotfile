#!/usr/bin/env bash
# 新しい generation が中のファイル単位でリンクを張るディレクトリについて、HOME 側が nix store を指す symlink のまま
# 残っていないかを調べる。home-manager の activation から checkLinkTargets の前に呼ぶ。
# checkLinkTargets はこの symlink を衝突として扱わず、symlink の先にファイルを作って switch を終えてしまう
#
# 使い方: check-dir-links.sh <home-files> <home>
set -euo pipefail

if [ "$#" -ne 2 ] || [[ "$1" != /* ]] || [[ "$2" != /* ]]; then
  printf '使い方: %s <home-files の絶対パス> <home の絶対パス>\n' "$0" >&2
  exit 2
fi
home_files=$1
home=$2
readonly home_files home

stale=()
# home-files 自体が store のディレクトリを指す symlink なので -H でたどる。
# ディレクトリごと張るパスは home-files の中でも symlink なので -type d に掛からない
while IFS= read -r -d '' dir; do
  target="$home/${dir#"$home_files"/}"
  # 1 段目だけを見る。たどりきると古い generation を経たリポジトリのパスになり、store かどうか分からない
  if [ -L "$target" ] && [[ "$(readlink "$target")" == /nix/store/* ]]; then
    stale+=("$target")
  fi
done < <(find -H "$home_files" -mindepth 1 -type d -print0)

if [ "${#stale[@]}" -eq 0 ]; then
  exit 0
fi

printf '古い generation がディレクトリごと張った symlink が残っている。\n' >&2
printf 'このまま switch すると symlink の先にファイルが作られ、古い generation の GC でリンクが切れる。\n' >&2
printf 'symlink だけを消してから switch し直す (-r も末尾の / も付けない)。\n\n' >&2
for target in "${stale[@]}"; do
  printf "  rm -- '%s'\n" "$target" >&2
done
exit 1
