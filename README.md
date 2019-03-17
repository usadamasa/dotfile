dotfiles
===

## python
* pyenv

## vim

### dein

    curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh > installer.sh
    mkdir -p ~/.cache
    sh ./installer.sh ~/.cache/dein


### link

    ln -sfn vimdir ~/.vim
    ln -sfn vimrc ~/.vimrc

## bash

    ln -sfn .bashrc ~/.bashrc

## powerline

copy font

    cp fonts/* ~/Library/Fonts/


install powerline

    pip install powerline-shell
