# dotfiles

## bootstrap

```sh
# install [homebrew](https://brew.sh)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# clone this repo
brew install git ghq
export GHQ_ROOT=~/src
ghq get https://github.com/usadamasa/dotfile.git
cd ~/src/github.com/usadamasa/dotfile
```

## zsh

```sh
brew install zsh
# enable XDG Base Directory
ln -sfn $(pwd)/.zshenv ~/
# reboot terminal
mkdir -p ~/.config

# oh-my-zsh
sh -c "$(curl -fsSL https://install.ohmyz.sh/)"

# symlink
rm -rf ~/.config/zsh
ln -sfn $(pwd)/config/zsh ~/.config/

git clone https://github.com/zsh-users/zsh-autosuggestions \
  ${ZSH_CUSTOM}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
  ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting
```

## git

```sh
ln -sfn $(pwd)/config/git ~/.config/
```

## vim

```sh
# XDG Base Directory 対応
mkdir -p ~/.config/vim
mkdir -p ~/.local/share/vim
mkdir -p ~/.cache/vim/{swap,backup}

ln -sfn $(pwd)/config/vim ~/.config/

# [powerline-shell](https://github.com/b-ryan/powerline-shell)
brew install pipx
pipx install powerline-shell
```

## npm

```sh
ln -sfn $(pwd)/config/npm ~/.config/
ln -sfn $(pwd)/config/npm/npmrc ~/.npmrc
```

## Others

```sh
brew install \
  direnv \
  git-now \
  gh \
  jq \
  peco \
  tig

# cask
brew install --cask \
  font-cica \
  jetbrains-toolbox \
  visual-studio-code

# gh extensions
gh extension install \
  seachicken/gh-poi

```

## misc

* [sdkman](https://sdkman.io/)
* [google-cloud-sdk](https://cloud.google.com/sdk/downloads)
* [gh-poi](https://github.com/seachicken/gh-poi)
