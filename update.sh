#!/usr/bin/env bash

if [ -z $P ]; then
  P=$HOME/.sanguis_settings
fi

function update_ss() {
  cd $P
  git pull
  git submodule update --init --recursive
}
