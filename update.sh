#! /bin/sh

SS=$HOME/.sanguis_settings
git submodule init

function update_ss() {
  git submodule update --recursive
}
