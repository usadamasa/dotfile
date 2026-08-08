# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

### Initial Setup (Recommended)
```sh
# Clone repository (install Homebrew first if not available)
# /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install git ghq
export GHQ_ROOT=~/src
ghq get https://github.com/usadamasa/dotfile.git
cd ~/src/github.com/usadamasa/dotfile

# Run initial setup (Homebrew + go-task + complete setup)
task bootstrap
```

## テスト・フォーマット

```sh
task test    # bats でシェルスクリプトのテストを実行 (tests/*.bats)
task format  # editorconfig-checker で .editorconfig 準拠をチェック
```

シェルスクリプトを Edit/Write すると、`.claude/hooks/lint-shell.sh` が PostToolUse
フックとして自動的に `shellcheck` と `editorconfig-checker` をかけ、指摘があれば
その場でフィードバックする (設定は `.claude/settings.json`)｡

## シェルスクリプト開発ガイド

### ディレクトリ構成

- 実行可能なスクリプトは `config/<tool>/` 配下に配置 (例: `config/git/git-mc`)
- 対応するテストは `tests/<name>.bats` に配置
- テスト用フィクスチャは `tests/fixtures/`、ヘルパーは `tests/helpers/`

### テストの作法 (bats-core)

- `@test` ごとに正常系・異常系の両方をカバー
- 一時ディレクトリは `BATS_TEST_TMPDIR` を使い自動クリーンアップ
- `setup` / `teardown` で前提条件を整える
- git 関連機能は通常 clone / bare repo / worktree の各コンテキストからテストする
  (詳細はプロジェクトスキル `git-context-testing` を参照)

### コーディング規約

- 変数展開は原則ダブルクォートで囲む (`"$VAR"`)
- `readonly` と代入は分離する (`VAR=$(cmd); readonly VAR`)
- コメント・エラーメッセージは日本語

`set -euo pipefail` と `printf` の使用方針はグローバル CLAUDE.md の
"Shell Script Quality" に記載。

## Code Formatting Guidelines

When working with long commands in this repository:
- Use backslashes (`\`) for line breaks in multi-argument commands
- Sort options and packages alphabetically when syntactically appropriate
- Maintain consistent indentation for readability
- Follow the established pattern in existing commands (e.g., `brew install` formatting)

## Claude Code Configuration

Claude Code のグローバル設定は **`usadamasa/claude-config`** リポジトリで管理されています｡

```sh
ghq get github.com/usadamasa/claude-config
cd ~/src/github.com/usadamasa/claude-config
task setup
```

`task setup` / `task status` / `task clean` は dotfile の Taskfile.yml から自動的に委譲されます｡
claude-config が未クローンの場合は警告メッセージが表示されます｡

### Note on Skill Scope
- **Global skills** → `usadamasa/claude-config` リポジトリの `skills/` に配置 (全プロジェクトで利用可能)
- **Project-specific skills** → プロジェクトの `.claude/skills/` に配置
