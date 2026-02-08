---
name: webfetch-domain-manager
description: >-
  settings.jsonのWebFetchドメイン許可リストを管理するスキル。
  セッションJSONLから過去30日間のWebFetch使用状況を集計し、
  安全性評価に基づいてドメインの追加/削除を提案する。
  (1) 許可ドメインの棚卸し (2) 新規ドメインの追加提案
  (3) 未使用ドメインの削除提案 に使用する。
---

# WebFetch Domain Manager

settings.jsonの`permissions.allow`に登録されているWebFetchドメインの許可リストを管理するワークフロー。

## ワークフロー

### 1. 分析の実行

以下のコマンドを実行してWebFetch使用状況を集計する:

```bash
go run ./cmd/analyze-webfetch --days 30
```

オプション:
- `--days N`: 集計期間を指定(デフォルト: 30日)
- `--settings PATH`: settings.jsonのパスを指定(デフォルト: ~/.claude/settings.json)

### 2. 結果の確認

出力はJSON形式で以下のセクションを含む:

- **metadata**: 分析の概要(期間、ファイル数、呼び出し回数)
- **recommendations.add**: 追加推奨ドメイン(safeカテゴリで未登録のもの)
- **recommendations.review**: 要確認ドメイン(medium/reviewカテゴリ)
- **recommendations.unused**: 未使用ドメイン(許可リストにあるが使用されていない)
- **all_domains**: 全ドメインの使用統計

### 3. settings.jsonの更新

ユーザーの承認を得た上で、以下の手順でsettings.jsonを更新する:

1. 承認されたドメインのみ`permissions.allow`に追加
2. `WebFetch(domain:ドメイン名)` 形式で記述
3. 許可エントリはアルファベット順にソート
4. 不要と判断されたドメインは削除

### 注意事項

- 必ずユーザーの承認を得てから変更を適用すること
- reviewカテゴリのドメインは特に慎重に確認すること
- ワイルドカード(`*.example.com`)は必要な場合のみ使用すること

## 安全性カテゴリ

| カテゴリ | 説明 | 例 |
|----------|------|-----|
| safe | 公式ドキュメント・パッケージレジストリ | docs.*, github.com, pkg.go.dev |
| medium | コミュニティ・学習プラットフォーム | stackoverflow.com, medium.com |
| review | 手動確認が必要 | 上記に該当しないドメイン |
