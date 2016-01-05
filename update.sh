#!/bin/sh

git submodule init

function update_ss() {
  git submodule update --recursive --init
}
