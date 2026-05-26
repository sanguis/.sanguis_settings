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

# curl looping through all pages of results and returning the results as a total value
_gh_pages_curl() {

  local curl_command=$@
  echo $curl_command
  local results=$(curl $curl_command)
  [[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG:curl command]\033[0m \n $(echo results| jq)"
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
  declare -a members
  # loop through all pages of members and add to members array
  local get_members =$(curl -s -H "Authorization: token $GH_TOKEN" "$GITHUB_API_URL/orgs/$org/members" | jq -r '.[].login')
  [[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG:members_raw]\033[0m $members_raw"

  echo "$members"
  [[ ! -z $flag_count ]] && echo "Total members: $(echo $members | wc -l)"
}

#list all users in an gh organization
gh_ent_users() {
  local USAGE="Gets list all users in a github enterprises organization
  Usage: gh_ent_users ORG
  Github token must have read:org and read:enterprise scope"
  _gh_reqs
  local flag_help flag_verbose
  zmodload zsh/zutil
  zparseopts -D -F -K -- \
   {h,-help}=flag_help \
   {d,-debug}=flag_verbose ||
    return 1
  [[ ! -z $flag_help ]] && echo $USAGE && return 0
  [[ ! -z $flag_verbose ]] &&  echo "DEBUG mode enabled" && DEBUG=true

  local get_orgs=$(curl -s -H "Authorization: token $GH_TOKEN" "$GITHUB_API_URL/enterprises/$GH_ENTERPRISE/orgs")
  [[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG:get orgs]\033[0m $get_orgs"

  local orgs=$(echo $get_orgs | jq -r '.[].login')
  [[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG:get orgs]\033[0m $orgs"

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
  declare -a members
  for org in $orgs; do
    # add members to the members array
    members+=(gh_org_users -n $org)
  done
  echo $members
}

# Create a PR via `gh pr create`. Title defaults to a humanized branch name.
# Body: Jira link (inferred from branch prefix, e.g. INFRA-324-...) + commit subjects
# since fork from main, merge commits excluded.
gh_pr_create() {
  local USAGE="Usage: gh_pr_create [-d|--debug] [-h|--help] [-- <extra gh pr create args>]
  Creates a PR via 'gh pr create'.
  Title: prompted; default is a humanized version of the current branch name.
  Body:  Jira link (if branch starts with PROJ-123-) + commit subjects since fork from main."

  local flag_help flag_verbose
  zmodload zsh/zutil
  zparseopts -D -K -- \
    {h,-help}=flag_help \
    {d,-debug}=flag_verbose ||
    return 1

  [[ ! -z $flag_help ]] && echo $USAGE && return 0
  [[ ! -z $flag_verbose ]] && echo "DEBUG mode enabled" && DEBUG=true

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo -e "\033[31;1m[ERROR]\033[0m Not inside a git repository"
    return 1
  fi
  if ! command -v gh >/dev/null 2>&1; then
    echo -e "\033[31;1m[ERROR]\033[0m gh CLI not found in PATH"
    return 1
  fi

  local branch
  branch=$(git rev-parse --abbrev-ref HEAD)
  [[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG]\033[0m branch: $branch"

  if [[ "$branch" == "main" ]]; then
    echo -e "\033[31;1m[ERROR]\033[0m Refusing to create a PR from main"
    return 1
  fi

  # Jira ID = leading uppercase-prefix + dash + number. [^-]+ keeps it from
  # straddling dashes (ERE has no non-greedy quantifier).
  local jira_id="" remainder="$branch"
  if [[ "$branch" =~ '^([A-Z][^-]+-[0-9]+)-(.*)$' ]]; then
    jira_id="${match[1]}"
    remainder="${match[2]}"
  else
    read "jira_id?Jira ticket ID (blank to skip): "
  fi
  [[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG]\033[0m jira_id: $jira_id"
  [[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG]\033[0m remainder: $remainder"

  local default_title="${remainder//[-_\/]/ }"
  default_title="${(C)default_title}"
  local title="$default_title"
  vared -p "PR Title: " -c title
  [[ -z "$title" ]] && title="$default_title"

  local merge_base
  merge_base=$(git merge-base main HEAD 2>/dev/null)
  if [[ -z "$merge_base" ]]; then
    echo -e "\033[31;1m[ERROR]\033[0m Could not find merge base with main"
    return 1
  fi
  [[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG]\033[0m merge_base: $merge_base"

  local changes
  changes=$(git log --no-merges --reverse --pretty=format:'- %s' "$merge_base"..HEAD)
  [[ -z "$changes" ]] && echo -e "\033[33;1m[WARN]\033[0m No non-merge commits since fork from main"

  local body
  if [[ -n "$jira_id" ]]; then
    body="[$jira_id](https://submittable.atlassian.net/browse/$jira_id)

## Changes:
$changes"
  else
    body="## Changes:
$changes"
  fi

  [[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG]\033[0m body:\n$body"

  gh pr create --title "$title" --body "$body" "$@"
}

gha_cancel_workflow() {
  local USAGE="Usage: cancel_workflow [OWNER] [REPO] [RUN_ID]
   Input values:
     GITHUB_TOKEN - personal access token with repo:workflow scope (or set inline)
     OWNER         - repo owner or org
     REPO          - repo name
     WORKFLOW_ID   - optional workflow file name or ID to narrow search
   "
  [[ -z "$GITHUB_TOKEN" ]] && GITHUB_TOKEN=$(gh auth token 2>/dev/null)
  [[ -z "$GITHUB_TOKEN" ]] && echo "GITHUB_TOKEN not set and 'gh auth token' returned nothing — run 'gh auth login'" && return 1
  local OWNER=$1
  local REPO=$2
  local WORKFLOW_ID=$3

  [[ -z $3 ]] && echo "Missing required arguments" && echo "$USAGE" && return 1


  set -euo pipefail

  if [[ -z "${4}" ]]; then
    RUN_ID="$4"
  else
    if [[ -n "$WORKFLOW_ID" ]]; then
      echo "Finding latest run for workflow: $WORKFLOW_ID"
      RUN_ID=$(curl -sS -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/repos/$OWNER/$REPO/actions/workflows/$WORKFLOW_ID/runs?per_page=1" \
        | grep -oP '"id":\s*\K[0-9]+' | head -n1)
    else
      echo "Finding latest run for repo: $OWNER/$REPO"
      RUN_ID=$(curl -sS -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/repos/$OWNER/$REPO/actions/runs?per_page=1" \
        | grep -oP '"id":\s*\K[0-9]+' | head -n1)
    fi
  fi

  if [[ -z "$RUN_ID" ]]; then
    echo "Could not determine RUN_ID." >&2
    return 1
  fi

  echo "Cancelling run ID: $RUN_ID"

  curl -sS -X POST -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/$OWNER/$REPO/actions/runs/$RUN_ID/cancel" \
    -o /tmp/cancel_response.json -w "\nHTTP status: %{http_code}\n"

  echo "Response preview:"
  if command -v jq >/dev/null 2>&1; then
    jq -r 'to_entries|map("\(.key): \(.value|tostring)")|.[]' /tmp/cancel_response.json 2>/dev/null || cat /tmp/cancel_response.json
  else
    cat /tmp/cancel_response.json
  fi
}
