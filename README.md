dotfiles
===

## bootstrap

### [homebrew](https://brew.sh/index_ja)

    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

### git

    brew install git
    cp /usr/local/opt/git/etc/bash_completion.d/git-completion.bash .git-completion.bash


### clone this repo.

    mkdir -p workspace
    git clone git@github.com:usadamasa/dotfile.git
    cd dotfile
    ln -sfn $(pwd)/gitconfig_global ~/.gitconfig
    ln -sfn $(pwd)/gitignore_global ~/.gitignore_global


## bash

    ln -sfn $(pwd)/.bashrc ~/.bashrc
    ln -sfn $(pwd)/.bash_profile ~/.bash_profile

### [powerline-shell](https://github.com/b-ryan/powerline-shell)

    brew install python3
    pip3 install powerline-shell

## vim

    brew install vim

### link

    ln -sfn $(pwd)/vimdir ~/.vim
    ln -sfn $(pwd)/vimrc ~/.vimrc

### dein

    curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh > /tmp/installer.sh
    mkdir -p ~/.cache
    sh /tmp/installer.sh ~/.cache/dein

## fonts

### cica

Download from https://github.com/miiton/Cica/releases .

## misc
* [sdkman](https://sdkman.io/)
* [google-cloud-sdk](https://cloud.google.com/sdk/downloads?hl=JA)
