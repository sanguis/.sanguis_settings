
#!/usr/bin/env bash

if [ ! -x brew ]
then
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

brew install bash zsh tmux source-highlight
xcode-select --install
