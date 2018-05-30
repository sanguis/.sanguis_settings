#!/usr/bin/env bash
P=$HOME/.sanguis_settings

source update.sh
if [ ! -d $P ]
then
  git clone --recursive https://github.com/sanguis/.sanguis_settings.git $P
  cd $P
else
 update_ss
fi

## install powerline fonts
bash ./fonts/install.sh
  
if [ -f "$HOME/.zshrc" ]; then
  echo "backing up zshrc"
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

for k in ${!links[@]}; do
  if [ ! -f ${links[${k}]} ]; then
    echo "ln -s $P/${k} ${links[${k}]}"
    ln -s $P/${k} ${links[${k}]}
  fi
    # ls ${links[${k}]}
done

#setup prezto
#setopt EXTENDED_GLOB
#for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/^README.md(.N); do
#  ln -s "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}"
#done
source $HOME/.zshrc
