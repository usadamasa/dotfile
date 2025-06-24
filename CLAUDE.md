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

## Installation Process

The repository uses symlinks to install configurations:
1. Clone to `~/src/github.com/usadamasa/dotfile` via ghq
2. Create XDG directories
3. Symlink configuration directories to `~/.config/`
4. Install additional tools via Homebrew and package managers