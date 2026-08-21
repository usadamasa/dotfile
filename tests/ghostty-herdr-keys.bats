#!/usr/bin/env bats
# Ghostty と herdr の連携のテスト
#
# キーバインド: Ghostty は cmd 系のキーを自分で消費せず、kitty keyboard
# protocol の CSI-u シーケンスとして herdr へ転送する。両ファイルの対応が
# 崩れるとキーがどこにも届かなくなるため、対になっていることを検証する。
#
# 環境変数: Ghostty が起動する herdr は最も外側のクライアントなので、
# HERDR_* を引き継がせない (引き継ぐと nested 判定で起動できなくなる)。

GHOSTTY_CONFIG="$BATS_TEST_DIRNAME/../config/ghostty/config"
HERDR_CONFIG="$BATS_TEST_DIRNAME/../config/herdr/config.toml"

# Ghostty の keybind から転送先のシーケンスを取り出す
ghostty_action() {
  local trigger="$1"
  grep -E "^keybind = ${trigger}=" "$GHOSTTY_CONFIG" | sed -E 's/^keybind = [^=]+=//'
}

# herdr の [keys] で指定のキーがどのアクションに割り当たっているか
herdr_action_for_key() {
  local key="$1"
  grep -E "^[a-z_]+ = \[.*\"${key}\".*\]" "$HERDR_CONFIG" | sed -E 's/ =.*//'
}

# =============================================================================
# Ghostty 側: cmd 系は CSI-u 転送に徹する
# =============================================================================

@test "cmd 系のキーは Ghostty 自身のペイン・タブ操作に使われない" {
  run grep -nE '^keybind = cmd\+.*=(new_split|new_tab|new_window|goto_split|resize_split|close_surface)' "$GHOSTTY_CONFIG"
  [ "$status" -ne 0 ]
}

@test "cmd+enter は下分割用の CSI-u を送る" {
  # 13 = enter の Unicode コードポイント、9 = 1 + super(8)
  [ "$(ghostty_action 'cmd\+enter')" = 'csi:13;9u' ]
}

@test "cmd+shift+enter は右分割用の CSI-u を送る" {
  # 10 = 1 + shift(1) + super(8)
  [ "$(ghostty_action 'cmd\+shift\+enter')" = 'csi:13;10u' ]
}

@test "cmd+n は workspace 生成用の CSI-u を送る" {
  # 110 = n の Unicode コードポイント
  [ "$(ghostty_action 'cmd\+n')" = 'csi:110;9u' ]
}

@test "cmd+矢印はペイン移動用の CSI-u を送る" {
  [ "$(ghostty_action 'cmd\+left')" = 'csi:1;9D' ]
  [ "$(ghostty_action 'cmd\+right')" = 'csi:1;9C' ]
  [ "$(ghostty_action 'cmd\+up')" = 'csi:1;9A' ]
  [ "$(ghostty_action 'cmd\+down')" = 'csi:1;9B' ]
}

@test "cmd+d 系は分割用の CSI-u を送る" {
  # 100 = d の Unicode コードポイント
  [ "$(ghostty_action 'cmd\+d')" = 'csi:100;9u' ]
  [ "$(ghostty_action 'cmd\+shift\+d')" = 'csi:100;10u' ]
}

@test "cmd+[ / ] はペイン循環用の CSI-u を送る" {
  # 91 = [、93 = ]
  [ "$(ghostty_action 'cmd\+\[')" = 'csi:91;9u' ]
  [ "$(ghostty_action 'cmd\+\]')" = 'csi:93;9u' ]
}

@test "タブ移動キーはタブ用の CSI-u を送る" {
  # shift 付きでも送るのは非 shift のコードポイント + shift 修飾子
  [ "$(ghostty_action 'cmd\+shift\+\[')" = 'csi:91;10u' ]
  [ "$(ghostty_action 'cmd\+shift\+\]')" = 'csi:93;10u' ]
  # 9 = tab、5 = 1 + ctrl(4)、6 = 1 + shift(1) + ctrl(4)
  [ "$(ghostty_action 'ctrl\+tab')" = 'csi:9;5u' ]
  [ "$(ghostty_action 'ctrl\+shift\+tab')" = 'csi:9;6u' ]
}

@test "cmd+ctrl+矢印はリサイズ用の CSI-u を送る" {
  # 13 = 1 + ctrl(4) + super(8)
  [ "$(ghostty_action 'cmd\+ctrl\+left')" = 'csi:1;13D' ]
  [ "$(ghostty_action 'cmd\+ctrl\+right')" = 'csi:1;13C' ]
  [ "$(ghostty_action 'cmd\+ctrl\+up')" = 'csi:1;13A' ]
  [ "$(ghostty_action 'cmd\+ctrl\+down')" = 'csi:1;13B' ]
}

# =============================================================================
# herdr 側: 転送されたキーを受け取るバインドがある
# =============================================================================

@test "cmd+enter が herdr の下分割に割り当たっている" {
  [ "$(herdr_action_for_key 'cmd\+enter')" = "split_horizontal" ]
}

@test "cmd+shift+enter が herdr の右分割に割り当たっている" {
  [ "$(herdr_action_for_key 'cmd\+shift\+enter')" = "split_vertical" ]
}

@test "cmd+n が herdr の workspace 生成に割り当たっている" {
  [ "$(herdr_action_for_key 'cmd\+n')" = "new_workspace" ]
}

@test "cmd+t が herdr のタブ生成に割り当たっている" {
  [ "$(herdr_action_for_key 'cmd\+t')" = "new_tab" ]
}

@test "cmd+w が herdr のペイン close に割り当たっている" {
  [ "$(herdr_action_for_key 'cmd\+w')" = "close_pane" ]
}

@test "cmd+矢印が herdr のペイン移動に割り当たっている" {
  [ "$(herdr_action_for_key 'cmd\+left')" = "focus_pane_left" ]
  [ "$(herdr_action_for_key 'cmd\+down')" = "focus_pane_down" ]
  [ "$(herdr_action_for_key 'cmd\+up')" = "focus_pane_up" ]
  [ "$(herdr_action_for_key 'cmd\+right')" = "focus_pane_right" ]
}

@test "cmd+d 系が herdr の分割に割り当たっている" {
  # Ghostty 既定と同じ向き: cmd+d が右、cmd+shift+d が下
  [ "$(herdr_action_for_key 'cmd\+d')" = "split_vertical" ]
  [ "$(herdr_action_for_key 'cmd\+shift\+d')" = "split_horizontal" ]
}

@test "cmd+[ / ] が herdr のペイン循環に割り当たっている" {
  [ "$(herdr_action_for_key 'cmd\+\[')" = "cycle_pane_previous" ]
  [ "$(herdr_action_for_key 'cmd\+\]')" = "cycle_pane_next" ]
}

@test "タブ移動キーが herdr のタブ移動に割り当たっている" {
  [ "$(herdr_action_for_key 'cmd\+shift\+\[')" = "previous_tab" ]
  [ "$(herdr_action_for_key 'cmd\+shift\+\]')" = "next_tab" ]
  [ "$(herdr_action_for_key 'ctrl\+shift\+tab')" = "previous_tab" ]
  [ "$(herdr_action_for_key 'ctrl\+tab')" = "next_tab" ]
}

@test "cmd+ctrl+矢印が herdr のペインリサイズに割り当たっている" {
  [ "$(herdr_action_for_key 'ctrl\+cmd\+left')" = "resize_pane_left" ]
  [ "$(herdr_action_for_key 'ctrl\+cmd\+down')" = "resize_pane_down" ]
  [ "$(herdr_action_for_key 'ctrl\+cmd\+up')" = "resize_pane_up" ]
  [ "$(herdr_action_for_key 'ctrl\+cmd\+right')" = "resize_pane_right" ]
}

# =============================================================================
# Ghostty 側: herdr が注入する環境変数を引き継がない
# =============================================================================

@test "Ghostty は HERDR_ENV を子プロセスへ渡さない" {
  # これが残っていると herdr が nested と誤判定して起動を拒否する
  run grep -cE '^env = HERDR_ENV=$' "$GHOSTTY_CONFIG"
  [ "$status" -eq 0 ]
  [ "$output" = "1" ]
}

@test "Ghostty は herdr のペイン識別子を子プロセスへ渡さない" {
  local key
  for key in HERDR_SOCKET_PATH HERDR_CLIENT_SOCKET_PATH HERDR_BIN_PATH \
    HERDR_WORKSPACE_ID HERDR_TAB_ID HERDR_PANE_ID; do
    run grep -cE "^env = ${key}=\$" "$GHOSTTY_CONFIG"
    [ "$status" -eq 0 ]
    [ "$output" = "1" ]
  done
}

@test "env のクリアより後に env マップ全体のリセットがない" {
  # 値なしの `env =` はマップ全体を空に戻すため、クリア行が無効化される
  local first_clear reset_line
  first_clear=$(grep -nE '^env = HERDR_' "$GHOSTTY_CONFIG" | head -1 | cut -d: -f1)
  [ -n "$first_clear" ]
  reset_line=$(grep -nE '^env =\s*$' "$GHOSTTY_CONFIG" | head -1 | cut -d: -f1)
  if [ -n "$reset_line" ]; then
    [ "$reset_line" -lt "$first_clear" ]
  fi
}

# =============================================================================
# 設定ファイル自体の妥当性 (ツールがある環境でのみ)
# =============================================================================

@test "herdr が config.toml を受け付ける" {
  if ! command -v herdr > /dev/null; then
    skip "herdr がインストールされていない"
  fi
  HERDR_CONFIG_PATH="$HERDR_CONFIG" run herdr config check
  [ "$status" -eq 0 ]
  [[ "$output" == *"ok"* ]]
}

@test "Ghostty が config を受け付ける" {
  local ghostty=/Applications/Ghostty.app/Contents/MacOS/ghostty
  if [ ! -x "$ghostty" ]; then
    skip "Ghostty がインストールされていない"
  fi
  run "$ghostty" +validate-config --config-file="$GHOSTTY_CONFIG"
  [ "$status" -eq 0 ]
}
