# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Architecture

This is a personal dotfiles repository for macOS development environment setup. The structure follows XDG Base Directory standards:

- `config/` - Contains all configuration files organized by tool
  - `git/` - Git configuration and global gitignore
  - `npm/` - npm configuration with custom registry and cache settings
  - `vim/` - Vim configuration with XDG compliance and plugin management
  - `zsh/` - Zsh configuration with oh-my-zsh integration
  - `git/git-mc` - 自作 git サブコマンド (シェルスクリプト)
- `tests/` - bats-core によるシェルスクリプトのテスト (`*.bats`)
- `Taskfile.yml` - go-task のタスク定義 (セットアップ/テスト/フォーマット)
- `Brewfile` - Homebrew で管理する依存ツール一覧
- `.zshenv` - XDG environment variables (symlinked to home directory)

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

### Regular Setup (when go-task is already installed)
```sh
# Run complete setup (installs all tools via Homebrew)
task setup

# Check setup status
task status
```

### Tool Management
```sh
# Update all Homebrew tools
brew update && brew upgrade

# List installed Homebrew tools
brew list

# Search for tools
brew search <tool-name>

# Check tool info
brew info <tool-name>
```

## Modern Installation Process

The repository has been modernized with automated dependency management:

### Tools Used
- **Homebrew**: Unified package manager for all development tools
- **go-task**: Modern task runner with dependency management (replaces Makefile)

### Installation Flow
1. **Bootstrap**: Install Homebrew → install go-task → run automated setup
2. **Tool Management**: Homebrew installs and manages all development tools
3. **Task Execution**: go-task handles dependency resolution and idempotent operations
4. **Configuration**: XDG-compliant directory structure with atomic symlink operations
5. **Shell Setup**: oh-my-zsh and plugins installed with proper dependency ordering
6. **Verification**: Built-in status checking and error recovery

### Key Improvements
- **Task-centric**: All setup logic unified in Taskfile.yml
- **Homebrew-only**: Simplified tool management with single package manager
- **Rich Logging**: Emoji-enhanced progress and status reporting
- **Idempotent**: Safe to run multiple times without side effects
- **Dependency Resolution**: Tasks run in correct order with explicit dependencies
- **Error Handling**: Graceful failure recovery and status reporting
- **Zero External Dependencies**: Only requires Homebrew and go-task
- **Modular Tasks**: Individual components can be installed/updated separately

## XDG Compliance Tools

### xdg-ninja
Tool for checking XDG Base Directory compliance and identifying files in $HOME that should be moved to XDG directories.

```sh
# Check for XDG compliance violations
xdg-ninja

# Verbose mode - show all checked files
xdg-ninja --no-skip-ok
xdg-ninja -v

# Skip files without fixes (default behavior)
xdg-ninja --skip-ok

# Skip unsupported files
xdg-ninja --skip-unsupported
```

**Common XDG Environment Variables:**
- `XDG_CONFIG_HOME` - User-specific configuration files (`~/.config`)
- `XDG_DATA_HOME` - User-specific data files (`~/.local/share`)
- `XDG_STATE_HOME` - User-specific state files (`~/.local/state`)
- `XDG_CACHE_HOME` - User-specific cache files (`~/.cache`)
- `XDG_RUNTIME_DIR` - User-specific runtime files (`/run/user/$UID`)

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

- 冒頭に `set -euo pipefail` を記述する
- 変数展開は原則ダブルクォートで囲む (`"$VAR"`)
- `readonly` と代入は分離する (`VAR=$(cmd); readonly VAR`)
- `echo` より `printf '%s\n'` を優先する
- コメント・エラーメッセージは日本語

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
