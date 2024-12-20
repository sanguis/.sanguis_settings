#!/usr/bin/env bash

if [[ ! -x /usr/local/bin/brew ]]
then
  echo "Homebrew missing installing"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi

brew install bash zsh tmux source-highlight
xcode-select --install

brew install tmux python3 macvim bash coreutils grep gnu-sed gnu-indent checkov pre-commit fzf chroma zsh-autosuggestions
