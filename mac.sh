
#!/usr/bin/env bash

if [ ! -x brew ]
then
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi

brew install bash zsh tmux source-highlight
xcode-select --install

brew install tmux python3 macvim bash
