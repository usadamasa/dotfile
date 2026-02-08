# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Architecture

This is a personal dotfiles repository for macOS development environment setup. The structure follows XDG Base Directory standards:

- `config/` - Contains all configuration files organized by tool
  - `claude/` - Claude Code configuration (symlinked to `~/.claude`)
    - `CLAUDE.md` - Global Claude Code instructions
    - `settings.json` - Permissions, plugins, model settings
    - `skills/` - Global skills (available in all projects)
    - `commands/` - Custom commands
  - `git/` - Git configuration and global gitignore
  - `npm/` - npm configuration with custom registry and cache settings
  - `vim/` - Vim configuration with XDG compliance and plugin management
  - `zsh/` - Zsh configuration with oh-my-zsh integration
- `cmd/` - Go CLI ツール群
  - `<コマンド名>/` - 各コマンドのソースとテスト (package main)
  - `Taskfile.yml` - Go 関連タスク定義 (go namespace)
- `go.mod` - Go モジュール定義 (リポジトリルート)
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

## Go CLI ツール開発ガイド

### ディレクトリ構成

```
cmd/
└── <コマンド名>/
    ├── main.go           # エントリポイント (package main)
    ├── main_test.go      # main.go のテスト
    ├── <機能>.go          # 機能ごとにファイル分割
    └── <機能>_test.go     # 対応するテスト
```

- 1コマンド = 1ディレクトリ｡全ファイル `package main`
- `go.mod` はリポジトリルートに配置済み (module: `github.com/usadamasa/dotfile`)
- 外部依存は最小限に｡標準ライブラリで済むならそれで良い

### タスク実行

```sh
task go:test     # 全 cmd パッケージのテスト実行
task go:test-v   # 詳細モード (-v)
task go:vet      # 静的解析
task go:build    # ビルド
task test        # bats + Go テストを統合実行
```

### 新しいコマンドの追加手順

1. `cmd/<コマンド名>/` ディレクトリを作成
2. `main.go` に `package main` と `func main()` を定義
3. テストファイル `*_test.go` を同ディレクトリに配置
4. `task go:test` で自動的にテスト対象に含まれる (`./cmd/...`)

### テストの作法

- テーブル駆動テスト + `t.Run()` でサブテスト化
- 一時ファイルは `t.TempDir()` を使い自動クリーンアップ
- テスト用ヘルパー関数はテストファイル内に定義 (例: `writeTestFile`)
- 正常系と異常系の両方をカバー

### コーディング規約

- コメント､エラーメッセージ､CLI の説明文は日本語
- CLIフラグは `flag` パッケージを使用
- エラーは `fmt.Fprintf(os.Stderr, ...)` で出力し `os.Exit(1)`
- 構造化出力は JSON で stdout に出力

## Code Formatting Guidelines

When working with long commands in this repository:
- Use backslashes (`\`) for line breaks in multi-argument commands
- Sort options and packages alphabetically when syntactically appropriate
- Maintain consistent indentation for readability
- Follow the established pattern in existing commands (e.g., `brew install` formatting)

## Claude Code Configuration

This repository manages Claude Code configuration at the global user level.

### Symlink Structure
The `config/claude/` directory is symlinked to `~/.claude` during `task setup`.
This means all configurations in this directory apply globally to all projects.

### Global Skills
Skills in `config/claude/skills/` are available across all projects:
- `usadamasa-draft-pr` - Draft PR creation workflow with fixup commits
- `usadamasa-skill-creation-guide` - Guide for creating Claude Code skills
- `content-research-writer` - Content writing assistant with research
- `cdp-confluence-guide` - CADDi Data Platform Confluence guide

### Adding New Global Skills
```sh
# Create skill directory and SKILL.md
mkdir -p config/claude/skills/<skill-name>
touch config/claude/skills/<skill-name>/SKILL.md

# Verify skill is recognized
# Run /skills in Claude Code
```

### Note on Skill Scope
- **Global skills** → Place in `config/claude/skills/` (applies to all projects)
- **Project-specific skills** → Place in `.claude/skills/` within the project repository
