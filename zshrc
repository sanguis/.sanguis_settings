setopt EXTENDED_GLOB
for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/^README.md(.N); do
  ln -s "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}"
done
alias vhost="sudo ~/bin/vhost"
alias vi="vim -g"
alias new-module="sh ~/src/drupal-new-module/new-module.sh"
