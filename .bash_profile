if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

# golang
export GOPATH=$(go env GOPATH)
export PATH=$PATH:${GOPATH}/bin
export GO111MODULE=on

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="${HOME}/.sdkman"
[[ -s "${HOME}/.sdkman/bin/sdkman-init.sh" ]] && source "${HOME}/.sdkman/bin/sdkman-init.sh"

[ -f ~/.git-completion.bash ] && . ~/.git-completion.bash

function _update_ps1() {
    PS1=$(powerline-shell $?)
}

if [[ $TERM != linux && ! $PROMPT_COMMAND =~ _update_ps1 ]]; then
    PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"
fi

# The next line updates PATH for the Google Cloud SDK.
if [ -f "${HOME}/google-cloud-sdk/path.bash.inc" ]; then . "${HOME}/google-cloud-sdk/path.bash.inc"; fi

# The next line enables shell command completion for gcloud.
if [ -f "${HOME}/google-cloud-sdk/completion.bash.inc" ]; then . "${HOME}/google-cloud-sdk/completion.bash.inc"; fi
