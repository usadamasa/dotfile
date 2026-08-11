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
| 前のタブ | `cmd` + `←` | `prefix` + `p` |
| 次のタブ | `cmd` + `→` | `prefix` + `n` |
| 新しい space (workspace) | `ctrl` + `n` | `prefix` + `shift` + `n` |
| 新しいタブ | `ctrl` + `shift` + `n` | `prefix` + `c` |
| 新しい claude エージェント | `ctrl` + `option` + `n` | (なし) |

変更後の反映は再起動不要で、`herdr server reload-config` で足りる。

直接バインドしたキーは herdr が横取りするため、ペイン内のアプリには届かなくなる。
特に `ctrl+n` は shell の履歴移動や vim の補完で使われるので、影響が大きいと
感じたら `config.toml` の `new_workspace` から外す。

### ターミナル側の前提

herdr は kitty keyboard protocol を使うため、`cmd` や `ctrl+shift` の
組み合わせも受け取れる。ただし手前でターミナルが横取りしていると届かない。

Ghostty は既定で `super+arrow_left/right` を `^A` / `^E` に変換するので、
`config/ghostty/config` で unbind してある。`ctrl+option+n` が効かない場合は
同ファイルの `macos-option-as-alt` を有効にする。

## 参考

- [herdr でタブタイトルを Claude Code のプロンプトにする](https://tech.anycloud.co.jp/articles/herdr-claude-code-tab-title/)
