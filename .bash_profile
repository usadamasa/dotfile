if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/Users/usadamasa/.sdkman"
[[ -s "/Users/usadamasa/.sdkman/bin/sdkman-init.sh" ]] && source "/Users/usadamasa/.sdkman/bin/sdkman-init.sh"

[ -f ~/.git-completion.bash ] && . ~/.git-completion.bash

function _update_ps1() {
    PS1=$(powerline-shell $?)
}

if [[ $TERM != linux && ! $PROMPT_COMMAND =~ _update_ps1 ]]; then
    PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"
fi
