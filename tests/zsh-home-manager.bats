#!/usr/bin/env bats
# home-manager の programs.zsh が生成する zsh 設定を、偽の HOME で起動して確かめる。
# 生成物は tests/helpers/build-hm-fake-home.sh (task test:hm) が先にビルドする。
# homeConfigurations は aarch64-darwin 向けで、CI の linux ではビルドしないので skip する

setup_file() {
  local dotfile_dir
  dotfile_dir="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  export HM_RESULT="$dotfile_dir/tmp/hm-fake-home/result"
  export FAKE_HOME="$dotfile_dir/tmp/hm-fake-home/home"
  if [ ! -d "$HM_RESULT" ]; then
    return 0
  fi
  # activation の代わりに zsh の設定だけを張る。~/.config/zsh はディレクトリごと生成物へ向ける
  # (Claude Code の sandbox は .zshrc / .zprofile という名前のファイルを作らせない)
  if [ -d "$FAKE_HOME" ]; then
    chmod -R u+w "$FAKE_HOME"
    rm -rf "$FAKE_HOME"
  fi
  mkdir -p "$FAKE_HOME/.config" "$FAKE_HOME/.cache/oh-my-zsh" "$FAKE_HOME/.local/state"
  ln -s "$HM_RESULT/home-files/.zshenv" "$FAKE_HOME/.zshenv"
  ln -s "$HM_RESULT/home-files/.config/zsh" "$FAKE_HOME/.config/zsh"
}

setup() {
  if [ ! -d "$HM_RESULT" ]; then
    skip "生成物が無い (task test:hm でビルドする)"
  fi
}

# 端末アプリが起動するのと同じく、親の環境を持ち込まずにログインシェルを起動し、式の値を最後の行に出す
run_login_zsh() {
  run env -i HOME="$FAKE_HOME" USER="${USER:-test}" TERM=dumb \
    PATH="/usr/bin:/bin:/usr/sbin:/sbin:$HM_RESULT/home-path/bin" \
    "$HM_RESULT/home-path/bin/zsh" -l -i -c "print -r -- \"$1\""
  # 失敗したときに起動時のエラーを読めるよう、出力をそのまま bats に渡す
  printf '%s\n' "$output"
  last_line=
  if [ "${#lines[@]}" -gt 0 ]; then
    last_line="${lines[${#lines[@]}-1]}"
  fi
}

@test "ZDOTDIR が ~/.config/zsh になる" {
  run_login_zsh '$ZDOTDIR'

  [ "$status" -eq 0 ]
  [ "$last_line" = "$FAKE_HOME/.config/zsh" ]
}

@test "oh-my-zsh を nix store から読む" {
  run_login_zsh '$ZSH'

  [ "$status" -eq 0 ]
  [[ "$last_line" == /nix/store/* ]]
}

@test "home.sessionVariables の値が入る (SQLITE_HISTORY)" {
  run_login_zsh '$SQLITE_HISTORY'

  [ "$status" -eq 0 ]
  [ "$last_line" = "$FAKE_HOME/.local/state/sqlite_history" ]
}

@test "PATH に ~/.local/bin が 1 回だけ入る" {
  run_login_zsh '${#${(@M)path:#$HOME/.local/bin}}'

  [ "$status" -eq 0 ]
  [ "$last_line" = "1" ]
}

@test "HISTFILE が XDG_STATE_HOME 配下になる" {
  run_login_zsh '$HISTFILE'

  [ "$status" -eq 0 ]
  [ "$last_line" = "$FAKE_HOME/.local/state/zsh/history" ]
}

@test "history の setopt が移行前と同じになる" {
  run_login_zsh '${(j: :)${(f)"$(setopt | grep -iE "hist|share|append")"}}'

  [ "$status" -eq 0 ]
  [ "$last_line" = "extendedhistory histexpiredupsfirst histignorealldups histignoredups histignorespace histnostore histreduceblanks histsavenodups histverify incappendhistory sharehistory" ]
}

@test "補完のダンプを XDG_CACHE_HOME 配下に書き、ZDOTDIR に書かない" {
  run_login_zsh '$ZSH_COMPDUMP'

  [ "$status" -eq 0 ]
  [[ "$last_line" == "$FAKE_HOME/.cache/zsh/"* ]]
  ! compgen -G "$FAKE_HOME/.config/zsh/.zcompdump*"
}

@test "補完が読み込まれる" {
  run_login_zsh '${+_comps[git]}'

  [ "$status" -eq 0 ]
  [ "$last_line" = "1" ]
}

@test "direnv の hook が 1 つだけ張られる" {
  run_login_zsh '${#${(@M)precmd_functions:#_direnv_hook}}'

  [ "$status" -eq 0 ]
  [ "$last_line" = "1" ]
}

@test "ZLE の plugin (autosuggestions と syntax-highlighting) が読み込まれる" {
  run_login_zsh '${+functions[_zsh_autosuggest_start]} ${+ZSH_HIGHLIGHT_VERSION}'

  [ "$status" -eq 0 ]
  [ "$last_line" = "1 1" ]
}
