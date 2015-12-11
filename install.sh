#! /bin/sh

SS=$HOME/.sanguis_settings
git submodule init
git submodule update

ln -s $SS/vimrc $HOME/.vimrc;
ln -s $SS/.vim $HOME/.vim;
ln -s $SS/zshrc $HOME/.zshrc;
ln -s $SS/gitconfig $HOME/.gitconfig;

# getting vim submodules
cd .vim
git submodule init
git submodule update --recursive
