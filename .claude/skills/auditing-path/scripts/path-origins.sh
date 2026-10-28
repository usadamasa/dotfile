#!/usr/bin/env bash
# ログインシェルを zsh -x で起動し、PATH の entry ごとに最初に足した file:line を出す。
# clean は環境を持ち込まない新しい端末、nested は今の環境から入れ子で起動した zsh -l に当たる
set -euo pipefail

readonly TAB=$'\t'
# shellcheck disable=SC2016 # $PATH は起動した zsh の中で展開する
readonly PRINT_PATH='print -r -- "@@PATH=$PATH"'
# 端末アプリが launchd から受け取る PATH
readonly LAUNCHD_PATH=/usr/bin:/bin:/usr/sbin:/sbin

initial_path() {
  case $1 in
    clean) printf '%s' "$LAUNCHD_PATH" ;;
    nested) printf '%s' "$PATH" ;;
  esac
}

trace() {
  local mode=$1
  case $mode in
    clean) env -i HOME="$HOME" USER="$USER" LOGNAME="${LOGNAME:-$USER}" TERM="${TERM:-xterm-256color}" \
      PATH="$LAUNCHD_PATH" PS4='+%x:%I> ' /bin/zsh -l -i -x -c "$PRINT_PATH" 2>&1 ;;
    nested) PS4='+%x:%I> ' /bin/zsh -l -i -x -c "$PRINT_PATH" 2>&1 ;;
    *)
      printf 'mode は clean か nested: %s\n' "$mode" >&2
      return 1 ;;
  esac
}

# macOS の /bin/bash (3.2) でも動くよう、連想配列でなく「entry<TAB>origin」の行で持つ
origin_of() {
  local entry=$1 origins=$2 row
  while IFS= read -r row; do
    if [ "${row%%"$TAB"*}" = "$entry" ]; then
      printf '%s' "${row#*"$TAB"}"
      return 0
    fi
  done <<<"$origins"
  return 1
}

report() {
  local mode=$1 out line origin value entry final origins
  local -a entries
  if ! out=$(trace "$mode"); then
    printf '%s: zsh の起動に失敗\n' "$mode" >&2
    return 1
  fi

  final=
  origins=
  IFS=: read -r -a entries <<<"$(initial_path "$mode")"
  for entry in "${entries[@]}"; do
    [ -n "$entry" ] && origins+="$entry$TAB(起動前の環境)"$'\n'
  done
  while IFS= read -r line; do
    case $line in
      @@PATH=*) final=${line#@@PATH=}; continue ;;
    esac
    # +<file>:<line>> [export ]PATH=<value> の行だけを見る
    if [[ $line =~ ^\+(.+:[0-9]+)\>\ (export\ )?PATH=(.*)$ ]]; then
      origin=${BASH_REMATCH[1]}
      value=${BASH_REMATCH[3]%% }
      value=${value#\'}
      value=${value%\'}
      IFS=: read -r -a entries <<<"$value"
      for entry in "${entries[@]}"; do
        if [ -n "$entry" ] && ! origin_of "$entry" "$origins" >/dev/null; then
          origins+="$entry$TAB$origin"$'\n'
        fi
      done
    fi
  done <<<"$out"

  if [ -z "$final" ]; then
    printf '%s: 最終の PATH を取れなかった\n' "$mode" >&2
    return 1
  fi

  printf '## %s\n' "$mode"
  local i=0
  IFS=: read -r -a entries <<<"$final"
  for entry in "${entries[@]}"; do
    i=$((i + 1))
    if ! origin=$(origin_of "$entry" "$origins"); then
      origin='(不明)'
    fi
    if [ -d "$entry" ]; then
      printf '%d%s%s%s%s\n' "$i" "$TAB" "$entry" "$TAB" "$origin"
    else
      printf '%d%s%s%s%s%s(存在しない)\n' "$i" "$TAB" "$entry" "$TAB" "$origin" "$TAB"
    fi
  done
}

report clean
report nested
