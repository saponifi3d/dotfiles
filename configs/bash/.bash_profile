if [ -f ~/.bash_profile ]; then
    alias resource='source ~/.bash_profile'
else
    alias resource='source ~/.bashrc'
fi;

alias ll="ls -la"
alias gdi="killall Dock"
alias grep="grep --color"
alias vi="vim"
alias gst="git status"

alias ctags="/usr/local/bin/ctags"
alias jtags="ctags -R . && sed -i '' -E '/^(if|switch|function|module\.exports|it|describe).+language:js$/d' tags"

PROMPT_COLOR=33
if [ -f ~/.git-prompt.sh ]; then
    source ~/.git-prompt.sh
    export PS1='\[\033[4;1;${PROMPT_COLOR}m\]\w\[\033[0m\]$(__git_ps1 "(%s)")$ '

    if [ ! -f ~/.git-completion.bash ]; then
      curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash > ~/.git-completion.bash
    fi

    source ~/.git-completion.bash
else
    export PS1='\[\033[4;1;${PROMPT_COLOR}m\]\w\[\033[0m\]$ '
fi;

export GIT_EDITOR=vim
export EDITOR=vim
export BASH_SILENCE_DEPRECATION_WARNING=1
export PATH=$PATH:~/go/bin

if [ -x "$(command -v brew)" ]; then
    if [ -f $(brew --prefix)/etc/bash_completion ]; then
        . $(brew --prefix)/etc/bash_completion
    fi;
fi;

clone() {
    git clone git@github.com:$1.git
}

####### CODE COMMAND ########

# tab-complete for 'code'
function _codePaths() {
    local paths=("$CODE_PATH/$2"*)
    [[ -e ${paths[0]} ]] && COMPREPLY=( "${paths[@]##*/}" )
}

complete -F _codePaths code

# quickly change between repos
code() {
    if [ -z "$1" ]; then
        cd $CODE_PATH
    else
        cd "$CODE_PATH/$1"
    fi;
}
#
#############################

function monorepo() {
    changed_dir="false"

    if [ $# -eq 1 ]; then
        cd $CODE_PATH/$1
        changed_dir="true"
    else
        IN=`node -pe 'JSON.parse(process.argv[1]).workspaces.toString()' "$(cat $CODE_PATH/$1/package.json)"`
        IFS=',' read -r -a workspaces <<< "$IN"

        for workspace in "${workspaces[@]}"
        do
            :
            path=${workspace%??}
            if [[ -d $CODE_PATH/$1/$path/$2 ]]; then
                cd $CODE_PATH/$1/$path/$2
                changed_dir="true"
            fi;
        done
    fi;

    if [[ "$changed_dir" == "false" ]]; then
        echo "Couldn't find $2 in $1"
        return 1
    fi;
}
