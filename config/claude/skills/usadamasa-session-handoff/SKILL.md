---
name: session-handoff
description: >
  コンテキスト逼迫時の自動引き継ぎとcompaction。セッション中にコンテキストが逼迫してきたと感じたら、
  プロアクティブにこのスキルを実行する。引継書をauto memoryに保存し、/compactでコンテキストを圧縮する。
  「引き継ぎして」「セッション引き継ぎ」「中断するから引き継ぎ書いて」「handoff」等の手動トリガーにも対応。
---

# session-handoff

コンテキストが逼迫してきたときに引継書を作成し、auto memoryに保存してからコンテキストを圧縮するスキル。
セッション継続と次セッションへの情報伝達の両方を実現する。

## トリガー条件

- **自動(プロアクティブ)**: コンテキストウィンドウが逼迫してきたと判断したとき
- **手動**: 「引き継ぎして」「セッション引き継ぎ」「中断するから引き継ぎ書いて」「handoff」等

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status --short`
- Recent commits: !`git log --oneline -5`

## ワークフロー

### Step 1: 現在の状態をキャプチャ

以下の情報を収集する:

```bash
git branch --show-current
git status --short
git log --oneline -5
git diff --stat
```

未コミットの変更ファイル一覧、現在のブランチ、直近のコミットを把握する。

### Step 2: タスク進捗を整理

セッション中の作業を振り返り、以下を整理する:

- 完了したステップ(何を実装/修正したか)
- 未完了のステップ(次にやるべきこと)
- 重要な判断とその理由(なぜその方法を選んだか)
- ブロッカー(あれば)

PLAN.md が存在する場合は、その進捗状態も確認する。

### Step 3: SESSION_HANDOFF.md を生成

以下のテンプレートに沿って引継書を作成する:

```markdown
# セッション引き継ぎ

## タスク
<何をしているか、1-2行で簡潔に>

## 完了
- [x] <完了したステップ1>
- [x] <完了したステップ2>

## 次のアクション
1. <次にやること1>
2. <次にやること2>

## Git状態
- ブランチ: <branch>
- 最新コミット: <hash> <message>
- 未コミット変更: <files or "なし">

## 判断・決定
- <重要な判断とその理由>

## ブロッカー
- <あれば。なければ "なし">
```

### Step 4: Auto Memory に保存

プロジェクトの auto memory ディレクトリに `SESSION_HANDOFF.md` を書き込む。

保存先の特定方法:

```bash
# CWD のパスから auto memory のプロジェクトディレクトリを導出する
# 例: /Users/masaru_uchida/src/github.com/usadamasa/dotfile/main
#   → ~/.claude/projects/-Users-masaru-uchida-src-github-com-usadamasa-dotfile-main/memory/SESSION_HANDOFF.md
```

auto memory ディレクトリのパスは、CWD の `/` を `-` に置換し、先頭に `-` を付けたものになる。
memory サブディレクトリが存在しない場合は作成する。

既存の `SESSION_HANDOFF.md` がある場合は上書きする(常に最新の状態を反映)。

### Step 5: コンテキストを圧縮

`/compact` を実行してコンテキストを圧縮する。

圧縮時の維持指示として、引継書の要点を含める:

```
/compact SESSION_HANDOFF.mdの内容を維持しつつコンテキストを圧縮。現在のタスク: <タスク概要>、次のアクション: <次にやること>
```

## 注意事項

- 引継書は簡潔に保つ。詳細すぎると次セッションのコンテキストを圧迫する
- MEMORY.md は更新しない(SESSION_HANDOFF.md は次セッション起動時に自動で読み込まれる)
- 圧縮後もセッションは継続可能。`claude --continue` で次セッションから再開することもできる
- PLAN.md がある場合は、そのチェック状態を引継書に反映する
