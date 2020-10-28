#!/usr/bin/env bash
P=$HOME/.sanguis_settings
OS=$(uname)

if [ OS = "Darwin" ]
then
  source mac.sh
fi


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

pip3 install powerline-status

if [ -f "$HOME/.zshrc" ]; then
  echo "backing up zshrc"
  ZSHDATA=`cat ~/.zshrc`
  mv $HOME/.zshrc $HOME/.zshrc_old
  rm $HOME/.zshrc
echo $ZSHDATA >> $P/zshrc
fi


# create symlinks


source $P/links.sh

for k in ${!links[@]}; do
  if [ ! -f ${links[${k}]} ]; then
    echo "ln -s $P/${k} ${links[${k}]}"
    ln -s $P/${k} ${links[${k}]}
  fi
    # ls ${links[${k}]}
done

source $HOME/.zshrc
