#!/bin/zsh

fetch_and_checkout() {
  git fetch --all && git checkout $1
}
