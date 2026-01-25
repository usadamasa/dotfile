---
name: skill-creation-guide
description: Claude Codeのskillを効果的に作成・運用するためのガイド。Frontmatterの書き方、セクション構成のベストプラクティス、記述スタイル、複数ファイル構成の判断基準、関連skillの統廃合基準を含みます。
---

# Claude Code Skill 作成ガイド

このガイドは、Claude Codeのskillを効果的に作成・運用するためのベストプラクティスを提供します。

## 目的と対象読者

### Skillの役割

Claude Code Skillは、特定のタスクやトピックに関する専門知識を構造化して提供する仕組みです。

**主な利点**:
- ✅ 繰り返し使う知識をドキュメント化
- ✅ プロジェクト固有またはユーザー固有の手順を標準化
- ✅ `/skills`コマンドで素早くアクセス可能
- ✅ Claudeが自動的に適切なタイミングで参照

### このガイドを使うべきタイミング

以下の状況で、このガイドを参照してください:

1. **新しいskillを作成する前** - 重複チェック、統廃合判断
2. **既存skillをメンテナンスする時** - 構成やスタイルの確認
3. **skillが認識されない時** - トラブルシューティング

## Frontmatterパターン

Skillの先頭にはYAML frontmatterが必要です。現在、2つのパターンが存在します。

### 命名規則

**gerund形式 (verb + -ing) を推奨**:

| 推奨度 | パターン | 例 |
|--------|----------|-----|
| ✅ 推奨 | gerund形式 | `processing-pdfs`, `analyzing-data`, `managing-configs` |
| ⚠️ 許容 | 名詞句 | `pdf-processing`, `data-analysis` |
| ⚠️ 許容 | 動詞形 | `process-pdfs`, `analyze-data` |
| ❌ 避ける | 曖昧な名前 | `helper`, `utils`, `tools`, `stuff` |

**制約**:
- 小文字、数字、ハイフンのみ
- 最大64文字
- `anthropic`, `claude` は予約語のため使用不可

**userスコープのprefix規則**:
- userスコープ (`~/.claude/skills/`) に配置するskillは `usadamasa-` をprefixとして付ける
- 例: `usadamasa-skill-creation-guide`, `usadamasa-draft-pr-with-squash`
- プロジェクトスコープ (`.claude/skills/`) にはprefixは不要

### パターン比較

| 項目 | name パターン（推奨） | skill_invocation パターン（レガシー） |
|------|---------------------|----------------------------------|
| **使用方法** | `/skills`から自動認識 | `/skill-name`で明示的呼び出し |
| **記述例** | `name: jacoco-coverage` | `skill_invocation: upgrade-quarkus` |
| **推奨度** | ✅ 推奨（新規作成時） | ⚠️ 既存skillとの互換性のみ |
| **認識性** | Claudeが文脈で自動参照 | ユーザーが明示的に呼び出す必要 |

### 推奨パターン（name:）

```yaml
---
name: skill-creation-guide
description: Claude Codeのskillを効果的に作成・運用するためのガイド。Frontmatterの書き方、セクション構成のベストプラクティス、記述スタイル、複数ファイル構成の判断基準、関連skillの統廃合基準を含みます。
---
```

**descriptionの書き方**:
- **三人称で記述** (重要)
  - ✅ 良い例: "Processes Excel files and generates reports"
  - ❌ 避ける: "I can help you process Excel files"
  - ❌ 避ける: "You can use this to process Excel files"
- 何をするか + いつ使うかを含める
- 1-2文で簡潔に（80-150文字程度、最大1024文字）
- 句点で終わる

### レガシーパターン（skill_invocation:）

```yaml
---
skill_invocation: upgrade-quarkus
description: Quarkusバージョンのアップグレードと依存関係競合の解決を支援します
---
```

**このパターンを使うべき状況**:
- 既存skillとの互換性維持が必要な場合のみ
- 新規作成時は `name:` パターンを使用してください

## セクション構成ベストプラクティス

Skillは以下の5段階ピラミッド構造で構成します。

### 5段階ピラミッド構造

```
1. タイトル (H1) + 導入文        ← 必須
2. 概要 (H2)                    ← 必須
3. クイックリファレンス (H2)     ← 推奨
4. 主要セクション (H2 × 3-5)    ← 推奨
5. トラブルシューティング/FAQ    ← オプション
```

### 必須セクション

#### 1. タイトル (H1)

```markdown
# [Skill名] - [サブタイトル]

または

# [Skill名]
```

**例**:
- `# JaCoCoコードカバレッジ - クイックガイド`
- `# Gradle依存関係ベストプラクティス`
- `# checkDependencies タスク`

#### 2. 概要 (H2)

```markdown
## 概要

このスキルは、[目的]を提供します。

または

このガイドは、[目的]のためのベストプラクティスを提供します。
```

### 推奨セクション

#### 3. クイックリファレンス

よく使うコマンド、最も重要な3つのポイント、基本的な使い方を記載。

```markdown
## よく使うコマンド

\`\`\`bash
# Finderでディレクトリを開く
open ~/.config/

# クリップボードにコピー
cat file.txt | pbcopy

# クリップボードから貼り付け
pbpaste > output.txt

# Homebrewでツール確認
brew list | grep [tool-name]
\`\`\`

または

## 最も重要な3つのポイント

1. ✅ **ポイント1のタイトル**
   - 詳細説明

2. ✅ **ポイント2のタイトル**
   - 詳細説明
```

#### 4. 主要セクション（3-5個）

skillの用途に応じて適切なセクションを配置:

**技術ツール系skill**:
- 使用方法
- 設定
- 実装の詳細
- ファイルパス早見表

**ベストプラクティス系skill**:
- クイックリファレンス
- アンチパターン
- よくある質問

### オプションセクション

#### 5. トラブルシューティング/FAQ/参考リンク

```markdown
## トラブルシューティング

### 問題1: [問題の症状]

**原因**: [原因の説明]

**解決方法**:
1. ステップ1
2. ステップ2

## 参考リンク

- [公式ドキュメント](URL)
- [関連プロジェクト](path)
```

### セクション構成テンプレート

```markdown
---
name: example-skill
description: [1-2文の説明。使用タイミングを含める。]
---

# [Skill名] - [サブタイトル]

このスキルは、[目的]を提供します。

## [主要セクション1]

内容...

## [主要セクション2]

内容...

## [主要セクション3]

内容...

## トラブルシューティング

よくある問題...

## 参考リンク

- [リンク1](URL)
```

### macOS向けスキルのテンプレート

```markdown
---
name: example-macos-skill
description: [目的]を提供します。macOSの[機能]を活用して[効果]を実現します。
---

# [Skill名]

このスキルは、macOS環境での[目的]を提供します。

## 前提条件

- macOS 12以降
- Homebrew がインストール済み
- 必要なツール: `brew install [tool-name]`

## よく使うコマンド

\`\`\`bash
# コマンド1の説明
open /path/to/directory

# コマンド2の説明
brew list | grep [keyword]
\`\`\`

## [主要セクション]

内容...

## トラブルシューティング

### ツールが見つからない

\`\`\`bash
# Homebrewでインストール
brew install [tool-name]

# パスを確認
which [tool-name]
\`\`\`
```

## 記述スタイルガイド

Skillを読みやすくするための視覚表現パターンを紹介します。

### 視覚表現パターン

#### ✅/❌ による良い例・悪い例の対比

```markdown
### ✅ 良い例

\`\`\`kotlin
dependencies {
    implementation(libs.io.quarkus.quarkus.arc)
}
\`\`\`

- バージョンカタログを使用
- 一元管理が可能

### ❌ 悪い例

\`\`\`kotlin
implementation(files("../lib/library.jar"))
\`\`\`

- バージョン管理外
- 相対パスへの依存
```

#### 絵文字の効果的な使用

**推奨絵文字**:
- 📦 パッケージ、モジュール
- ⚠️ 警告、注意事項
- ✓ チェック項目、成功
- 🔍 調査、検索
- 📋 リスト、一覧
- ✅ 推奨、良い例
- ❌ 非推奨、悪い例

**使用例**:
```markdown
📦 com.google.guava:guava
   2 バージョンが検出されました:

✅ **統合すべき**: "Gradle依存関係の除外方法"

❌ **分離すべき**: "JaCoCoレポート生成"
```

#### コードブロックの言語指定

必ず言語を指定してシンタックスハイライトを有効化:

````markdown
```bash
./gradlew test
```

```kotlin
dependencies {
    implementation(libs.io.quarkus.quarkus.arc)
}
```

```yaml
ignoredConflicts:
  - packageKey: "org.json:json"
    reason: "複数バージョンの共存が許容される"
```
````

#### macOS特有のコマンド推奨

macOS向けのスキルでは、以下のコマンドを積極的に活用してください:

| コマンド | 用途 | 例 |
|---------|------|-----|
| `open` | Finderやアプリでファイル/URLを開く | `open .` `open -a Safari https://example.com` |
| `pbcopy` | クリップボードにコピー | `cat file.txt \| pbcopy` |
| `pbpaste` | クリップボードから貼り付け | `pbpaste > output.txt` |
| `brew` | Homebrewパッケージ管理 | `brew install [tool]` `brew list` |
| `defaults` | macOS設定の読み書き | `defaults read com.apple.finder` |
| `mdfind` | Spotlight検索 | `mdfind -name "file.txt"` |
| `osascript` | AppleScript実行 | `osascript -e 'display notification "Done"'` |

**macOSスクリーンショット**:
- `cmd+ctrl+shift+4`: クリップボードにスクリーンショット
- `ctrl+v`: 貼り付け (注: `cmd+v`ではない)

**コマンド例のテンプレート**:

```bash
# ディレクトリをFinderで開く
open /path/to/directory

# 結果をクリップボードにコピー
command | pbcopy

# Homebrewでツールをインストール
brew install [tool-name]

# 通知を表示（長時間処理の完了時など）
osascript -e 'display notification "処理が完了しました" with title "Skill"'
```

### パス指定

**Unixスタイル (`/`) を使用** (Windowsスタイル `\` は避ける):

- ✅ 良い: `scripts/helper.py`, `reference/guide.md`
- ❌ 避ける: `scripts\helper.py`, `reference\guide.md`

Unixスタイルは全プラットフォームで動作します。

### 選択肢を与えすぎない

複数のアプローチを提示するより、デフォルトを1つ提供してください。

❌ 悪い例 (選択肢が多すぎる):
```
pypdf、pdfplumber、PyMuPDF、pdf2imageなど...
```

✅ 良い例 (デフォルト + 例外):
```
pdfplumberでテキスト抽出:

import pdfplumber

OCRが必要なスキャンPDFの場合のみ、pdf2image + pytesseractを使用。
```

### テーブル活用

#### ファイルパス早見表

**macOS向けパス例**:

```markdown
| 項目 | パス |
|------|------|
| ユーザー設定 | `~/.config/[app-name]/` |
| アプリケーションサポート | `~/Library/Application Support/[app-name]/` |
| キャッシュ | `~/Library/Caches/[app-name]/` |
| Homebrewセラー | `/opt/homebrew/Cellar/[tool-name]/` |
```

**プロジェクト固有パス例**:

```markdown
| 項目 | パス |
|------|------|
| 個別XMLレポート | `<module>/build/jacoco/jacocoTestReport.xml` |
| 集約XMLレポート | `support-jacoco-report-aggregation/build/reports/jacoco/testCodeCoverageReport/testCodeCoverageReport.xml` |
| 除外パターン定義 | `gradle/build-logic/src/main/kotlin/JacocoExclusions.kt` |
```

#### コマンドオプション対比表

```markdown
| フラグ | 説明 | 必須 |
|--------|------|------|
| `--no-parallel` | 並列実行を無効化 | ✅ |
| `--quiet` | 出力を簡潔にする | ⚠️ 推奨 |
| `--stacktrace` | スタックトレースを表示 | ❌ |
```

#### 判断基準のチェックリスト

```markdown
| 判断基準 | 選択肢A | 選択肢B |
|---------|--------|--------|
| **単一責任の原則** | ✅ 独立した明確な目的 | ❌ 一部として説明可能 |
| **使用頻度** | ✅ 独立して頻繁に参照 | ❌ 同時に使われる |
```

## 複数ファイル構成の判断基準

Skillが大きくなった場合、複数ファイルに分割することができます。

### SKILL.mdの推奨サイズ

- **500行以内**に抑える (公式推奨)
- 超える場合は別ファイルに分離 (progressive disclosure)
- 各skillはメタデータスキャン時に約100トークン、アクティベート時に<5kトークン

### 判断フロー

```
skillの内容量は？
├─ < 300行
│   └─ SKILL.md のみ（シンプル）
│
└─ >= 300行 または 詳細な技術資料が必要
    └─ SKILL.md + reference.md
        ├─ SKILL.md: クイックガイド（使い方中心）
        └─ reference.md: 詳細解説（実装詳細、背景知識）
```

### SKILL.md のみ（推奨）

**使用すべき状況**:
- 内容が300行以内に収まる
- クイックリファレンスとして機能する
- 1つのファイルで完結する方が便利

**例**: `check-dependencies`, `bruno-fix-child-process`

### SKILL.md + reference.md

**使用すべき状況**:
- 内容が300行を超える
- クイックガイドと詳細資料を分けたい
- 実装の詳細やアーキテクチャ解説が必要

**ファイル分割の役割**:

**SKILL.md（クイックガイド）**:
- よく使うコマンド
- 基本的な使い方
- FAQ
- 150-300行程度（スクロール2-3画面分）

**reference.md（詳細資料）**:
- 実装の詳細
- アーキテクチャ
- ベストプラクティスの深掘り
- 制限なし（必要なだけ詳細に記述）

**例**: `jacoco-coverage`, `gradle-dependency-best-practices`

### reference.mdへのリンク

SKILL.mdの最後に、reference.mdへのリンクを追加:

```markdown
## 詳細情報

より詳しいGradle統合、マルチモジュール集約、GitHub Actions統合、パフォーマンス最適化については [reference.md](reference.md) を参照してください。
```

### 参照の深さ制限

**1レベル深さまで**に抑えてください。入れ子参照はClaudeが部分的にしか読めない可能性があります。

✅ 良い構造:
```
SKILL.md
├── reference/finance.md (直接参照)
├── reference/sales.md (直接参照)
└── examples.md (直接参照)
```

❌ 避ける構造:
```
SKILL.md → advanced.md → details.md (入れ子参照)
```

**100行以上のreferenceファイルには目次を付ける**:
```markdown
# API Reference

## Contents
- Authentication and setup
- Core methods
- Error handling
```

## 関連Skillの統廃合判断基準

新しいskillを作成する前に、既存skillに統合すべきか検討します。

### 統廃合判断チェックリスト

| 判断基準 | 新しいskill作成 | 既存skillに統合 |
|---------|--------------|---------------|
| **単一責任の原則** | ✅ 独立した明確な目的がある | ❌ 既存skillの一部として説明可能 |
| **使用頻度** | ✅ 独立して頻繁に参照される | ❌ 既存skillと同時に使われることが多い |
| **技術スタック** | ✅ 異なる技術要素（例: Gradle vs JaCoCo） | ❌ 同じ技術要素の異なる側面 |
| **コンテンツサイズ** | ✅ 150行以上の独立コンテンツ | ❌ 50行程度の補足情報 |
| **ユーザー体験** | ✅ skill名で直感的に発見できる | ❌ 親skillのセクションとして発見しやすい |

### 判断フロー

```
1. 既存skillを検索
   └─ 関連するskillが存在する？
       ├─ YES → ステップ2へ
       └─ NO → 新しいskill作成

2. 既存skillの範囲を確認
   └─ 新しいトピックはskillの目的に合致する？
       ├─ YES → ステップ3へ
       └─ NO → 新しいskill作成

3. コンテンツサイズを評価
   └─ 追加コンテンツは50行以下？
       ├─ YES → 既存skillに統合
       └─ NO → ステップ4へ

4. 単一責任を評価
   └─ 統合するとskillが複雑になりすぎる？
       ├─ YES → 新しいskill作成
       └─ NO → 既存skillに統合
```

### 統合と分離の具体例

#### ✅ 統合すべき例

**ケース**: "Gradle依存関係の除外方法"というトピック

**判断**:
- 既存skill: `gradle-dependency-best-practices`
- 同じ技術スタック（Gradle依存関係管理）
- コンテンツサイズ: 約30-40行
- 既存skillの目的に合致

**結論**: `gradle-dependency-best-practices`に新しいセクションとして追加

#### ❌ 分離すべき例

**ケース**: "JaCoCoレポート生成"というトピック

**判断**:
- 既存skill: `gradle-dependency-best-practices`
- 異なる技術スタック（Gradle vs JaCoCo）
- 独立した明確な目的（コードカバレッジ測定）
- 150行以上の独立コンテンツ

**結論**: `jacoco-coverage`として独立したskillを作成

### 既存skillの調査範囲

既存skillの調査は以下のディレクトリに**限定**してください:

| スコープ | パス | 説明 |
|---------|------|------|
| ユーザレベル | `~/.claude/skills/` | 全プロジェクト共通のskill |
| プロジェクトレベル | `$HOME/src/` 配下の `.claude/skills/` | 各リポジトリ固有のskill |

⚠️ **注意**: `$HOME` 全体をスキャンしないでください。上記のディレクトリのみを調査対象とします。

### 既存skillとの重複を避ける手順

1. **既存skillをリストアップ**
   ```
   /skills
   ```

2. **類似する名前・descriptionがないか確認**
   - 同じ技術要素を扱うskillがないか
   - 同じ目的のskillがないか

3. **既存skillを読んで、コンテンツの重複をチェック**
   - セクション構成を確認
   - 既存コンテンツとの重複度を評価

4. **重複する場合は統合を検討**
   - チェックリストと判断フローを使用
   - 迷った場合は統合を優先（skillの数を抑える）

## クイックリファレンス

Skill作成の6ステップを実行します。

### Skill作成の6ステップ

```
1. 既存skillを確認（重複チェック）
   ↓
2. 統廃合判断（チェックリスト活用）
   ↓
3. ディレクトリ作成
   └─ ~/.claude/skills/[skill-name]/    （ユーザースコープ）
   └─ .claude/skills/[skill-name]/      （プロジェクトスコープ）
   ↓
4. SKILL.md作成（frontmatter + 必須セクション）
   ↓
5. コンテンツ記述（スタイルガイド準拠）
   ↓
6. 検証（/skills コマンドで認識確認）
```

### ステップ詳細

#### ステップ1: 既存skillを確認

```
/skills
```

類似するskillがないか確認します。

#### ステップ2: 統廃合判断

チェックリストと判断フローを使用して、新しいskillを作成すべきか既存skillに統合すべきか判断します。

#### ステップ3: ディレクトリ作成

```bash
# ユーザースコープ（全プロジェクトで使用）
mkdir -p ~/.claude/skills/[skill-name]/

# プロジェクトスコープ（特定プロジェクトのみ）
mkdir -p .claude/skills/[skill-name]/
```

#### ステップ4: SKILL.md作成

```markdown
---
name: skill-name
description: [1-2文の説明。使用タイミングを含める。]
---

# [Skill名]

このスキルは、[目的]を提供します。

## [主要セクション]

内容...
```

#### ステップ5: コンテンツ記述

- 5段階ピラミッド構造に従う
- ✅/❌、絵文字、テーブルを活用
- コードブロックに言語を指定

#### ステップ6: 検証

```
/skills
```

作成したskillが表示されることを確認します。

## トラブルシューティング

Skillが認識されない、または期待通りに動作しない場合のチェックポイント。

### Skillが認識されない

**症状**: `/skills`コマンドで表示されない

**チェックポイント**:

1. **ファイルパスの確認**
   ```bash
   # ユーザースコープ
   ls ~/.claude/skills/[skill-name]/SKILL.md

   # プロジェクトスコープ
   ls .claude/skills/[skill-name]/SKILL.md
   ```

2. **frontmatterの書式確認**
   ```yaml
   ---
   name: skill-name
   description: 説明文
   ---
   ```
   - `---`で開始・終了しているか
   - `name:`または`skill_invocation:`が存在するか
   - `description:`が存在するか
   - YAMLインデントが正しいか（スペース2個）

3. **ファイル名の確認**
   - ファイル名は `SKILL.md`（大文字）
   - 拡張子は `.md`

### descriptionが表示されない

**症状**: Skill名は表示されるが、説明文が表示されない

**チェックポイント**:

1. **YAML構文エラー**
   - コロン(`:`)の後にスペースがあるか
   - 引用符が不要な箇所で使っていないか
   - 改行が適切か

2. **description内容**
   - 空文字列でないか
   - 特殊文字（`"`、`'`、`:`）が含まれていないか
   - 含まれる場合はYAML文法に従ってエスケープ

### 複数ファイルの整理

**症状**: Skillが300行を超えて読みにくい

**解決方法**:

1. **reference.mdへの分割を検討**
   - クイックガイド → SKILL.md
   - 詳細資料 → reference.md

2. **リンクの追加**
   ```markdown
   ## 詳細情報

   より詳しい情報は [reference.md](reference.md) を参照してください。
   ```

## 参考資料

### 公式ドキュメント

- [Claude Code Skills公式ドキュメント](https://code.claude.com/docs/en/skills)
- [Skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)

### macOS関連リソース

- [Homebrew公式サイト](https://brew.sh)
- [macOSターミナルコマンドリファレンス](https://ss64.com/osx/)
- [XDG Base Directory仕様](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)

### 既存skillの参照例

プロジェクトスコープの既存skillを参照して、構成やスタイルを学ぶことができます:

**macOS環境設定系skill**:
- `.claude/skills/homebrew-setup/` - Homebrewツール管理
- `.claude/skills/macos-defaults/` - macOS設定管理

**シンプルな構成（SKILL.mdのみ）**:
- `.claude/skills/check-dependencies/`
- `.claude/skills/bruno-fix-child-process/`

**複数ファイル構成（SKILL.md + reference.md）**:
- `.claude/skills/jacoco-coverage/`
- `.claude/skills/gradle-dependency-best-practices/`

### ユーザースコープとプロジェクトスコープ

**ユーザースコープ** (`~/.claude/skills/`):
- 全プロジェクトで共通して使用するskill
- 例: このskill作成ガイド

**プロジェクトスコープ** (`.claude/skills/`):
- 特定プロジェクト固有のskill
- 例: AプロジェクトのGradle設定、JaCoCo設定
