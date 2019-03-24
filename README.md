dotfiles
===

## bootstrap

### [homebrew](https://brew.sh/index_ja)

    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

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

## git

    brew install git
    cp /usr/local/opt/git/etc/bash_completion.d/git-completion.bash .git-completion.bash
    ln -sfn $(pwd)/gitconfig_global ~/.gitconfig
    ln -sfn $(pwd)/gitignore_global ~/.gitignore_global

## fonts

### ricty-powerline

    brew tap sanemat/font
    brew install ricty --with-powerline
    cp -f /usr/local/opt/ricty/share/fonts/Ricty*.ttf ~/Library/Fonts/
    fc-cache -vf

## misc
* [sdkman](https://sdkman.io/)
