
# Path to your oh-my-zsh installation.
export ZSH=$HOME/.sanguis_settings/oh-my-zsh

# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="agnoster"

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
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.

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

# aliases
alias got="git"
alias tmuxa="tmux $_tmux_iterm_integration new-session -A"
alias tvs="tmux split-window -vc $PWD"
alias tsp="tmux split-window -c $PWD"
alias vi="vim -g --servername VIM4"
export EDITOR=/usr/bin/vim
export VISUAL=/usr/bin/vim
export PATH="$HOME/.rvm/bin:$HOME/.rvm/rubies/default/bin:$PATH:" # Add RVM to PATH for scripting


# manually setting rvm requirements
#export GEM_HOME=$HOME/.gem
#export GEM_PATH=$HOME/.gem
#
# include local overrides

if [[ -s "$HOME/.zshrc_user" ]]; then
  source "$HOME/.zshrc_user"
fi

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
