#!/bin/zsh

kust_add () {
  [[ ! -f kustomize.yaml ]] && touch kustomize.yaml
  kustomize edit add $1
}
