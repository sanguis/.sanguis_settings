#!/bin/zsh

_gh_reqs() {
#array of required variables
declare -a reqs
reqs=(GITHUB_API_URL GH_ENTERPRISE GH_TOKEN)
for req in $reqs; do
  [[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG]\033[0m checking $req"
  if [[ -z "${(P)req}" ]]; then
    echo -e "\033[31;1m[ERROR]\033[0m Required variable $req is not set"
    return 1
  else
    [[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG]\033[0m Required variable $req is set"
  fi
done
}

# List all users in the enterprise
gh_org_users() {
local USAGE="Usage: gh_org_users ORG
Github token must have read:org scope"
_gh_reqs

local flag_help flag_verbose flag_no_headers flag_count
zmodload zsh/zutil
zparseopts -D -F -K -- \
 {h,-help}=flag_help \
 {d,-debug}=flag_verbose \
 {n,-no-header}=flag_no_headers \
 {c,-count}=flag_count ||
  return 1


[[ ! -z $flag_help ]] && echo $USAGE && return 0
[[ ! -z $flag_verbose ]] &&  echo "DEBUG mode enabled" && DEBUG=true
[[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG: flags]\033[0m
flag_help: $flag_help
flag_verbose: $flag_verbose
flag_no_headers: $flag_no_headers
flag_count: $flag_count"

[[ -z $1 ]] && echo "Organization is required" && echo $USAGE && return 1

local org=$1
# Iterate through each organization and list members
[[ -z $flag_no_headers ]] && echo "Organization: \033[32;1m$org\033[0m"
local members=$(curl -s -H "Authorization: token $GH_TOKEN" "$GITHUB_API_URL/orgs/$org/members" | jq -r '.[].login')
echo "$members"
[[ ! -z $flag_count ]] && echo "Total members: $(echo $members | wc -l)"
}

#list all users in an gh organization
gh_ent_users() {
local USAGE="Gets list all users in a github enterprises organization
Usage: gh_ent_users ORG
Github token must have read:org and read:enterprise scope"
_gh_reqs

local orgs=$(curl -s -H "Authorization: token $GH_TOKEN" "$GITHUB_API_URL/enterprises/$GH_ENTERPRISE/orgs" | jq -r '.[].login')

# if $1 is not in the orgs then return 1
if [[ -z "$1" ]]; then
  echo -e "\033[32;1m[INFO]\033[0m Getting all users in each organization in the enterprise, $GH_ENTERPRISE"
else
  if [[ ! " ${orgs[@]} " =~ " $1 " ]]; then
    echo "Organization $1 is not in the enterprise $GH_ENTERPRISE"
    return 1
  fi
  orgs=($1)
fi


# Iterate through each organization and list members
for org in $orgs; do
  members=(gh_ent_users $org)
done
}
