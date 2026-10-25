#!/usr/bin/env bats
# home/check-dir-links.sh のテスト。
# 新しい generation の home-files と HOME を BATS_TEST_TMPDIR に組む。
# 実物の $newGenPath/home-files は store のディレクトリを指す symlink なので、fixture も同じ形にする

SCRIPT="$BATS_TEST_DIRNAME/../home/check-dir-links.sh"

setup() {
  GEN="$BATS_TEST_TMPDIR/gen"
  mkdir -p "$GEN/files/.config/zsh"
  ln -s /nix/store/new-hm_zshrc "$GEN/files/.config/zsh/.zshrc"
  # mkOutOfStoreSymlink で張るディレクトリは home-files の中でも symlink になる
  ln -s /nix/store/new-hm_git "$GEN/files/.config/git"
  ln -s "$GEN/files" "$GEN/home-files"

  HOME_DIR="$BATS_TEST_TMPDIR/home"
  mkdir -p "$HOME_DIR/.config"
}

@test "ファイル単位で張るパスの親が store を指す symlink なら、消し方を示して失敗する" {
  # 古い generation を GC した後はリンク先が無いので、dangling の symlink で組む
  ln -s /nix/store/old-home-manager-files/.config/zsh "$HOME_DIR/.config/zsh"

  run bash "$SCRIPT" "$GEN/home-files" "$HOME_DIR"

  [ "$status" -eq 1 ]
  [[ "$output" == *"$HOME_DIR/.config/zsh"* ]]
  [[ "$output" == *"rm -- '$HOME_DIR/.config/zsh'"* ]]
}

@test "親がディレクトリなら成功する" {
  mkdir "$HOME_DIR/.config/zsh"
  ln -s /nix/store/old-home-manager-files/.config/zsh/.zshrc "$HOME_DIR/.config/zsh/.zshrc"

  run bash "$SCRIPT" "$GEN/home-files" "$HOME_DIR"

  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "ディレクトリごと張るパス自体が store を指す symlink でも成功する" {
  # ~/.config/git -> 古い generation は home-manager が張り替える通常の状態
  mkdir "$HOME_DIR/.config/zsh"
  ln -s /nix/store/old-home-manager-files/.config/git "$HOME_DIR/.config/git"

  run bash "$SCRIPT" "$GEN/home-files" "$HOME_DIR"

  [ "$status" -eq 0 ]
}

@test "親が store の外を指す symlink なら成功する" {
  mkdir "$BATS_TEST_TMPDIR/elsewhere"
  ln -s "$BATS_TEST_TMPDIR/elsewhere" "$HOME_DIR/.config/zsh"

  run bash "$SCRIPT" "$GEN/home-files" "$HOME_DIR"

  [ "$status" -eq 0 ]
}

@test "引数が絶対パスでなければ使い方の誤りとして失敗する" {
  run bash "$SCRIPT" gen/home-files "$HOME_DIR"
  [ "$status" -eq 2 ]

  run bash "$SCRIPT" "$GEN/home-files" home
  [ "$status" -eq 2 ]

  run bash "$SCRIPT" "$GEN/home-files"
  [ "$status" -eq 2 ]
}
