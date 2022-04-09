dotfiles
===

## bootstrap

### [homebrew](https://brew.sh/index_ja)

    $ /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

### git

    $ brew install git


### clone this repo via [ghq](https://github.com/motemen/ghq).

    $ brew install ghq
    $ export GHQ_ROOT=~/src
    $ ghq get https://github.com/usadamasa/dotfile.git
    $ cd ~/src/github.com/usadamasa/dotfile

### brew

    $ brew bundle

## link

### enable XDG Base Directory

    $ ln -sfn $(pwd)/.zshenv ~/
    # reboot terminal
    $ mkdir -p ~/.config

### git

    $ ln -sfn $(pwd)/config/git ~/.config/


### zsh

    ## oh-my-zsh
    $ sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

    ## zsh-completions
    $ brew install zsh-completions
    $ fpath=(path/to/zsh-completions/src $fpath)
    $ rm -f ~/.zcompdump; compinit
    $ chmod go-w '/usr/local/share'

    ## symlink
    $ ln -sfn $(pwd)/config/zsh ~/.config/

### [powerline-shell](https://github.com/b-ryan/powerline-shell)

    $ brew install python3
    $ pip3 install powerline-shell


### link

    $ ln -sfn $(pwd)/vimdir ~/.vim
    $ ln -sfn $(pwd)/vimrc ~/.vimrc

### dein

    $ curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh > /tmp/installer.sh
    $ mkdir -p ~/.cache
    $ sh /tmp/installer.sh ~/.cache/dein

## fonts

### cica

Download from https://github.com/miiton/Cica/releases .

## misc
* [sdkman](https://sdkman.io/)
* [google-cloud-sdk](https://cloud.google.com/sdk/downloads?hl=JA)
