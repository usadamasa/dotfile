#!/usr/bin/env bats
# config/zsh/.zshrc が zsh plugin を home-manager の profile から読む並び

setup() {
  DOTFILE_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  FAKE_HOME="$BATS_TEST_TMPDIR/home"
  FAKE_STATE="$FAKE_HOME/.local/state"
  FAKE_DATA="$FAKE_HOME/.local/share"
  PROFILE_SHARE="$FAKE_STATE/nix/profile/share"
  OMZ_DIR="$FAKE_DATA/oh-my-zsh"
  LOG="$BATS_TEST_TMPDIR/sourced.log"
  # テストでは HOME と PATH を差し替えるので、zsh は先に絶対パスで解決しておく (CI では /nix/store にある)
  ZSH_BIN="$(command -v zsh)"

  # home-manager の profile にある plugin と、oh-my-zsh 本体の代わり。読まれた順をログに残す
  mkdir -p "$PROFILE_SHARE/zsh-autosuggestions" "$PROFILE_SHARE/zsh-syntax-highlighting" \
    "$PROFILE_SHARE/zsh/site-functions" "$OMZ_DIR" "$FAKE_HOME/.cache/zsh"
  printf '%s\n' 'print -r -- "autosuggestions" >> "$ZSHRC_TEST_LOG"' \
    > "$PROFILE_SHARE/zsh-autosuggestions/zsh-autosuggestions.zsh"
  printf '%s\n' 'print -r -- "syntax-highlighting" >> "$ZSHRC_TEST_LOG"' \
    > "$PROFILE_SHARE/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  printf '%s\n' 'print -r -- "oh-my-zsh" >> "$ZSHRC_TEST_LOG"' \
    'print -r -- "plugins=${(j: :)plugins}" >> "$ZSHRC_TEST_LOG"' \
    'print -r -- "fpath=${(j: :)fpath}" >> "$ZSHRC_TEST_LOG"' \
    > "$OMZ_DIR/oh-my-zsh.sh"
}

# .zshenv を経ない zsh -f で .zshrc だけを読む。.zshenv が export する変数は同じ形で渡す。
# source の終了コードは .zshrc の最後の行 (`[ -s … ] && source …`) の値になるので見ない。
# 読み終えたことは末尾の "end" で確かめる。FPATH は呼び出し元のシェル (brew shellenv が export する) から
# 引き継がれて fpath の初期値になるので外す
source_zshrc() {
  env -u FPATH HOME="$FAKE_HOME" \
    XDG_CACHE_HOME="$FAKE_HOME/.cache" \
    XDG_DATA_HOME="$FAKE_DATA" \
    XDG_STATE_HOME="$FAKE_STATE" \
    ZSH="$OMZ_DIR" \
    ZDOTDIR="$DOTFILE_DIR/config/zsh" \
    ZSHRC_TEST_LOG="$LOG" \
    "$ZSH_BIN" -f -c 'source "$1" 2>/dev/null; print -r -- "end" >> "$ZSHRC_TEST_LOG"' _ "$DOTFILE_DIR/config/zsh/.zshrc"
  grep -q -F "end" "$LOG"
}

# ログの中で $1 と完全に一致する最初の行の行番号 (1 始まり)。無ければ 0
log_line_of() {
  local hit
  if ! hit=$(grep -n -m 1 -x -F -- "$1" "$LOG"); then
    printf '0\n'
    return 0
  fi
  printf '%s\n' "${hit%%:*}"
}

@test "plugin 2 つを home-manager の profile から、oh-my-zsh の後に autosuggestions → syntax-highlighting の順で読む" {
  run source_zshrc
  [ "$status" -eq 0 ]

  omz_line=$(log_line_of "oh-my-zsh")
  auto_line=$(log_line_of "autosuggestions")
  hl_line=$(log_line_of "syntax-highlighting")
  [ "$omz_line" -gt 0 ]
  [ "$auto_line" -gt 0 ]
  [ "$hl_line" -gt 0 ]
  [ "$omz_line" -lt "$auto_line" ]
  [ "$auto_line" -lt "$hl_line" ]
}

@test "oh-my-zsh の plugins に zsh-syntax-highlighting を残さない (custom/plugins の clone は使わない)" {
  run source_zshrc
  [ "$status" -eq 0 ]

  plugins_line=$(grep '^plugins=' "$LOG")
  [[ "$plugins_line" != *"zsh-syntax-highlighting"* ]]
  [[ "$plugins_line" != *"zsh-autosuggestions"* ]]
}

@test "home-manager の profile の share/zsh/site-functions を oh-my-zsh の compinit より前に fpath へ足す" {
  run source_zshrc
  [ "$status" -eq 0 ]

  fpath_line=$(grep '^fpath=' "$LOG")
  [[ "$fpath_line" == *"$PROFILE_SHARE/zsh/site-functions"* ]]
}
