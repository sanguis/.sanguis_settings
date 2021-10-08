#!/usr/bin/env bash
P=$HOME/.sanguis_settings
OS=$(uname)

if [ ! -d $P ]
then
  git clone --recursive https://github.com/sanguis/.sanguis_settings.git $P
  cd $P
fi

[[ OS = "Darwin" ]] && source $P/mac.sh

source update.sh $Pw
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

# setup sshconfig to be symbolic link and kept onter version control
SSHCONF=$GOME/.sshconfig
if [[ ! -d $SSHCONF ]]; then
  CUR=$(pwd)
  mkdir $SSHCONF
  cd $SSHCONF
  echo "creating sshconf git repo and adding symbolic link"
  git init
  touch config
  git add config
  git commit config --message "Adding empty config file"
  cd $CUR

fi
# create symlinks

source $P/links.sh

function links() {
  for k in $(links[@]); do
    [[ -f $(links[${k}]) ]] && return
    [[ $DEBUG ]] && echo "ln -s $P/${k} ${links[${k}]}"
    ln -s $P/${k} $(links[${k}])
  done
}
links

source $HOME/.zshrc
