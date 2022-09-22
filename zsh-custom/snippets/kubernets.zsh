#!/bin/zsh

# add https://krew.sigs.k8s.io/ to PATH
if [[ -d '$HOME/.krew' ]]; then
  export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
fi
