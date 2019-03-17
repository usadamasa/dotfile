dotfiles
===

## vim

### dein

    curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh > installer.sh
    mkdir -p ~/.cache
    sh ./installer.sh ~/.cache/dein


### link

    ln -sfn $(pwd)/vimdir ~/.vim
    ln -sfn $(pwd)/vimrc ~/.vimrc

## bash

    ln -sfn $(pwd)/.bashrc ~/.bashrc

