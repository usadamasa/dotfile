# shellcheck shell=bash
# shellcheck disable=SC2154
# go-task の補完。
# task は direnv の devShell で版が切り替わり、`task --completion zsh` の出す方式も版ごとに違う
# (新しい版は `task __complete` を呼ぶ)。oh-my-zsh の task plugin は起動時に一度だけ生成してキャッシュするので、
# direnv が PATH を変えた後は別の版の補完が残って壊れる。
# 補完を呼んだ時点の task から生成し、task の実体が変わったときだけ作り直す。
_task_follow_path() {
  local bin=${commands[task]}
  [[ -n "$bin" ]] || return 1
  if [[ "$bin" != "${_task_completion_bin-}" ]]; then
    eval "$(task --completion zsh)"
    typeset -g _task_completion_bin="$bin"
    # 生成したスクリプトが compdef _task task で差し替えるので戻す
    compdef _task_follow_path task
  fi
  _task "$@"
}
compdef _task_follow_path task
