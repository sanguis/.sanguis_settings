#!/bin/zsh
#
#
#
alias kgpo="kubectl get pods -o wide"
alias kgp="kubectl get pods"
alias kdep="kubectl describe pod"
alias keti="kubectl exec -ti"
alias kdlp="kubectl delete pod"
alias rollout="kubectl rollout restart deployment"
alias rollStatus="kubectl rollout status deployment"
alias kdes="kubectl describe"
alias kgs="kubectl get secrets"
alias kvs="kubectl get secret -o yaml"
alias kgsb="kubectl get secret -o jsonpath='{.data}'"

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
  local USEAGE="Usage: ko <action> <object_type> <object_name>
  Example: ko get pod my-pod-1234
  Follow Up commands:
   \033[32;1mk_ed\033[0m  to edit the object
   \033[32;1mk_des\033[0m to describe the object
   \033[32;1mk_dl\033[0m  to delete the object"
  zmodload zsh/zutil
  zparseopts -D -F -K -- \
    h=help -HELP=help \
    d=debug -DEBUG=debug ||
    return 1

  [[ $HELP == true ]] && echo -e "\033[33;1m[USAGE]\033[0m $USEAGE" && return 0
  if [[ $# -ne 3 ]]; then
    echo -e "\033[31;1m[ERROR]\033[0m Invalid number of arguments"
    echo -e "\033[33;1m[USAGE]\033[0m $USEAGE"
    return 1
  fi
  export k_type=$2
  export k_ob=$3
  echo -e "\033[32;1m Persistent object set to:\033[0m $k_type $k_ob"
  [[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG]\033[0m $@"
  kubectl $1 $k_type $k_ob
}

# auto complete for ko to complete object type and object name
_ko() {
  local state
  _arguments \
    '1: :->action' \
    '2: :->object_type' \
    '3: :->object_name'
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
    object_name)
      if [[ -n $k_type ]]; then
        local -a object_names
        object_names=($(kubectl get $k_type --no-headers 2>/dev/null | awk '{print $1}'))
        _describe 'object name' object_names
      fi
      ;;
  esac
  }
compdef _ko ko

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

k_dl () {
  _ko_eval
  local cmd="kubectl delete $k_type $k_ob"
  echo -e "\033[31;1m[Deleting ]\033[0m $k_type $k_ob"
  [[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG ]\033[0m $cmd"
  eval $cmd
}
