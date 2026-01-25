# CLAUDE.md

> **Note:** This directory (`config/claude/`) is symlinked to `~/.claude` via dotfiles setup.
> All configurations here apply globally to all projects.
> Source: `~/src/github.com/usadamasa/dotfile/config/claude/`

## Conversation Guidelines

### 言語設定

- 会話は常に日本語で行う｡
- コミットメッセージ､スキル定義などリポジトリに保存されるテキストは標準語で記載する｡(ConfigのLanguage設定に関わらず)

### 文字種ルール

以下の文字は全角ではなく半角を使用する:

- 句読点: ｡ ､
- 括弧: ( ) [ ] { }
- 記号: , : ; ! ?

## Development Philosophy

### Test-Driven Development (TDD)

- 原則としてテスト駆動開発(TDD)で進める
- 期待される入出力に基づき､まずテストを作成する
- 実装コードは書かず､テストのみを用意する
- テストを実行し､失敗を確認する
- テストが正しいことを確認できた段階でコミットする
- その後､テストをパスさせる実装を進める
- 実装中はテストを変更せず､コードを修正し続ける
- すべてのテストが通過するまで繰り返す

## 技術調査とツール

- 技術要素やソフトウェアエンジニアリングについて調査するときはorm-discovery-mcp-goを積極的に利用するようにしてください｡

## Skills 実装

<https://code.claude.com/docs/en/skills> を参照し､適切な形式で記述してください｡
作成後､Skillsとして利用可能であることを `/skills` で検証してください｡

### スキルの配置場所

| スコープ | 配置場所 | 説明 |
| --------- | --------- | ------ |
| グローバル | `config/claude/skills/` (= `~/.claude/skills/`) | 全プロジェクトで利用可能 |
| プロジェクト | プロジェクトの `.claude/skills/` | そのプロジェクトのみで利用可能 |

特に指示がなければグローバルスコープ(`config/claude/skills/`)に配置してください｡
