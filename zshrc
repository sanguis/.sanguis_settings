# vim: set ft=zsh.shell
# Path to your oh-my-zsh installation.
# export DOTFILEDIR=$(realpath)

# EDITING THIS FILE
#  - when creating variables for a global path please do not use

# when sourced with $PROFILE=true profiling is turned on

[[ $PROFILE ]] && echo  -e "\033[32;1m[INFO]\033[0m Profileing On" && zmodload zsh/zprof

# Global Variables


## TODO figure out  why this does not work in an rcfile export _DOT_FILES_REPO==${0:A:h}
export _DOT_FILES_REPO=$HOME/.sanguis_settings
export _LOCAL_CONFIG_FILES_REPO=$HOME/.local_configs
export ZSH=$_DOT_FILES_REPO/oh-my-zsh
export ZSH_CUSTOM=$_DOT_FILES_REPO/zsh-custom

## Don't ask just update.
export DISABLE_UPDATE_PROMPT=true
export UPDATE_ZSH_DAYS=13

# enable auto-completeing
autoload bashcompinit && bashcompinit

## Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Tmux settings
[[ -z $TMUX_SESSION_NAME ]] && TMUX_SESSION_NAME="JOsh World"
# ZSH_TMUX_AUTOSTART_ONCE="true"
# ZSH_TMUX_AUTOCONNECT="true"
# ZSH_TMUX_AUTOQUIT="true"
# ZSH_TMUX_ITERM2="true"

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.

# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="spaceship"
VI_MODE_RESET_PROMPT_ON_MODE_CHANGE=true
VI_MODE_SET_CURSOR=true

#Spaceship theme options. (https://github.com/spaceship-prompt/spaceship-prompt/blob/master/docs/options.md)
SPACESHIP_KUBECTL_SHOW=true
SPACESHIP_TERRAFORM_SHOW=true
SPACESHIP_AWS_REGION_SHOW=true
SPACESHIP_AWS_PREFIX=" "

plugins=(
  ansible
  aws
  branch
  brew
  colored-man-pages
  colorize
  compleat
  cp
  docker
  docker-compose
  dotenv
  git
  git-auto-fetch
  git-extras
  golang
  helm
  history
  kubectl
  man
  minikube
  os
  pip
  terraform
  rsync
  vi-mode
  vscode

  ## Custom Plugins
  zsh-autosuggestions
)
ZSH_DISABLE_COMPFIX=true
source $ZSH/oh-my-zsh.sh


# set vi as the default cli editor
if [[ ! -f /opt/homebrew/bin/vim ]]; then
  export EDITOR=/usr/local/bin/vim
  export VISUAL=/usr/local/bin/vim
else
  export EDITOR=/opt/homebrew/bin/vim
  export VISUAL=/opt/homebrew/bin/vim
fi

#Path stuff
export PATH=$PATH:~/.composer/vendor/bin:$HOME/Library/Python/2.7/bin
export PATH=$PATH:/usr/local/bin
export PATH=$PATH:$(go env GOPATH)/bin
export PATH="$HOME/.rvm/bin:$HOME/.rvm/rubies/default/bin:$PATH:" # Add RVM to PATH for scripting


if ([[ "$TERM_PROGRAM" = 'iTerm.app' ]]); then
  _tmux_iterm_integration='-CC'
fi


if [[ -z "$TMUX" && -z "$EMACS" && -z "$VIM" ]]
then
  tmux start-server

  # Create a  session if no session has been defined in tmux.conf.
  if ! tmux has-session 2> /dev/null; then
    tmux \
      new-session -d -s "$TMUX_SESSION_NAME" \; \
      set-option -t "$TMUX_SESSION_NAME" destroy-unattached off &> /dev/null
  fi

  # Attach to the Last section used
  exec tmux  attach-session
fi

# history -  ignore searched for duplicates
export HISTCONTROL=ignoreboth:erasedups

# @description vi and git wrapper for opening editing and then committing changes to files
# @example f_edit .zshrc
# @exitcode 0 if successful
# @exitcode 1 if missing input files
f_edit() {

  local _USAGE="Usage :  f_edit  [options] [--] {files to edit}

Options:
-r|reload     Relaod zshrc after editing
-g|open       Open Vim in GUI mode (detached from shell)
-h|help       Display this message
-a|commit-all add the --all flag to the git commit after file edit
"

  while getopts 'rgha' opt
  do
    case $opt in
      h|help     )  echo $_USAGE; return 0   ;;

      r|reload   ) local _RELAOD=true ;;
      s|split 		 ) local _SPLIT=true 		;;
      v|vertical-split 		 ) _VSPLIT=true 		;;
      a|commit-all  ) local _COMMIT_ALL=true  ;;

      * ) echo -e "\033[31;1m[ERROR]\033[0m Option does not exist : $OPTARG\n"
        echo "$_USAGE"; return 1   ;;
    esac    # --- enc of case ---
  done
  shift $(($OPTIND-1))
 [[ -z $1 ]] && echo $_USAGE && return 1

  local FULL_PATH=$(realpath $1)
  local FILE=$(basename $FULL_PATH)
  local DIRECTORY=$(dirname $FULL_PATH)

  vim $FULL_PATH

  git -C $DIRECTORY add $FILE

  [[ $_COMMIT_ALL ]] && git -C $DIRECTORY --all || git -C $DIRECTORY commit $FILE

  [[ $_RELOAD ]] && echo -e "\033[32;1m[INFO]\033[0m Reloading .zshrc" && source $FULL_PATH
#  return 0
}

# aliases
## spelling mistakes
alias dicker="docker"
alias got="git"

## App aliases
# TODO: Create `aliases` function that allows for an array of alias names to a single command.
alias c="code ."
alias fedit="f_edit"
alias gmain="git checkout main && git pull"
alias grep="grep --exclude-dir={.git,.svn} --exclude-dir=.terraform --exclude-dir=.terragrunt-cache"
alias java8="export PATH='/usr/local/opt/openjdk@8/bin:$PATH' && CPPFLAGS='-I/usr/local/opt/openjdk@8/include'"
alias less="cless"
alias m="make"
alias mk="minikube"
alias pre-commit-init='echo -e "\\033[32;1m[INFO]\\033[0m Creating pre-commit-config.yaml" &&
  pre-commit sample-config > .pre-commit-config.yaml &&
  vim .pre-commit-config.yaml &&
  pre-commit autoupdate &&
  git add .pre-commit-config.yaml &&
  git commit -m "Adding git Precommit" &&
  pre-commit install --install-hooks'
alias profile_zsh="$PROFILE=true source $HOME/.zshrc"
alias reload_tmux="tmux source-file path $HOME/.tmux.conf"
alias reload_zsh="source $HOME/.zshrc"
alias sshconfig_edit="f_edit $HOME/.local_configs/ssh_config"
alias sshc_onfig_edit="sshconfig_edit"
alias stern="stern -s5m" #stern defaults to 5 minutes
alias tf="terraform"
alias tg="terragrunt"
alias tmuxa="tmux $_tmux_iterm_integration new-session -A"
alias tmuxconfig_edit="f_edit $_DOT_FILES_REPO/tmux.conf && tmux source-file ~/.tmux.conf"
alias vi="vim -Og --servername VIM4" #open vi in gvim, always vertically split the files
alias zshrc_user_edit="f_edit -r $HOME/.local_configs/.zshrc_user"

#local_config stuff
#.local_config is a locally created .git repo that allows for one to keep grach onf changes on sensitive files like ssh config or AWS credentails.
move_to_local_config() {
local _USAGE="Usage : move_to_local_config  [- flags] [--] move_to_local_config FILENAME SYMLINK_FILE (optional)
  Moves a file to local configs, addts it to version control and creates a symlink.
      Options:
      -h|help       Display this message
  "
  while getopts ": flags" opt
  do
    case $opt in

    h|help     )  echo $_USAGE; return 0   ;;

    * ) echo -e "\033[31;1m[ERROR]\033[0m Option does not exist : $OPTARG\n"

        echo $_USAGE; return 1   ;;

    esac    # --- end of case ---
  done
  shift $(($OPTIND-1))
  [[ -z $1 ]] && echo -e "\033[31;1m[ERROR]\033[0m Requires fine name and path to run"
  local ORIGINAL_PATH=$(realpath $1)
  [[ -z $2 ]] && local LN_LINK=$2 || local LN_LINK=$(basename $ORIGINAL_PATH)
  local LN_TARGET=$_LOCAL_CONFIG_FILES_REPO/$LN_LINK
  local COMMIT_MESSAGE="Initial add  of $ORIGINAL_PATH to $_LOCAL_CONFIG_FILES_REPOi as $LN_LINK"
  echo -e "\033[32;1m[INFO]\033[0m Moving $ORIGINAL_PATH to $LN_TARGET and creating a symlink back to it"
  mv $ORIGINAL_PATH $LN_TARGET
  ln -s $LN_TARGET $ORIGINAL_PATH
  git -C _LOCAL_CONFIG_FILES_REPO add $LN_LINK
  git -C _LOCAL_CONFIG_FILES_REPO commit $LN_LINK -m "$COMMIT_MESSAGE"
}
# edit and commit changed to zshrc (this file).
zshrc_edit() {
  local  _MAIN_REPO=$_DOT_FILES_REPO
  local  _MAIN_ZSHRC=${_MAIN_REPO}/zshrc
  local  _USER_REPO=$_LOCAL_CONFIG_FILES_REPO
  local  _USER_RC=${_USER_REPO}/.zshrc_user
  _USAGE="Usage :  zshrc_edit  [options]]

Options:
-a|all        Open both .zshrc and .zshrc_user in split window
-h|help       Display this message
"
  while getopts 'hr' opt
  do
    case $opt in
      h|help     )  echo $_USAGE; return 0   ;;

      a|all 		) local _ALL=true 		;;

      * ) echo -e "\033[31;1m[ERROR]\033[0m Option does not exist : $OPTARG\n"
        echo "$_USAGE"; return 1   ;;

    esac    # --- end of case ---
  done
  shift $(($OPTIND-1))

  [[ ${_ALL} ]] && vim -o ${_MAIN_ZSHRC} ${_USER_RC} || vim ${_MAIN_ZSHRC}
  vared -p "What Changes did you make? (leave blank for none)" -c MESSAGE
  [[ -z $MESSAGE ]] && return 1
  [[ ${DEBUG} ]] && echo -e "\033[34;1m[DEBUG]\033[0m Committing: $MESSAGE"
    git -C ${_MAIN_REPO} commit ${_MAIN_ZSHRC} -m "$MESSAGE"
    git -C ${_MAIN_REPO} push || echo "no commit. no push"
    [[ ${_ALL} ]] && git -C ${_USER_REPO} commit ${_USER_RC} -m "$MESSAGE"
  source $HOME/.zshrc
}

# misc tools.
# @description shortcut for envs grepping
#
#  @example
#     envgrep $PATTERN
#
#  @arg $1 Pattern to search
#
#  @exitcode 0 If successful.
#  @exitcode 1 If an empty string passed.)
grepenv() {
  [[ -z $1 ]] && echo -e "\033[31;1m[ERROR]\033[0m Np pattern input" && return 1
  env | grep $1
}
# Vim functions
source $HOME/.vim/vim-shell-utils.zsh

## GIT Functions
# commit and push in one function.
cimpush() {
  git commit --all --message "$1"
  git push
}

# commit with manual message and push
cipush() {
  git commit --all
  if [[ $? != 0 ]]; then
    echo "git commit failed not pushing"
    return 1
  else
    git push
  fi
}

alias synfix='cimpush "Syntax Fix"'

newgit () {
  mkdir $1
  cd $1
  git init
}

## docker functions
function docker-kill-all() {
  docker stop $(docker ps -a -q)
  docker rm $(docker ps -a -q)
}


# update kubeconfig with new cluster
eks_config() {
  aws eks update-kubeconfig --name $1 --alias $1
}

# BOF Kubernetes resources

source <(kubectl completion zsh)
alias k8s-show-ns=" kubectl api-resources --verbs=list --namespaced -o name  | xargs -n 1 kubectl get --show-kind --ignore-not-found  -n"
complete -F __start_kubectl k8s

alias kns="kubens"
alias ktx="kubectx"

function k8s-ns() {
  echo "
---
apiVersion: v1
kind: Namespace
metadata:
  labels:
    name: $1
  name: $1
" > $1.ns.yaml
}

function new-ssh-config-entry() {
  echo "
Host $1
  HostName $3
  User $2

  " >> $HOME/.ssh/config
}

# manually setting rvm requirements
#export GEM_HOME=$HOME/.gem
#export GEM_PATH=$HOME/.gem
#
# per os settings.

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Python settings
# maing brew installed python3 default.
autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /usr/local/bin/kustomize kustomize

# Jenkins functions

function jen-lib-var() {
  echo $1 > $1.txt
  echo "#!/usr/bin/env groovy" >> $1.groovy
  echo "def call(Map params = [:]) {" >> $1.groovy
  echo "}" >> $1.groovy
  git add $1.txt $1.groovy
  vi -O $1.txt $1.groovy

}
# Per language or application settings that are not quite right for oh_my_zsh
for file in $ZSH_CUSTOM/snippets/*.zsh; do
  source "$file"
done
### Local overrides this should always be at the bottom of the rcfile
# mac osX
if [[ $(uname) == "Darwin" ]]
then
  source $_DOT_FILES_REPO/zshrc_mac
fi
# include local overrides

if [[ -s "$HOME/.zshrc_user" ]]; then
  source "$HOME/.zshrc_user"
fi

# Homebrew install path locations
if ! command -v brew help &> /dev/null
then
  export PATH="/usr/local/opt/openjdk@11/bin:$PATH"
  export GROOVY_HOME=/usr/local/opt/groovy/libexec
fi

# in nvm is installed then load it
if [[ -f /opt/homebrew/opt/nvm/nvm.sh ]]; then
  export NVM_DIR="$HOME/.nvm"
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
fi
# Created by `pipx` on 2024-10-15 18:48:42
export PATH="$PATH:/Users/joshb/.local/bin"
