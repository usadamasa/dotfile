---
name: draft-pr-with-squash
description: コミットをsquashして1つに集約し、Draft PRを作成するワークフロー。複数のコミットを1つに整理してからPRを作成します。
allowed-tools: Bash(git:*), Bash(gh:*)
---

# draft-pr-with-squash

このskillは、現在のブランチの複数のコミットを1つに集約し、Draft PRを作成するワークフローを実行します。

## 概要

1. 分岐元ブランチをgitの追跡情報から自動検出
2. 分岐元からのコミット状況を確認し、適切な方法でコミットを準備
   - **差分コミットがある場合**: `git rebase` で1つに集約（squash）
   - **差分コミットがないが未コミット変更がある場合**: 新規コミットを作成
3. コミットメッセージをユーザーに確認
4. `git push --force-with-lease` でプッシュ
5. PRテンプレートを自動検出（存在する場合）
6. PRが存在しなければ `gh pr create --draft` で新規作成（テンプレートがあれば使用）
7. PRが存在すれば `gh pr edit` でタイトル/内容を更新

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status --short`
- Recent commits: !`git log --oneline -5`

## Your Task

以下の手順を実行してください：

### 1. 分岐元ブランチの自動検出

GitHub CLIでリポジトリのデフォルトブランチを取得：
```bash
BASE=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)
```

### 2. 前提条件の確認
- 現在のブランチが分岐元ブランチと異なることを確認
- 分岐元ブランチが存在することを確認
- 分岐元からのコミット数を確認: `git rev-list --count origin/$BASE..HEAD`
  - **コミットが1つ以上ある場合** → 通常のsquashフローへ進む（ケースA）
  - **コミットがない場合** → `git status --porcelain` を確認
    - 未コミット変更がある → 新規コミット作成フローへ進む（ケースB）
    - 変更もない → **エラー**: 変更がないためPR作成不可

### 3. コミット準備

#### ケースA: 差分コミットがある場合（rebase squashフロー）

1. **未コミット変更がある場合は先にコミット**
   ```bash
   git add -A
   git commit -m "WIP"
   ```

2. **非対話的rebaseでsquash**
   ```bash
   GIT_SEQUENCE_EDITOR="sed -i '' '2,\$s/^pick/squash/'" git rebase -i origin/$BASE
   ```

3. **コミットメッセージの確認**
   - ユーザーにコミットメッセージを確認し、必要に応じて `git commit --amend` で修正

#### ケースB: 差分コミットがない場合（新規コミットフロー）
- 全変更をステージング: `git add -A`
- 新規コミットを作成（メッセージはユーザーに確認）

### 4. コミットメッセージ確認
- ユーザーにコミットメッセージを提示
- 必要に応じて `git commit --amend` で修正

### 5. Force Push（安全版）
- `git push --force-with-lease origin <current-branch>` でプッシュ
- push に失敗した場合はエラーメッセージを表示

### 6. PRテンプレートの検出

GitHub CLIでリポジトリのPRテンプレートを自動検出：

```bash
# テンプレート情報を取得（ファイル名と内容が含まれる）
TEMPLATES_JSON=$(gh repo view --json pullRequestTemplates -q '.pullRequestTemplates')
TEMPLATE_COUNT=$(echo "$TEMPLATES_JSON" | jq 'length')
```

**テンプレートが1つの場合：**
- そのテンプレートのファイル名を使用

**複数テンプレートがある場合：**
- テンプレート一覧を表示してユーザーに選択を促す

```bash
if [[ "$TEMPLATE_COUNT" -eq 1 ]]; then
  TEMPLATE_FILE=$(echo "$TEMPLATES_JSON" | jq -r '.[0].filename')
elif [[ "$TEMPLATE_COUNT" -gt 1 ]]; then
  echo "複数のPRテンプレートが見つかりました："
  echo "$TEMPLATES_JSON" | jq -r 'to_entries[] | "\(.key + 1). \(.value.filename)"'
  # ユーザーに選択を促す（AskUserQuestionツールで実装）
fi
```

**テンプレートがない場合：**
- テンプレートなしで従来通り作成

### 7. PRの作成または更新

1. **既存PRの確認**
   ```bash
   gh pr view --json number 2>/dev/null
   ```

2. **PRが存在しない場合: 新規作成**
   - テンプレートが見つかった場合：
     ```bash
     gh pr create --draft --base $BASE --template "$TEMPLATE_FILE"
     ```
   - テンプレートが見つからない場合：
     ```bash
     gh pr create --draft --base $BASE
     ```

3. **PRが存在する場合: 更新**
   - `gh pr edit --title "..." --body "..."` でタイトルと内容を更新
   - force pushは既に完了しているのでコミットは反映済み

## 考慮事項

- **分岐元自動検出**: `gh repo view` でリポジトリのデフォルトブランチを取得
- **非対話的rebase**: `GIT_SEQUENCE_EDITOR` を使って対話的なエディタを回避し、自動的にsquashを実行
- **--force-with-lease**: 他のユーザーの変更を検出する安全な force push
- **PRのベースブランチ**: 検出した分岐元を `--base` オプションで指定
- **既存PR対応**: PRが存在すれば`gh pr edit`でタイトル/内容を更新
- **差分コミットなしのケース**: 新規ブランチで作業開始直後など、まだコミットがない状態でもPRを作成可能
- **未コミット変更の扱い**:
  - 差分コミットがある場合: 先にWIPコミットしてからrebaseでsquash
  - 差分コミットがない場合: 変更をそのまま新規コミットとして作成
- **変更なしエラー**: 差分コミットも未コミット変更もない場合はPR作成の意味がないためエラーとする
- **rebase失敗時**: コンフリクトが発生した場合は `git rebase --abort` で中止し、ユーザーに手動解決を促す
- **PRテンプレート自動検出**: `gh repo view --json pullRequestTemplates`でテンプレートを自動検出し、`gh pr create --template`で使用
- **複数テンプレート対応**: 複数テンプレートがある場合はユーザーに選択を促す
- **テンプレートがない場合**: テンプレートが存在しないリポジトリでは従来通りの動作を維持（後方互換性）
