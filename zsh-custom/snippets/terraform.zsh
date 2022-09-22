#!/usr/bin/env zsh
#@brief Terraform extension functions

# # Aliases

alias tf-state='terraform state pull | less'

# @description call the current state of https://github.com/Diehlabs/terraform-module-scaffolding and addit it as a squashed subtree
tf_new_module() {
 local usage="tf_new_module module_name"
 [[ -z $1 ]] && echo -e "\033[31;1m[ERROR]\033[0m Needs a module name. \n $usage" $$ return 1
 git subtree add --prefix $1 https://github.com/sanguis/terraform-module-scaffolding.git main --squash
}

# @description Generate pricing information for a terraform deployment
tf_cost() {
local PLAN_FILE=/tmp/tf-cost-$(date +"%s")
	terraform plan -out $(PLAN_FILE).binary
	terraform show -json $(PLAN_FILE).binary > $(PLAN_FILE).json
	infracost breakdown --path $(PLAN_FILE).json
	infracost diff --path $(PLAN_FILE).json
}

# @description Generate a plan file and open it in vi
tf_plan_json() {
  local PLAN_FILE=/tmp/tf-plan-$($PWD:t)-$(date +"%s").json
  terraform state pull > $PLAN_FILE
  vi $PLAN_FILE
}
#
# @description  set terraform log debugging
#
#  @example
#     tf-log-debug
#
#  @exitcode 0 If successful.
#  @exitcode 1 If an empty string passed.)
tf-log-debug() {
[[ -z $1 ]] && LEVEL=TRACE
export TF_LOG=$LEVEL
export TF_LOG_PATH=/tmp/tf_debug.log
echo -e  "\033[32;1m[INFO]\033[0m Terraform log level set to debug.  Log output at $TF_LOG_PATH"
}
alias tf-log-tail="tail -f $TF_LOG_PATH"

# detects if its a terragrunt dir or normal terraform and runs the right exe
t() {
[[ -f ./terragrunt.hcl ]] && local exe=terragrunt
[[ ! -f ./terragrunt.hcl ]] && local exe=terraform

[[ ! $exe ]] && echo -e "\033[31;1m[ERROR]\033[0m Can't figure out what to run. Please run manually"
local cmd=($exe $@)
[[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG]\033[0m executable is $exe.
Args are $@
Command to be run: $cmd"
$cmd
}
