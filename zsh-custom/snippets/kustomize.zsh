#!/bin/zsh

_create_kust() {
  [[ ! -f kustomize.yaml ]] && touch kustomize.yaml
}
kust_add_base () {
[[ -z $1 ]] && echo -e "\033[31;1m[ERROR]\033[0m please list files you want to add to the kustomize base" && return 1
  _create_kust
  kustomize edit add base $@
}
