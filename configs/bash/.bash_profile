alias resource='source ~/.bash_profile'
alias ll="ls -la"
alias gdi="killall Dock"
alias grep="grep --color"
alias vi="vim"
alias gst="git status"

alias ctags="/usr/local/bin/ctags"

PROMPT_COLOR=33
export PS1='\[\033[4;1;${PROMPT_COLOR}m\]\w\[\033[0m\]$(__git_ps1 "(%s)")$ '

if [ -f $(brew --prefix)/etc/bash_completion ]; then
    . $(brew --prefix)/etc/bash_completion
fi

code() {
    cd "$CODE_PATH/$1"
}
