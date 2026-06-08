#!/usr/bin/env bash
# PostToolUse(Edit/Write) フック。
# 編集されたシェルスクリプトに shellcheck と editorconfig-checker をかける。
set -euo pipefail

file="$(jq -r '.tool_input.file_path // empty')"
[ -f "$file" ] || exit 0

case "$file" in
  *.bats) exit 0 ;;
  *.sh | *.bash | *.zsh) ;;
  *) case "$(head -n 1 "$file")" in '#!'*sh*) ;; *) exit 0 ;; esac ;;
esac

shellcheck "$file" >&2 && editorconfig-checker "$file" >&2 || exit 2
