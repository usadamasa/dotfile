#!/usr/bin/env bash
# PostToolUse(Edit/Write) フック。
# 編集されたシェルスクリプトを静的解析し、指摘を Claude に返す。
# 使用ツール: shellcheck / editorconfig-checker
set -euo pipefail

input="$(cat)"
file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')"

[ -n "$file_path" ] || exit 0
[ -f "$file_path" ] || exit 0

# シェルスクリプト判定 (.bats は bats でテストするため除外)
is_shell=false
case "$file_path" in
  *.bats) exit 0 ;;
  *.sh | *.bash | *.zsh) is_shell=true ;;
  *)
    first_line="$(head -n 1 "$file_path" 2>/dev/null || true)"
    case "$first_line" in
      '#!'*sh*) is_shell=true ;;
    esac
    ;;
esac
"$is_shell" || exit 0

findings=""

if ! command -v shellcheck >/dev/null 2>&1; then
  findings+="shellcheck が未インストール (brew install shellcheck)"$'\n'
elif ! sc_out="$(shellcheck "$file_path" 2>&1)"; then
  findings+="[shellcheck]"$'\n'"$sc_out"$'\n'
fi

if ! command -v editorconfig-checker >/dev/null 2>&1; then
  findings+="editorconfig-checker が未インストール (brew install editorconfig-checker)"$'\n'
elif ! ec_out="$(editorconfig-checker "$file_path" 2>&1)"; then
  findings+="[editorconfig-checker]"$'\n'"$ec_out"$'\n'
fi

if [ -n "$findings" ]; then
  printf 'lint 指摘 (%s):\n%s' "$file_path" "$findings" >&2
  exit 2
fi

exit 0
