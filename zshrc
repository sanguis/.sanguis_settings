# vim: set ft=zsh.sh
# Path to your oh-my-zsh installation.
# export DOTFILEDIR=$(realpath)

[[ $PROFILE ]] && echo -e "\033[32;1m[INFO]\033[0m Profileing On" && zmodload zsh/zprof
export ZSH=$HOME/.sanguis_settings/oh-my-zsh

export UPDATE_ZSH_DAYS=13

# enable auto-completeing
autoload bashcompinit && bashcompinit

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Tumx settings see ./oh-my-zsh/plugins/tmux/README.md
# ZSH_TMUX_AUTOSTART_ONCE="true"
# ZSH_TMUX_AUTOCONNECT="true"
# ZSH_TMUX_AUTOQUIT="true"
# ZSH_TMUX_ITERM2="true"

# Would you like to use another custom folder than $ZSH/custom?
export ZSH_CUSTOM=$HOME/.sanguis_settings/zsh-custom

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
  fancy-ctrl-z
  git
  git-auto-fetch
  git-extras
  golang
  helm
  history
  iterm2
  kubectl
  man
  minikube
  os
  os
  pip
  rsync
  terraform
  vi-mode
)
ZSH_DISABLE_COMPFIX=true
source $ZSH/oh-my-zsh.sh


# set vi as the default cli editor
export EDITOR=/usr/local/bin/vim
export VISUAL=/usr/local/bin/vim
export SSH_KEY_PATH="~/.ssh/rsa_id"

export PATH=$PATH:~/.composer/vendor/bin:$HOME/Library/Python/2.7/bin
export PATH=$PATH:/usr/local/bin


if ([[ "$TERM_PROGRAM" = 'iTerm.app' ]]); then
  _tmux_iterm_integration='-CC'
fi


if [[ -z "$TMUX" && -z "$EMACS" && -z "$VIM" ]]
then
  tmux start-server

  # Create a  session if no session has been defined in tmux.conf.
  if ! tmux has-session 2> /dev/null; then
    tmux_session="JOsh-World"
    tmux \
      new-session -d -s "$tmux_session" \; \
      set-option -t "$tmux_session" destroy-unattached off &> /dev/null
  fi

  # Attach to the Last section used
  exec tmux  attach-session
fi

# history -  ignore searched for duplicates
export HISTCONTROL=ignoreboth:erasedups
# generic file edit pattern
f_edit() {

  _USAGE="Usage :  f_edit  [options] [--] {files to edit}

Options:
-r|reload     Relaod zshrc after editing
-h|help       Display this message
"

  while getopts 'hr' opt
  do
    case $opt in
      h|help     )  echo $_USAGE; return 0   ;;

      r|reload   ) _RELAOD=true ;;

      * ) echo -e "\033[31;1m[ERROR]\033[0m Option does not exist : $OPTARG\n"
        echo "$_USAGE"; return 1   ;;

    esac    # --- end of case ---
  done
  shift $(($OPTIND-1))
 [[ -z $1 ]] && echo $_USAGE && return 1

  FULL_PATH=$(realpath $1)
  FILE=$(basename $FULL_PATH)
  DIRECTORY=$(dirname $FULL_PATH)

  vim $FULL_PATH
  git -C $DIRECTORY add $FILE
  git -C $DIRECTORY commit $FILE
  [[ $_RELOAD ]] && echo -e "\033[32;1m[INFO]\033[0m Reloading .zshrc" && source $HOME/.zshrc
#  return 0
}

# aliases
## spelling mistakes
alias tf="terraform"
alias got="git"
alias dicker="docker"

## App aliases
alias mk="minikube"
alias tmuxa="tmux $_tmux_iterm_integration new-session -A"
alias vi="vim -Og --servername VIM4" #open vi in gvim, always vertically split the files
alias reload_zsh="source $HOME/.zshrc"
alias profile_zsh="$PROFILE=true source $HOME/.zshrc"
alias sshconfig_edit="f_edit $HOME/.local_configs/ssh_config"
alias zshrc_user_edit="f_edit -r $HOME/.local_configs/.zshrc_user"
alias tmuxconfig_edit="f_edit $HOME/.sanguis_settings/tmux.conf && tmux source-file ~/.tmux.conf"
alias gmain="git checkout main && git pull"
alias java8="export PATH='/usr/local/opt/openjdk@8/bin:$PATH' && CPPFLAGS='-I/usr/local/opt/openjdk@8/include'"
export PATH="$HOME/.rvm/bin:$HOME/.rvm/rubies/default/bin:$PATH:" # Add RVM to PATH for scripting

# edit and commit changed to zshrc (this file).
zshrc_edit() {
  REPO=$HOME/.sanguis_settings
  ZSHRC=$REPO/zshrc
  vim $ZSHRC
  git -C $REPO commit $ZSHRC
  [ -z $? ] && git push || echo "no commit. no push"
  source $ZSHRC
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

# AWS stuff
complete -C '/usr/local/bin/aws_completer' aws
alias aws-id="aws sts get-caller-identity"
alias aws_region_eu1="export AWS_DEFAULT_REGION=eu-west-1"
alias aws_region_us1="export AWS_DEFAULT_REGION=us-east-1"
alias aws_region_us2="export AWS_DEFAULT_REGION=us-east-2"

aws-profile() {
  #echo "switching aws profile to $1"
  export AWS_DEFAULT_PROFILE=$1
  export AWS_PROFILE=$1
  #aws-id
}
aws_profile() {
  compadd $(aws configure list-profiles)
}
compdef _aws_profile aws_profile

# Terraform stuff
tf-log-debug() {
[[ -z $1 ]] && LEVEL=TRACE
export TF_LOG=$LEVEL
export TF_LOG_PATH=/tmp/tf_debug.log
echo -e  "\033[32;1m[INFO]\033[0m Terraform log level set to debug.  Log output at $TF_LOG_PATH"
}
alias tf-log-tail="tail -f $TF_LOG_PATH"

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
export PATH=/usr/local/opt/python/libexec/bin:$PATH
# vim: set ft=zsh
export PATH="/usr/local/opt/node@12/bin:$PATH"
export AWS_PAGER=""
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
# Other functions
source $ZSH_CUSTOM/snippets/*.zsh
### Local overrides this should always be at the bottom of the rcfile
# mac osX
if [[ $(uname) == "Darwin" ]]
then
  source $HOME/.sanguis_settings/zshrc_mac
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
