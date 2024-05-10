if [ -f ~/.bash_profile ]; then
    alias resource='source ~/.bash_profile'
else
    alias resource='source ~/.bashrc'
fi;

######################################
#              Aliases               #
######################################
alias ll="ls -la"
alias gdi="killall Dock"
alias grep="grep --color"
alias vi="vim"

alias gst="git status"
alias git-merged="git branch --merged | grep -v '\*' | grep -v 'master' | grep -v 'main'"
alias git-prune="git-merged | xargs -n 1 git branch -d"
alias git-rebase="git fetch && git rebase origin/main"

git_color() {
    local git_status="$(git status 2> /dev/null)"
    local color="\033[1;32m" # Green by default (no changes)

    if [[ $git_status =~ "Your branch is ahead" ]]; then
        color="\033[1;36m" # Blue (commits to push)
    elif [[ $git_status =~ "nothing to commit" ]]; then
        color="\033[1;32m" # Green (no changes)
    elif [[ $git_status =~ "Changes not staged for commit" ]]; then
        color="\033[1;31m" # Red (uncommitted changes)
    elif [[ $git_status =~ "Changes to be committed" ]]; then
        color="\033[1;33m" # Yellow (changes staged)
    fi

    echo -ne $color
}

PROMPT_COLOR=33
if [ -f ~/.git-prompt.sh ]; then
    source ~/.git-prompt.sh
    export PS1='\[\033[4;1;${PROMPT_COLOR}m\]\w\[\033[0m\]$(__git_ps1 "($(git_color)%s ⛙\[\033[0m\])")$ '

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

######################################
#            CODE COMMAND            #
######################################
function _codePaths() {
    local paths=("$CODE_PATH/$2"*)
    [[ -e ${paths[0]} ]] && COMPREPLY=( "${paths[@]##*/}" )
}

complete -F _codePaths code

code() {
    if [ -z "$1" ]; then
        cd $CODE_PATH
    else
        cd "$CODE_PATH/$1"
    fi;
}


######################################
#            Monorepo Cmd            #
######################################
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
