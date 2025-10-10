#!/bin/zsh

aks_session() {
  local USAAGE="Usage: aks_session <cluster_name> <subscription_id>"
  [[ $# -ne 2 ]] && echo $USAAGE && return 1
  local CLUSTER_NAME=$1
  local SUBSCRIPTION_ID=$2

  az account set --subscription $SUBSCRIPTION_ID || { echo "Failed to set subscription"; return 1; }
  kubectx $CLUSTER_NAME || { echo "Failed to switch context to $CLUSTER_NAME"; return 1; }
}
