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

### Bootstrap Process
```sh
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Clone repository
brew install git ghq
export GHQ_ROOT=~/src
ghq get https://github.com/usadamasa/dotfile.git
cd ~/src/github.com/usadamasa/dotfile
```

### Configuration Setup
```sh
# Enable XDG Base Directory
ln -sfn $(pwd)/.zshenv ~/

# Create config directory
mkdir -p ~/.config

# Symlink configurations
ln -sfn $(pwd)/config/zsh ~/.config/
ln -sfn $(pwd)/config/git ~/.config/
ln -sfn $(pwd)/config/vim ~/.config/
ln -sfn $(pwd)/config/npm ~/.config/

# Create vim directories
mkdir -p ~/.local/share/vim
mkdir -p ~/.cache/vim/{swap,backup}
```

### Tool Installation
```sh
# Core development tools
brew install zsh direnv git-now gh jq peco tig pipx

# oh-my-zsh and plugins
sh -c "$(curl -fsSL https://install.ohmyz.sh/)"
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting

# powerline-shell for vim
pipx install powerline-shell

# GUI applications
brew install --cask font-cica jetbrains-toolbox visual-studio-code

# GitHub extensions
gh extension install seachicken/gh-poi
```

## Installation Process

The repository uses symlinks to install configurations:
1. Clone to `~/src/github.com/usadamasa/dotfile` via ghq
2. Enable XDG Base Directory by symlinking `.zshenv`
3. Create necessary directories (`~/.config`, vim cache/data dirs)
4. Symlink configuration directories to `~/.config/`
5. Install shell framework (oh-my-zsh) and plugins
6. Install development tools via Homebrew