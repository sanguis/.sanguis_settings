#!/bin/zsh

_create_kust() {
  [[ ! -f kustomize.yaml ]] && touch kustomize.yaml
}
kust_add_base () {
[[ -z $1 ]] && echo -e "\033[31;1m[ERROR]\033[0m please list files you want to add to the kustomize base" && return 1
  _create_kust
  kustomize edit add base $@
  git add kustomize.yaml
}

kust_add_patch_dir() {
_USAGE="Usage : kust_add_patch_dir  [options] [--] {new dir} {path to base dir}
  Adds directory and kustomzation.yaml to that directory
    Options:
    -h|help       Display this message
"

while getopts ":h" opt
do
  case $opt in

  h|help     )  echo $_USAGE; return 0   ;;

  * ) echo -e "\033[31;1m[ERROR]\033[0m Option does not exist : $OPTARG\n"
      echo ${usage}; return 1   ;;

  esac    # --- end of case ---
done
shift $(($OPTIND-1))
[[ -z $1 ]] && echo $_USAGE && return 1 [[ -z $2 ]] && echo $_USAGE && return 1
[[ -f $1/kustomzation.yaml ]] && echo -e "\033[31;1m[ERROR]\033[0m patch directory already exists." && return 1
mkdir $1
echo "
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- $2" >> $1/kustomzation.yaml
}
