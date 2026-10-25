# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

### Initial Setup (Recommended)
```sh
# 新しい Mac で何も入れずに流す。bootstrap.sh が Homebrew・Nix・clone・task setup まで行う
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/usadamasa/dotfile/main/bootstrap.sh)"
```

導入済みのマシンで設定を収束させるのは `task setup`。

## テスト・フォーマット

```sh
task test    # bats でシェルスクリプトのテストを実行 (tests/*.bats)
task format  # editorconfig-checker で .editorconfig 準拠をチェック
```

シェルスクリプトを Edit/Write すると、`.claude/hooks/lint-shell.sh` が PostToolUse
フックとして自動的に `shellcheck` と `editorconfig-checker` をかけ、指摘があれば
その場でフィードバックする (設定は `.claude/settings.json`)｡

### 開発ツールの devShell

テストと lint のツールは `flake.nix` の devShell に置き、direnv (`.envrc`) で読み込む。
`task nix:check-flake` で flake を検証し、`task nix:update` で nixpkgs を進める。
flake.lock は Dependabot (`.github/dependabot.yml`) も週次で更新する。
`lint-shell.sh` フックは claude を起動したシェルの PATH で動くので、リポジトリ内のシェルから claude を起動する。

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

Claude Code のグローバル設定は **`usadamasa/claude-config`** リポジトリで管理する｡

```sh
ghq get github.com/usadamasa/claude-config
cd ~/src/github.com/usadamasa/claude-config
task setup
```

dotfile の Taskfile.yml は claude-config の task を呼ばない｡claude-config 側のセットアップは上のコマンドで別に行う｡

### Note on Skill Scope
- **Global skills** → `usadamasa/claude-config` リポジトリの `skills/` に配置 (全プロジェクトで利用可能)
- **Project-specific skills** → プロジェクトの `.claude/skills/` に配置
