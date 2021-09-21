#!/usr/bin/env zsh

if [ -z $P ]; then
  P=$HOME/.sanguis_settings
fi

function update_ss() {
  cd $P
  git pull
  git submodule update --init --recursive
}
function set_git() {
 cd $P/$1
 git config user.email "sanguis@users.noreply.github.com"
 git config user.name "Josh Beauregard"
 cd $P
}

function set_git_dirs() {
local dirs=$(git config --file .gitmodules --get-regexp path | awk '{ print $2 }')
for d in ${dirs}; do

  set_git $d
done
}
set_git_dirs
