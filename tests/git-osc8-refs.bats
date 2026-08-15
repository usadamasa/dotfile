#!/usr/bin/env bats
# git-osc8-refs スクリプトのテスト
# issue / PR 参照の OSC 8 変換、誤検出の抑止、リンク先を解決できない場合の
# 素通しを、通常リポジトリ / bare / worktree の各コンテキストで検証する

SCRIPT="$BATS_TEST_DIRNAME/../config/git/git-osc8-refs"
GIT_CONFIG_FILE="$BATS_TEST_DIRNAME/../config/git/config"

setup() {
  ORIG_DIR="$PWD"
  REPO="$BATS_TEST_TMPDIR/repo"
  git init -q -b main "$REPO"
  git -C "$REPO" remote add origin git@github.com:usadamasa/dotfile.git
  git -C "$REPO" config user.email "test@example.com"
  git -C "$REPO" config user.name "Test User"
  cd "$REPO" || return 1
  unset GIT_OSC8_REFS_BASE
}

teardown() {
  cd "$ORIG_DIR" || return 0
}

# OSC 8 でリンク化されたテキストを組み立てる
# $1: リンク先 URL / $2: 表示テキスト
osc8() {
  printf '\e]8;;%s\e\\%s\e]8;;\e\\' "$1" "$2"
}

# =============================================================================
# 構文チェック
# =============================================================================

@test "スクリプトの構文が正しい" {
  run bash -n "$SCRIPT"
  [ "$status" -eq 0 ]
}

# =============================================================================
# 変換される入力
# =============================================================================

@test "PR 参照 #87 が OSC 8 リンクになる" {
  run bash "$SCRIPT" <<< 'Merge pull request #87 from usadamasa/x'

  [ "$status" -eq 0 ]
  link=$(osc8 'https://github.com/usadamasa/dotfile/issues/87' '#87')
  [ "$output" = "Merge pull request $link from usadamasa/x" ]
}

@test "カッコで囲まれた (#1234) も変換される" {
  run bash "$SCRIPT" <<< 'fix something (#1234).'

  [ "$status" -eq 0 ]
  link=$(osc8 'https://github.com/usadamasa/dotfile/issues/1234' '#1234')
  [ "$output" = "fix something ($link)." ]
}

@test "行頭の #5 も変換される" {
  run bash "$SCRIPT" <<< '#5 is done'

  [ "$status" -eq 0 ]
  link=$(osc8 'https://github.com/usadamasa/dotfile/issues/5' '#5')
  [ "$output" = "$link is done" ]
}

@test "ANSI SGR シーケンス直後の #7 も変換される" {
  run bash "$SCRIPT" <<< "$(printf '\e[33m#7\e[m')"

  [ "$status" -eq 0 ]
  link=$(osc8 'https://github.com/usadamasa/dotfile/issues/7' '#7')
  [ "$output" = "$(printf '\e[33m')$link$(printf '\e[m')" ]
}

@test "1 行に複数ある参照がすべて変換される" {
  run bash "$SCRIPT" <<< 'closes #1 and #2'

  [ "$status" -eq 0 ]
  one=$(osc8 'https://github.com/usadamasa/dotfile/issues/1' '#1')
  two=$(osc8 'https://github.com/usadamasa/dotfile/issues/2' '#2')
  [ "$output" = "closes $one and $two" ]
}

# =============================================================================
# 変換してはいけない入力
# =============================================================================

@test "16 進カラー #42abcd は変換しない" {
  run bash "$SCRIPT" <<< 'color: #42abcd;'

  [ "$status" -eq 0 ]
  [ "$output" = 'color: #42abcd;' ]
}

@test "別リポジトリ参照 owner/repo#99 は変換しない" {
  run bash "$SCRIPT" <<< 'see usadamasa/other#99'

  [ "$status" -eq 0 ]
  [ "$output" = 'see usadamasa/other#99' ]
}

@test "番号を伴わない # は変換しない" {
  run bash "$SCRIPT" <<< '# コメント行'

  [ "$status" -eq 0 ]
  [ "$output" = '# コメント行' ]
}

# =============================================================================
# リンク先の解決
# =============================================================================

@test "https 形式のリモート URL を正規化する" {
  git remote set-url origin https://github.com/usadamasa/dotfile.git
  run bash "$SCRIPT" <<< 'see #3'

  [ "$status" -eq 0 ]
  link=$(osc8 'https://github.com/usadamasa/dotfile/issues/3' '#3')
  [ "$output" = "see $link" ]
}

@test "ssh:// 形式のリモート URL を正規化する" {
  git remote set-url origin ssh://git@github.com/usadamasa/dotfile.git
  run bash "$SCRIPT" <<< 'see #3'

  [ "$status" -eq 0 ]
  link=$(osc8 'https://github.com/usadamasa/dotfile/issues/3' '#3')
  [ "$output" = "see $link" ]
}

@test "GIT_OSC8_REFS_BASE が origin より優先され末尾スラッシュを落とす" {
  export GIT_OSC8_REFS_BASE='https://ghe.example.com/o/r/'
  run bash "$SCRIPT" <<< 'see #3'

  [ "$status" -eq 0 ]
  link=$(osc8 'https://ghe.example.com/o/r/issues/3' '#3')
  [ "$output" = "see $link" ]
}

# =============================================================================
# 素通しになる条件
# =============================================================================

@test "GitHub 以外のホストは素通しする" {
  git remote set-url origin git@gitlab.com:usadamasa/dotfile.git
  run bash "$SCRIPT" <<< 'see #3'

  [ "$status" -eq 0 ]
  [ "$output" = 'see #3' ]
}

@test "origin が無いリポジトリでは素通しする" {
  git remote remove origin
  run bash "$SCRIPT" <<< 'see #3'

  [ "$status" -eq 0 ]
  [ "$output" = 'see #3' ]
}

@test "リポジトリ外では素通しし標準出力に fatal を混ぜない" {
  cd "$BATS_TEST_TMPDIR" || return 1
  run bash "$SCRIPT" <<< 'see #3'

  [ "$status" -eq 0 ]
  [ "$output" = 'see #3' ]
}

# =============================================================================
# git のコンテキスト別 (通常 clone / bare / worktree)
# =============================================================================

@test "通常 clone のコンテキストで変換される" {
  clone="$BATS_TEST_TMPDIR/clone"
  git clone -q "$REPO" "$clone"
  git -C "$clone" remote set-url origin git@github.com:usadamasa/dotfile.git
  cd "$clone" || return 1

  run bash "$SCRIPT" <<< 'see #3'

  [ "$status" -eq 0 ]
  link=$(osc8 'https://github.com/usadamasa/dotfile/issues/3' '#3')
  [ "$output" = "see $link" ]
}

@test "bare リポジトリのコンテキストで変換される" {
  bare="$BATS_TEST_TMPDIR/bare.git"
  git init -q --bare "$bare"
  git -C "$bare" remote add origin git@github.com:usadamasa/dotfile.git
  cd "$bare" || return 1

  run bash "$SCRIPT" <<< 'see #3'

  [ "$status" -eq 0 ]
  link=$(osc8 'https://github.com/usadamasa/dotfile/issues/3' '#3')
  [ "$output" = "see $link" ]
}


# =============================================================================
# git config との対応
# =============================================================================

@test "pager.log と pager.show がこのスクリプトを経由する" {
  for key in log show; do
    value=$(git config --file "$GIT_CONFIG_FILE" --get "pager.$key")
    [[ "$value" == *"git-osc8-refs"* ]]
  done
}

@test "pager の less に -R が付いている" {
  # -R が無いと OSC 8 が less に食われて端末まで届かない
  for key in log show; do
    value=$(git config --file "$GIT_CONFIG_FILE" --get "pager.$key")
    [[ "$value" == *"less -R"* ]]
  done
}

@test "worktree のコンテキストで変換される" {
  echo initial > README.md
  git add README.md
  git commit -q -m 'Initial commit'
  wt="$BATS_TEST_TMPDIR/wt"
  git worktree add -q -b feature "$wt" >/dev/null
  cd "$wt" || return 1

  run bash "$SCRIPT" <<< 'see #3'

  [ "$status" -eq 0 ]
  link=$(osc8 'https://github.com/usadamasa/dotfile/issues/3' '#3')
  [ "$output" = "see $link" ]
}
