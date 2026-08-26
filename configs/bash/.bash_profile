# Enable Bash vi mode
set -o vi

if [ -f ~/.bash_profile ]; then
    alias resource='source ~/.bash_profile'
else
    alias resource='source ~/.bashrc'
fi;

######################################
#                PS1                 #
######################################
PROMPT_COLOR="33"

# Get bash auto-complete if it doesn't exist
if [ ! -f ~/.git-completion.bash ]; then
  curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash > ~/.git-completion.bash
fi

# Set the git branch color based on status
# set_git_prompt() {
#     local branch=$(git branch --show-current 2>/dev/null)
#
#     if [ -n "$branch" ]; then
#         local git_status="$(git status --porcelain 2>/dev/null)"
#         local color="32" # Default green
#
#         if [ -n "$git_status" ]; then
#             if git status 2>/dev/null | grep -q "Changes to be committed"; then
#                 color="33" # Yellow (staged)
#             else
#                 color="31" # Red (unstaged)
#             fi
#         elif git status 2>/dev/null | grep -q "Your branch is ahead"; then
#             color="36" # Cyan (ahead)
#         fi
#
#         # Store just the color code and branch name
#         GIT_COLOR="$color"
#         GIT_BRANCH="$branch"
#     else
#         GIT_COLOR=""
#         GIT_BRANCH=""
#     fi
# }

set_git_prompt() {
    local branch=$(git branch --show-current 2>/dev/null)
    local git_part=""

    if [ -n "$branch" ]; then
        local git_status="$(git status --porcelain 2>/dev/null)"
        local color="32"

        if [ -n "$git_status" ]; then
            if git status 2>/dev/null | grep -q "Changes to be committed"; then
                color="33"
            else
                color="31"
            fi
        elif git status 2>/dev/null | grep -q "Your branch is ahead"; then
            color="36"
        fi

        git_part="(\001\033[1;${color}m\002${branch} ⛙\001\033[0m\002)"
    fi

    PS1="\001\033[4;1;${PROMPT_COLOR}m\002\w\001\033[0m\002${git_part}\$ "
}

# Update prompt before each command
PROMPT_COMMAND=set_git_prompt

# Build PS1 with proper escaping done at PS1 evaluation time
export PS1='\[\033[4;1;${PROMPT_COLOR}m\]\w\[\033[0m\]${GIT_BRANCH:+(\[\033[1;${GIT_COLOR}m\]${GIT_BRANCH} ⛙\[\033[0m\])}$ '
# export PS1='\[\033[4;1;${PROMPT_COLOR}m\]\w\[\033[0m\]${GIT_BRANCH:+(}\[\033[1;${GIT_COLOR}m\]${GIT_BRANCH} ⛙\[\033[0m\]${GIT_BRANCH:+)}$ '

######################################
#              Aliases               #
######################################
alias ll="ls -la"
alias gdi="killall Dock"
alias grep="grep --color"
alias vi="vim"

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

######################################
#              Git Cmds              #
######################################
alias gst="git status"
alias git-merged="git branch --merged | grep -v '\*' | grep -v 'master' | grep -v 'main'"
alias git-prune="git-prune-branches"
alias git-rebase="git-rebase-default"

# git-machete
source $CODE_PATH/dotfiles/configs/completions/git-machete-completions.bash
alias gm="git machete"
complete -o default -o nospace -F _git_machete gm

# Prune branches that have been merged
git-prune-branches() {
  echo "Pruning branches..."
  branches=$(git-merged)

  if [ -z "$branches" ]; then
    echo "No branches to prune."
  else
    echo "Branches to be pruned:"
    echo "$branches"
    echo "$branches" | xargs git branch -d
  fi
}

## Rebase with the default branch in repo, default is 'main'
git-rebase-default() {
  default_branch=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')

  if [ -z "$default_branch" ]; then
    default_branch="main"
    echo "No default branch found, trying 'origin/$default_branch'."
  fi

  echo "Rebasing with 'origin/$default_branch' ..."
  git fetch && git rebase origin/$default_branch && echo "done."
}
