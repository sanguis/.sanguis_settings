#! /bin/sh

source $PATH/update.sh

# create symlinks
# todo: add ifs
ln -s $SS/vimrc $HOME/.vimrc;
ln -s $SS/.vim $HOME/.vim;
ln -s $SS/zshrc $HOME/.zshrc;
ln -s $SS/tmux.conf $HOME/.tmux.conf;
ln -s $SS/gitconfig $HOME/.gitconfig;
ln -s $SS/prezto $HOME/.zprezto;

update_ss
# setup prezto
setopt EXTENDED_GLOB
for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/^README.md(.N); do
  ln -s "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}"
done
