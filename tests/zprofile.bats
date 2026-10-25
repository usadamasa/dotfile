#!/usr/bin/env bats
# config/zsh/zprofile (programs.zsh.profileExtra) の PATH の並び

setup() {
  DOTFILE_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  FAKE_HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$FAKE_HOME"
  NIX_PROFILE_BIN="$FAKE_HOME/.local/state/nix/profile/bin"
  # テストでは PATH を差し替えるので、zsh は先に絶対パスで解決しておく (CI では /nix/store にある)
  ZSH_BIN="$(command -v zsh)"
}

# ログインシェルで /etc/zprofile の path_helper が通った直後の並び (システムが先頭、nix の profile が後ろ) を
# 起点にして .zprofile を読み、PATH を出力する。NIX_PROFILES は .zshenv (programs.zsh.envExtra) の nix-daemon.sh が export する値の形。
# brew や go が無い環境でも読める
source_zprofile_and_print_path() {
  HOME="$FAKE_HOME" \
    NIX_PROFILES="/nix/var/nix/profiles/default $FAKE_HOME/.local/state/nix/profile" \
    PATH="/usr/bin:/bin:/usr/sbin:/sbin:$NIX_PROFILE_BIN" \
    "$ZSH_BIN" -f -c 'source "$1" 2>/dev/null; print -r -- "$PATH"' _ "$DOTFILE_DIR/config/zsh/zprofile"
}

# PATH の中で $1 が最初に現れる位置 (0 始まり)。無ければ -1
path_index_of() {
  local IFS=':' i=0 entry
  for entry in $PATH_UNDER_TEST; do
    if [ "$entry" = "$1" ]; then
      printf '%d\n' "$i"
      return 0
    fi
    i=$((i + 1))
  done
  printf '%d\n' -1
}

@test "nix の profile が /usr/bin より前に来る" {
  run source_zprofile_and_print_path
  [ "$status" -eq 0 ]
  PATH_UNDER_TEST="$output"

  nix_index=$(path_index_of "$NIX_PROFILE_BIN")
  usr_bin_index=$(path_index_of /usr/bin)
  [ "$nix_index" -ge 0 ]
  [ "$usr_bin_index" -ge 0 ]
  [ "$nix_index" -lt "$usr_bin_index" ]
}

@test "nix の profile が /opt/homebrew/bin より前に来る (brew がある環境)" {
  if [ ! -x /opt/homebrew/bin/brew ]; then
    skip "brew が無い"
  fi
  run source_zprofile_and_print_path
  [ "$status" -eq 0 ]
  PATH_UNDER_TEST="$output"

  nix_index=$(path_index_of "$NIX_PROFILE_BIN")
  brew_index=$(path_index_of /opt/homebrew/bin)
  [ "$nix_index" -ge 0 ]
  [ "$brew_index" -ge 0 ]
  [ "$nix_index" -lt "$brew_index" ]
}

@test "user profile が default profile より前に来る (nix-daemon.sh と同じ並び)" {
  run source_zprofile_and_print_path
  [ "$status" -eq 0 ]
  PATH_UNDER_TEST="$output"

  nix_index=$(path_index_of "$NIX_PROFILE_BIN")
  default_index=$(path_index_of /nix/var/nix/profiles/default/bin)
  [ "$nix_index" -ge 0 ]
  [ "$default_index" -ge 0 ]
  [ "$nix_index" -lt "$default_index" ]
}

@test "NIX_PROFILES が無い環境 (nix 未導入) でも PATH が壊れない" {
  run env -u NIX_PROFILES HOME="$FAKE_HOME" PATH="/usr/bin:/bin:/usr/sbin:/sbin" \
    "$ZSH_BIN" -f -c 'source "$1" 2>/dev/null; print -r -- "$PATH"' _ "$DOTFILE_DIR/config/zsh/zprofile"
  [ "$status" -eq 0 ]
  PATH_UNDER_TEST="$output"

  [ "$(path_index_of /usr/bin)" -ge 0 ]
  [[ "$output" != *"nix/profile/bin"* ]]
}
