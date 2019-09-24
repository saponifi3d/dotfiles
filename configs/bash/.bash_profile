alias resource='source ~/.bash_profile'
alias ll="ls -la"
alias gdi="killall Dock"
alias grep="grep --color"
alias vi="vim"
alias gst="git status"

alias ctags="/usr/local/bin/ctags"
alias jtags="ctags -R . && sed -i '' -E '/^(if|switch|function|module\.exports|it|describe).+language:js$/d' tags"

PROMPT_COLOR=33
export PS1='\[\033[4;1;${PROMPT_COLOR}m\]\w\[\033[0m\]$(__git_ps1 "(%s)")$ '

if [ -f $(brew --prefix)/etc/bash_completion ]; then
    . $(brew --prefix)/etc/bash_completion
fi

code() {
    if [ -z "$1" ]; then
        cd $CODE_PATH
    else
        cd "$CODE_PATH/$1"
    fi
}

function monorepo() {
    if [ $# -eq 1 ]; then
        cd $CODE_PATH/$1
    else
        IN=`node -pe 'JSON.parse(process.argv[1]).workspaces.toString()' "$(cat $CODE_PATH/$1/package.json)"`
        workspaces=$(echo $IN | tr "," "\n")

        for workspace in $workspaces
        do
            :
            path=${workspace%??}
            if [[ -d $CODE_PATH/$1/$path/$2 ]]; then
                cd $CODE_PATH/$1/$path/$2
            fi;
        done
    fi;
}
