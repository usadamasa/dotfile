dotfiles
===

## bootstrap

```sh
# install [homebrew](https://brew.sh/index_ja)
$ /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# clone this repo
$ brew install git
$ brew install ghq
$ export GHQ_ROOT=~/src
$ ghq get https://github.com/usadamasa/dotfile.git
$ cd ~/src/github.com/usadamasa/dotfile

# install packages
$ brew bundle
```

## link configs

### zsh

```sh
# enable XDG Base Directory
$ ln -sfn $(pwd)/.zshenv ~/
# reboot terminal
$ mkdir -p ~/.config

# oh-my-zsh
$ sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# symlink
$ rm -rf ~/.config/zsh
$ ln -sfn $(pwd)/config/zsh ~/.config/
```

### git

```
$ ln -sfn $(pwd)/config/git ~/.config/
```

### vim
```sh
# link
$ ln -sfn $(pwd)/vimdir ~/.vim
$ ln -sfn $(pwd)/vimrc ~/.vimrc

# [powerline-shell](https://github.com/b-ryan/powerline-shell)
$ pipx install powerline-shell
```

## maintenances

### Sync Brewfile

```sh
$ brew bundle cleanup
$ brew bundle dump
```

## misc
* [sdkman](https://sdkman.io/)
* [google-cloud-sdk](https://cloud.google.com/sdk/downloads?hl=JA)
