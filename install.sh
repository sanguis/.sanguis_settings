#!/usr/bin/env bash
P=$HOME/.sanguis_settings

if [ ! -d $P ]
then
  git clone --recursive https://github.com/sanguis/.sanguis_settings.git $P
  cd $P
else
  cd $P
  git pull
  git submodule --init --recursive
fi
  
if [ -f "$HOME/.zshrc" ]; then
  ZSHDATA=`cat ~/.zshrc`
  mv $HOME/.zshrc $HOME/.zshrc_old
  rm $HOME/.zshrc
echo $ZSHDATA >> $P/zshrc
fi


# create symlinks

declare -A links

links["vim"]=$HOME/.vim
links["zshrc"]=$HOME/.zshrc
links["tmux.conf"]=$HOME/.tmux.conf
links["gitconfig"]=$HOME/.gitconfig
links["prezto"]=$HOME/.zprezto

for key in ${links[@]}; do
  if [ ! -f ${links[${key}]} ]; then
    ln -s $P/${key} ${links[${key}]}
  fi
done

source update.sh
#setup prezto
#setopt EXTENDED_GLOB
#for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/^README.md(.N); do
#  ln -s "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}"
#done
source $HOME/.zshrc
