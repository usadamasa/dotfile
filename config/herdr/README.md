# herdr

[herdr](https://herdr.dev) はコーディングエージェント向けのターミナルワークスペース
マネージャ。`task setup` で以下が `~/.config/herdr/` へ symlink される。

| ファイル | 役割 |
| --- | --- |
| `config.toml` | herdr 本体の設定 (テーマ・UI・キーバインド) |
| `herdr-new-agent.sh` | ペインを分割して新しいエージェントを起動する |

Claude Code のプロンプトをタブ名へ反映するフックは
[claude-config](https://github.com/usadamasa/claude-config) の `shared/hooks/` が持つ。

## キーバインド

既定の prefix (`ctrl+b`) 方式は残したまま、直接バインドを追加してある。

| 操作 | キー | prefix 版 |
| --- | --- | --- |
| ペインを下に分割 | `cmd` + `enter` / `cmd` + `shift` + `d` | `prefix` + `-` |
| ペインを右に分割 | `cmd` + `shift` + `enter` / `cmd` + `d` | `prefix` + `v` |
| ペイン間の移動 | `cmd` + `←↓↑→` | `prefix` + `h/j/k/l` |
| ペインを循環 | `cmd` + `[` / `]` | `prefix` + `(shift) tab` |
| ペインのリサイズ | `cmd` + `ctrl` + `←↓↑→` | `prefix` + `r` |
| ペインを閉じる | `cmd` + `w` | `prefix` + `x` |
| 新しい space (workspace) | `cmd` + `n` (`ctrl` + `n`) | `prefix` + `shift` + `n` |
| 新しいタブ | `cmd` + `t` | `prefix` + `c` |
| 前のタブ | `shift` + `←` / `↑`、`cmd` + `shift` + `[`、`ctrl` + `shift` + `tab` | `prefix` + `p` |
| 次のタブ | `shift` + `→` / `↓`、`cmd` + `shift` + `]`、`ctrl` + `tab` | `prefix` + `n` |
| 新しい claude エージェント | `ctrl` + `option` + `n` | (なし) |

`cmd+d` / `cmd+[` / `cmd+shift+[` / `ctrl+tab` は Ghostty が既定で自分の
split・タブ操作に使っていたキー。向きや役割は Ghostty 既定に合わせたまま
herdr 側へ移してある。リサイズだけは herdr に方向指定のバインドがないため、
`herdr pane resize` を叩くカスタムコマンドで実現している。

変更後の反映は再起動不要で、`herdr server reload-config` で足りる。

直接バインドしたキーは herdr が横取りするため、ペイン内のアプリには届かなくなる。
特に `ctrl+n` は shell の履歴移動や vim の補完で使われる。`cmd+n` が安定して
効くなら `config.toml` の `new_workspace` から外してよい。

### ターミナル側の前提

herdr は kitty keyboard protocol を使うため、`cmd` や `ctrl+shift` の
組み合わせも受け取れる。ただし手前でターミナルが横取りしていると届かない。

Ghostty は `cmd` 系のキー (`cmd+enter` / `cmd+n` / `cmd+t` / `cmd+w` /
`cmd+矢印`) を既定で自分のタブ・ウィンドウ操作に使うため、
`config/ghostty/config` で CSI-u シーケンス (`csi:13;9u` など) に付け替えて
herdr へ転送している。キーを増やすときは両方のファイルを対で更新する。

`ctrl+option+n` が効かない場合は `config/ghostty/config` の
`macos-option-as-alt` を有効にする。

## トラブルシューティング

### `error: nested herdr is disabled by default.`

herdr は `HERDR_ENV=1` を見つけると nested と判定して起動を拒否する。判定材料は
この環境変数だけで、本当にペインの中にいるかは見ていない。

Ghostty のアプリプロセスが一度でも `HERDR_ENV=1` を持った状態で起動すると
(herdr のペインから `ghostty` バイナリを直接叩いた場合など)、そのアプリが開く
サーフェスはすべて `command = herdr` を汚染された環境で起動するため、以後ずっと
このエラーになる。macOS は同じバンドルのアプリを 1 インスタンスしか持たないので、
ウィンドウを閉じて Dock から開き直しても汚染されたプロセスが再利用される。

`config/ghostty/config` の `env = HERDR_ENV=` で、Ghostty が起動する子プロセス
から `HERDR_*` を落としてあるので、この状態にはならない。

すでに汚染されたアプリプロセスが残っている場合は、それを本当に終了させる必要が
ある。Terminal.app から `herdr server stop` すると、サーバの子孫にぶら下がって
いる Ghostty ごと落ちるため復旧する。

## 参考

- [herdr でタブタイトルを Claude Code のプロンプトにする](https://tech.anycloud.co.jp/articles/herdr-claude-code-tab-title/)
