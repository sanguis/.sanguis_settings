#!/usr/bin/env zsh
#@brief Terraform extension functions

# # Aliases

alais tf-state='terraform state pull | less'

# @description call the current state of https://github.com/Diehlabs/terraform-module-scaffolding and addit it as a squashed subtree
tf_new_module() {
 local usage="tf_new_module module_name"
 [[ -z $1 ]] && echo -e "\033[31;1m[ERROR]\033[0m Needs a module name. \n $usage" $$ return 1
 git subtree add --prefix $1 https://github.com/Diehlabs/terraform-module-scaffolding.git main --squash
}

tf_cost() {
local planfile=/tmp/tf-cost-${date +"%s"}
	terraform plan -out $(PLAN_FILE).binary
	terraform show -json $(PLAN_FILE).binary > $(PLAN_FILE).json
	infracost breakdown --path $(PLAN_FILE).json
	infracost diff --path $(PLAN_FILE).json
}
