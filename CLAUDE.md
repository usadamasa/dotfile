# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Architecture

This is a personal dotfiles repository for macOS development environment setup. The structure follows XDG Base Directory standards where possible:

- `config/` - Contains all configuration files organized by tool
  - `git/` - Git configuration and global gitignore
  - `npm/` - npm configuration with custom registry and cache settings
  - `vim/` - Vim configuration with XDG compliance and plugin management
  - `zsh/` - Zsh configuration with oh-my-zsh integration
- `.zshenv` - XDG environment variables (symlinked to home directory)

## Development Environment

The setup assumes:
- macOS with Homebrew package manager
- Zsh as the default shell with oh-my-zsh framework
- XDG Base Directory specification compliance
- Multiple language runtimes managed via version managers (nvm, pyenv, rbenv, sdkman)

## Key Configuration Patterns

### XDG Base Directory Compliance
All configurations follow XDG standards:
- `XDG_CONFIG_HOME` for configuration files
- `XDG_DATA_HOME` for data files  
- `XDG_CACHE_HOME` for cache files

### Vim Configuration Structure
- Main config in `config/vim/vimrc` with XDG path setup
- Modular configuration via `userautoload/*.vim` files
- Plugin management with vim-plug

### Zsh Configuration Structure
- `.zshrc` handles oh-my-zsh setup and plugin loading
- `.zprofile` manages PATH and environment for various development tools
- Custom functions in `funcs/` directory
- History settings in separate `history_settings.sh`

## Code Style Guidelines

From `.windsurfrules`:
- Indentation: 2 spaces
- Line endings: LF
- Encoding: UTF-8
- Japanese language for documentation
- Conventional commit format: `type(scope): subject`

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

### Individual Tasks
```sh
# Check macOS environment
task check-macos

# Install only Homebrew
task install-homebrew

# Install go-task (initial setup version)
task install-go-task-initial

# Install only core development tools
task install-core-tools

# Setup only XDG directories
task setup-xdg

# Setup only zsh environment
task setup-zsh

# Setup only zsh plugins
task setup-zsh-plugins

# Setup only configuration symlinks
task setup-symlinks

# Setup only vim environment
task setup-vim

# Install additional tools (GUI apps, extensions)
task setup-additional-tools

# Clean up configuration (WARNING: removes config files)
task clean
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