#!/bin/zsh
# use minikube for docker
minikube_as_docker () {
  [[ -x minikube ]] && [[ ${DEBUG} ]] && echo -e "\033[34;1m[DEBUG]\033[0m Minikube not found" && return 1
  [[ ${DEBUG} ]] && echo -e "\033[34;1m[DEBUG]\033[0m minikube executable found "
  local mk_status=$(minikube status -o json | jq .Host -r)
  [[ ${DEBUG} ]] && echo -e  "\033[34;1m[DEBUG]\033[0m Minikube status: ${mk_status}"
  [[ ${mk_status} != "Running" ]] && [[ ${DEBUG} ]] && echo -e "\033[34;1m[DEBUG]\033[0m Minikube Not running" && return 1
  eval $(minikube docker-env)
  return 0
}

minikube_unset_as_docker () {
  unset DOCKER_CERT_PATH
  unset DOCKER_HOST
  unset DOCKER_TLS_VERIFY
}
