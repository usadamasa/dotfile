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

## 参考

- [herdr でタブタイトルを Claude Code のプロンプトにする](https://tech.anycloud.co.jp/articles/herdr-claude-code-tab-title/)
