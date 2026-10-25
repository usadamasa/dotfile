#!/usr/bin/env bats
# .zshenv unit tests

setup() {
  DOTFILE_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  FAKE_HOME="$BATS_TEST_TMPDIR/home"
  # home/files.nix と同じく ~/.zshenv と ~/.config/zsh をリポジトリへ張る
  mkdir -p "$FAKE_HOME/.config"
  ln -s "$DOTFILE_DIR/.zshenv" "$FAKE_HOME/.zshenv"
  ln -s "$DOTFILE_DIR/config/zsh" "$FAKE_HOME/.config/zsh"
}

# ZDOTDIR の無い (端末アプリが起動した) zsh で、指定した式の値を出力する
run_fresh_zsh() {
  (
    unset ZDOTDIR
    HOME="$FAKE_HOME" zsh -c "print -r -- $1"
  )
}

# 親が export した ZDOTDIR と古い値を引き継いだ zsh で、指定した式の値を出力する
run_child_zsh() {
  HOME="$FAKE_HOME" ZDOTDIR="$FAKE_HOME/.config/zsh" SQLITE_HISTORY=stale \
    PATH="$FAKE_HOME/.local/bin:$PATH" zsh -c "print -r -- $1"
}

# =============================================================================
# ZDOTDIR
# =============================================================================

@test "ZDOTDIR の無い zsh で ZDOTDIR が ~/.config/zsh になる" {
  run run_fresh_zsh '$ZDOTDIR'

  [ "$status" -eq 0 ]
  [ "$output" = "$FAKE_HOME/.config/zsh" ]
}

# =============================================================================
# sqlite
# =============================================================================

@test "SQLITE_HISTORY points to XDG_STATE_HOME" {
  run run_fresh_zsh '$SQLITE_HISTORY'

  [ "$status" -eq 0 ]
  [ "$output" = "$FAKE_HOME/.local/state/sqlite_history" ]
}

@test "SQLITE_HISTORY path is not created as a directory" {
  run run_fresh_zsh '$SQLITE_HISTORY'

  [ "$status" -eq 0 ]
  [ ! -d "$output" ]
}

@test "parent directory of SQLITE_HISTORY exists" {
  run run_fresh_zsh '$SQLITE_HISTORY'

  [ "$status" -eq 0 ]
  [ -d "$(dirname "$output")" ]
}

# =============================================================================
# ZDOTDIR を引き継いだ子シェル
# =============================================================================

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
