# vim: set ft=zsh
# Path to your oh-my-zsh installation.
export ZSH=$HOME/.sanguis_settings/oh-my-zsh

export UPDATE_ZSH_DAYS=13

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

#Spaceship theme options.
SPACESHIP_KUBECTL_SHOW=true

plugins=(
  brew
  ansible
  git
  branch
  aws
  colorize
  compleat
  cp
  docker
  docker-compose
  git-auto-fetch
  git-extras
  github
  go
  golang
  helm
  history
  iterm2
  kubectl
  man
  pip
  sudo
  terraform
  rsync
  colored-man-pages
  vi-mode
  fancy-ctrl-z
  helm
  kubectl
)

source $ZSH/oh-my-zsh.sh
# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8


# ssh
export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
#
# EOF oh-my-zsh settings
#
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

  # Attach to the 'prezto' session or to the last session used.
  exec tmux  attach-session
fi

# history -  ignore searched for duplicates
export HISTCONTROL=ignoreboth:erasedups
# aliases
alias got="git"
alias tmuxa="tmux $_tmux_iterm_integration new-session -A"
alias tvs="tmux split-window -vc $PWD"
alias tsp="tmux split-window -c $PWD"
alias vi="vim -g --servername VIM4" #open vi in gvim
alias aws-id="aws sts get-caller-identity"

# common editor settings
export EDITOR=/usr/bin/vim
export VISUAL=/usr/bin/vim
export PATH="$HOME/.rvm/bin:$HOME/.rvm/rubies/default/bin:$PATH:" # Add RVM to PATH for scripting

#functions
function docker-kill-all() {
  docker stop $(docker ps -a -q)
  docker rm $(docker ps -a -q)
}

# BOF Kubernetes resources
# get ready for helm charting
function helm-prep() {
 export TILLER_NAMESPACE=tiller
 tiller -listen=localhost:44134 -storage=secret -logtostderr &
 export HELM_HOST=:44134
 helm init --client-only --upgrade
}

source <(kubectl completion zsh)
alias k8s-show-ns=" kubectl api-resources --verbs=list --namespaced -o name  | xargs -n 1 kubectl get --show-kind --ignore-not-found  -n"
complete -F __start_kubectl k8s

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

# manually setting rvm requirements
#export GEM_HOME=$HOME/.gem
#export GEM_PATH=$HOME/.gem
#
# per os settings.

# mac osX
if [[ -x /usr/bin/xcode-select ]]
then
  source $HOME/.sanguis_settings/zshrc_mac
fi
# include local overrides

if [[ -s "$HOME/.zshrc_user" ]]; then
  source "$HOME/.zshrc_user"
fi

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Python settings
# maing brew installed python3 default.
export PATH=/usr/local/opt/python/libexec/bin:$PATH
