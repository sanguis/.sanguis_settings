# Path to your oh-my-zsh configuration.
ZSH=$HOME/.sanguis_settings/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
# ZSH_THEME="gallois"
  ZSH_THEME="agnoster"

# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Comment this out to disable weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
 COMPLETION_WAITING_DOTS="true"
 ZSH_TMUX_AUTOSTART="true"
 ZSH_TMUX_AUTOCONNECT="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
#plugins=(git drush vi-mode vi)
plugins=(git drush vi git-extras symphony history rsync github gem git-remote-branch knife vagrant tmux)

source $ZSH/oh-my-zsh.sh

# Customize to your needs...
# export PATH=/home/knectar/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games
#. /home/josh/.local/lib/python2.7/site-packages/powerline/bindings/zsh/powerline.zsh
# Aliases

alias vhost="sudo ~/bin/vhost"
alias vi="vim -g"
alias new-module="sh ~/src/drupal-new-module/new-module.sh"

