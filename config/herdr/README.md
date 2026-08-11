# herdr

[herdr](https://herdr.dev) はコーディングエージェント向けのターミナルワークスペース
マネージャ。`task setup` で以下が `~/.config/herdr/` へ symlink される。

| ファイル | 役割 |
| --- | --- |
| `config.toml` | herdr 本体の設定 (テーマ・UI・キーバインド) |
| `herdr-new-agent.sh` | ペインを分割して新しいエージェントを起動する |
| `herdr-tab-title.sh` | Claude Code のプロンプトをタブ名へ反映するフック |

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

## タブ名の自動リネーム

`herdr-tab-title.sh` を Claude Code の `UserPromptSubmit` フックに登録すると、
送信したプロンプトの先頭 20 文字がタブ名になる。

フックの登録先は [claude-config](https://github.com/usadamasa/claude-config) が
管理する `~/.claude/settings.json`。`hooks.UserPromptSubmit[0].hooks` へ以下を
追加する。

```json
{
  "type": "command",
  "command": "$HOME/.config/herdr/herdr-tab-title.sh",
  "timeout": 5
}
```

起動中のセッションには、`/hooks` メニューを一度開けば反映される。

### タブの特定方法

`HERDR_TAB_ID` / `HERDR_PANE_ID` は共有デーモン配下で古い値のまま残ることが
あり、実際のタブとずれる。そのため `herdr api snapshot` へ問い合わせて、
次の順で対象タブを決めている。

1. herdr が claude 連携フックから受け取ったセッション ID と一致するペイン
2. セッション ID が未登録で、`cwd` が一致する claude ペインがちょうど 1 つ

どちらにも当てはまらないときは何もしない。誤ったタブを rename しないための
判断で、worktree などで cwd がずれている場合はタブ名が変わらない。

## 参考

- [herdr でタブタイトルを Claude Code のプロンプトにする](https://tech.anycloud.co.jp/articles/herdr-claude-code-tab-title/)
