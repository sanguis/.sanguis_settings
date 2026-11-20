#!/bin/zsh

aks_session() {
  local USAGE=" Switches context of \`az\` and \`kubectl\` to the specified AKS cluster and subscription.
    Usage: aks_session <cluster_name> <subscription_id> [pim_resource]
      pim_resource  Optional. PIM resource to activate; requires \`az-pim-cli\`."
  [[ $# -lt 2 || $# -gt 3 ]] && echo $USAGE && return 1
  local CLUSTER_NAME=$1
  local SUBSCRIPTION_ID=$2
  local PIM_RESOURCE=$3

  if [[ -n $PIM_RESOURCE ]]  then
    ! command -v az-pim-cli >/dev/null 2>&1 && echo -e "\033[31;1m[ERROR]\033[0m \`az-pim-cli\` is not installed. Please install it to use PIM activation." && return 1
    local PIM
    PIM=$(az-pim-cli activate resource --name $PIM_RESOURCE 2>&1)

    if [[ $? -ne 0 ]]; then
      if [[ $PIM == *RoleAssignmentExist* ]]; then
        echo "PIM resource $PIM_RESOURCE is already active"
      else
        echo $PIM
        echo -e "\033[31;1m[ERROR]\033[0m Failed to activate PIM resource $PIM_RESOURCE"
        return 1
      fi
    fi
  fi

  az account set --subscription $SUBSCRIPTION_ID || { echo "Failed to set subscription"; return 1; }
  kubectx $CLUSTER_NAME || { echo "Failed to switch context to $CLUSTER_NAME"; return 1; }
}
