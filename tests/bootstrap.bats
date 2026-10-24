#!/usr/bin/env bats
# bootstrap.sh のテスト。
# brew / nix / git / curl は tests/helpers/bootstrap-mocks のモックに差し替え、HOME と BREW_BIN / NIX_BIN を
# 一時ディレクトリへ向けて、導入済みのものを飛ばし足りないものだけ入れる分岐を見る

SCRIPT="$BATS_TEST_DIRNAME/../bootstrap.sh"
MOCKS="$BATS_TEST_DIRNAME/helpers/bootstrap-mocks"

setup() {
  export MOCK_LOG="$BATS_TEST_TMPDIR/calls.log"
  : > "$MOCK_LOG"

  FAKE_HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$FAKE_HOME"
  DOTFILE_DIR="$FAKE_HOME/src/github.com/usadamasa/dotfile"

  # 既定は「全部そろっている」状態。各テストで足りないものを消す
  export BREW_BIN="$BATS_TEST_TMPDIR/homebrew/bin/brew"
  export NIX_BIN="$BATS_TEST_TMPDIR/nix/bin/nix"
  mkdir -p "$(dirname "$BREW_BIN")" "$(dirname "$NIX_BIN")" "$BATS_TEST_TMPDIR/nix/etc/profile.d" "$DOTFILE_DIR/.git"
  cp "$MOCKS/brew" "$BREW_BIN"
  : > "$NIX_BIN"
  chmod +x "$NIX_BIN"
  : > "$BATS_TEST_TMPDIR/nix/etc/profile.d/nix-daemon.sh"
}

run_bootstrap() {
  HOME="$FAKE_HOME" PATH="$MOCKS:/usr/bin:/bin" run bash "$SCRIPT"
}

@test "構文が macOS 同梱の /bin/bash (3.2) で通る" {
  if [ ! -x /bin/bash ]; then
    skip "/bin/bash が無い"
  fi
  run /bin/bash -n "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "全部そろっていれば何も入れず、リポジトリで nix develop --command task setup を呼ぶ" {
  run_bootstrap
  [ "$status" -eq 0 ]

  run grep -c 'CALLED: curl' "$MOCK_LOG"
  [ "$output" = "0" ]
  run grep -c 'CALLED: git clone' "$MOCK_LOG"
  [ "$output" = "0" ]
  grep -Fxq "CALLED: nix develop --command task setup (pwd=$DOTFILE_DIR)" "$MOCK_LOG"
}

@test "clone 先が無ければ ghq の配置と同じパスへ git clone する" {
  rm -r "$DOTFILE_DIR"

  run_bootstrap
  [ "$status" -eq 0 ]

  grep -Fxq "CALLED: git clone https://github.com/usadamasa/dotfile.git $DOTFILE_DIR" "$MOCK_LOG"
  grep -Fxq "CALLED: nix develop --command task setup (pwd=$DOTFILE_DIR)" "$MOCK_LOG"
}

@test "Homebrew が無ければ公式インストーラを取得して実行する" {
  rm "$BREW_BIN"

  run_bootstrap
  [ "$status" -eq 0 ]

  grep -Fxq "CALLED: curl https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh" "$MOCK_LOG"
  # インストーラの後に shellenv を読む
  grep -Fxq "CALLED: brew shellenv" "$MOCK_LOG"
}

@test "Nix が無ければ Determinate Nix のインストーラを取得して実行する" {
  rm "$NIX_BIN"

  run_bootstrap
  [ "$status" -eq 0 ]

  grep -Fxq "CALLED: curl https://install.determinate.systems/nix" "$MOCK_LOG"
  grep -Fxq "CALLED: nix develop --command task setup (pwd=$DOTFILE_DIR)" "$MOCK_LOG"
}

@test "~/.zprofile に追記しない (config/zsh/.zprofile が brew shellenv を持つ)" {
  rm "$BREW_BIN"

  run_bootstrap
  [ "$status" -eq 0 ]

  [ ! -e "$FAKE_HOME/.zprofile" ]
}
