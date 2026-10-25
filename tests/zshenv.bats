#!/usr/bin/env bats
# .zshenv unit tests

setup() {
  DOTFILE_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  FAKE_HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$FAKE_HOME"
}

# 空の HOME で .zshenv を読み込み、指定した変数の値を出力する
source_zshenv_and_print() {
  HOME="$FAKE_HOME" zsh -f -c 'source "$1"; print -r -- "${(P)2}"' _ "$DOTFILE_DIR/.zshenv" "$1"
}

# =============================================================================
# sqlite
# =============================================================================

@test "SQLITE_HISTORY points to XDG_STATE_HOME" {
  run source_zshenv_and_print SQLITE_HISTORY

  [ "$status" -eq 0 ]
  [ "$output" = "$FAKE_HOME/.local/state/sqlite_history" ]
}

@test "SQLITE_HISTORY path is not created as a directory" {
  run source_zshenv_and_print SQLITE_HISTORY

  [ "$status" -eq 0 ]
  [ ! -d "$output" ]
}

@test "parent directory of SQLITE_HISTORY exists" {
  run source_zshenv_and_print SQLITE_HISTORY

  [ "$status" -eq 0 ]
  [ -d "$(dirname "$output")" ]
}

# =============================================================================
# ZDOTDIR を引き継いだ子シェル
# =============================================================================

# 親が export した ZDOTDIR と古い値を引き継いだ zsh を起動し、指定した式の値を出力する
run_child_zsh() {
  ln -s "$DOTFILE_DIR/.zshenv" "$FAKE_HOME/.zshenv"
  HOME="$FAKE_HOME" ZDOTDIR="$DOTFILE_DIR/config/zsh" SQLITE_HISTORY=stale \
    PATH="$FAKE_HOME/.local/bin:$PATH" zsh -c "print -r -- $1"
}

@test "ZDOTDIR を引き継いだ子シェルでも .zshenv が読まれる" {
  run run_child_zsh '$SQLITE_HISTORY'

  [ "$status" -eq 0 ]
  [ "$output" = "$FAKE_HOME/.local/state/sqlite_history" ]
}

@test "子シェルで .zshenv を読み直しても PATH に ~/.local/bin が重ならない" {
  run run_child_zsh '${#${(M)path:#$HOME/.local/bin}}'

  [ "$status" -eq 0 ]
  [ "$output" = "1" ]
}
