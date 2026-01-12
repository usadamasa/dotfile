# CLAUDE.md

## Conversation Guidelines

- 常に日本語で会話する。
- ConfigのLanguageに関わらず、コミットメッセージおよびSKILLなどリポジトリに保存されるテキストは、標準語の日本語で記載する。

## Development Philosophy

### Test-Driven Development (TDD)

- 原則としてテスト駆動開発（TDD）で進める
- 期待される入出力に基づき、まずテストを作成する
- 実装コードは書かず、テストのみを用意する
- テストを実行し、失敗を確認する
- テストが正しいことを確認できた段階でコミットする
- その後、テストをパスさせる実装を進める
- 実装中はテストを変更せず、コードを修正し続ける
- すべてのテストが通過するまで繰り返す

## 技術調査とツール

- 技術要素やソフトウェアエンジニアリングについて調査するときはorm-discovery-mcp-goを積極的に利用するようにしてください｡

# Claude Code

## Skills 実装

https://code.claude.com/docs/en/skills を参照し、適切な形式で記述してください。
作成後、Skillsとして利用可能であることを `/skills` で検証してください。
また、特に指示がなければskillsはリポジトリルートに配置してください。
