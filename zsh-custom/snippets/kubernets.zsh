#!/bin/zsh
#
#
# add https://krew.sigs.k8s.io/ to PATH
if [[ -d '$HOME/.krew' ]]; then
  export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
fi


64d() {
  echo $1 | base64 --decode
}

# returns all names of the type of obkect passed as second argument#
# prefirms the action passed as first argument on all objects of that type
k_all() {
  local action=$1
  local object_type=$2
  local objects=$(kubectl get $(object_type) | awk '{print $1}' | tail -n +2)
  kubectl $action $objects
}

_k_all() {
  local state
  _arguments \
    '1: :->action' \
    '2: :->object_type'

  case $state in
    action)
      local -a actions
      actions=($(kubectl 2>&1 | awk '/^  [a-z]/ {print $1}'))
      _describe 'action' actions
      ;;
    object_type)
      local -a object_types
      object_types=($(kubectl api-resources --no-headers 2>/dev/null | awk '{print $1}'))
      _describe 'object type' object_types
      ;;
  esac
}

compdef _k_all k_all

ko () {
  export k_type=$2
  export k_ob=$3
  echo -e "\033[32;1m[Working with Set to ]\033[0m $k_type $k_ob"
  [[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG]\033[0m $@"
  kubectl $1 $k_type $k_ob
}

_ko_eval () {
  [[ -z $k_type ]] && echo "Please set the object type using ko" && return 1
  [[ -z $k_ob ]] && echo "Please set the object name using ko" && return 1
}

k_ed () {
  _ko_eval
  local cmd="kubectl edit $k_type $k_ob"
  echo -e "\033[32;1m[Editing ]\033[0m $k_type $k_ob"
  [[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG]\033[0m $cmd"
  eval $cmd
}

k_des () {
  _ko_eval
  kubectl describe $k_type $k_ob
}
