#!/bin/zsh

# Sets GH_TOKEN as an env
alias gh_token=$(gh auth token)

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

# ---------------------------------------------------------------------------
# PR helpers shared by gh_pr_create / gh_pr_update
# ---------------------------------------------------------------------------

# Verify we're inside a git repo, gh is installed, and we're not on BASE.
# Usage: _gh_pr_preflight BASE
_gh_pr_preflight() {
  local base=$1
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
  if [[ "$branch" == "$base" ]]; then
    echo -e "\033[31;1m[ERROR]\033[0m Refusing to operate on a PR from $base"
    return 1
  fi
}

# Print the Jira ID at the start of a branch name (PROJ-123-foo -> PROJ-123).
# Prints nothing if the branch doesn't start with one.
# Jira ID = leading uppercase-prefix + dash + number. [^-]+ keeps it from
# straddling dashes (ERE has no non-greedy quantifier).
# Usage: _gh_pr_jira_from_branch BRANCH
_gh_pr_jira_from_branch() {
  [[ "$1" =~ '^([A-Z][^-]+-[0-9]+)-(.*)$' ]] && echo "${match[1]}"
  return 0
}

# Print the hashes of non-merge commits since fork from BASE, oldest first.
# Only commits authored by the local git user (git config user.email, falling
# back to user.name) are listed, so commits pulled in from other people are
# skipped. Pass --all-authors as the second arg to include everyone.
# Usage: _gh_pr_commits BASE [--all-authors]
_gh_pr_commits() {
  local base=$1 merge_base
  merge_base=$(git merge-base "$base" HEAD 2>/dev/null)
  if [[ -z "$merge_base" ]]; then
    echo -e "\033[31;1m[ERROR]\033[0m Could not find merge base with $base" >&2
    return 1
  fi
  [[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG]\033[0m merge_base: $merge_base" >&2

  local -a author_filter
  if [[ "$2" != "--all-authors" ]]; then
    local me
    me=$(git config user.email)
    [[ -z "$me" ]] && me=$(git config user.name)
    if [[ -z "$me" ]]; then
      echo -e "\033[33;1m[WARN]\033[0m git user.email/user.name not set; listing commits from all authors" >&2
    else
      # --fixed-strings makes --author a literal match instead of a regex
      author_filter=(--fixed-strings --author="$me")
      [[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG]\033[0m author filter: $me" >&2
    fi
  fi
  git rev-list --no-merges --reverse $author_filter "$merge_base"..HEAD
}

# Print JSON {number,url,body} for the current branch's open PR, or nothing
# (exit 1) if there isn't one.
# Usage: _gh_pr_find
_gh_pr_find() {
  local branch pr_json
  branch=$(git rev-parse --abbrev-ref HEAD)
  pr_json=$(gh pr list --head "$branch" --state open --limit 1 --json number,url,body 2>/dev/null | jq -c '.[0] // empty')
  [[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG]\033[0m open PR for $branch: ${pr_json:-none}" >&2
  [[ -n "$pr_json" ]] || return 1
  print -r -- "$pr_json"
}

# Print one "- <full commit message>" entry for HASH (trailing newlines trimmed).
# Usage: _gh_pr_commit_entry HASH
_gh_pr_commit_entry() {
  local entry
  entry=$(git log -1 --pretty=format:'- %B' "$1")
  print -r -- "${entry%%$'\n'##}"
}

# Print "- <message>" entries for the local user's non-merge commits since fork
# from BASE. Pass --all-authors as the second arg to include everyone's commits.
# Usage: _gh_pr_changes BASE [--all-authors]
_gh_pr_changes() {
  local hash
  for hash in $(_gh_pr_commits "$1" "$2"); do
    _gh_pr_commit_entry "$hash"
  done
}

# Build a PR body from an (optional) Jira ID and a block of change entries.
# Usage: _gh_pr_body JIRA_ID CHANGES
_gh_pr_body() {
  local jira_id=$1 changes=$2
  if [[ -n "$jira_id" ]]; then
    echo "[$jira_id](https://submittable.atlassian.net/browse/$jira_id)"
    echo
  fi
  echo "## Changes:"
  print -r -- "$changes"
}

# Read a PR body on stdin and print it with NEW_ENTRIES appended to the end of
# the "## Changes:" section (before the next "## " heading, or at EOF).
# If the body has no "## Changes:" section one is added at the end.
# Usage: _gh_pr_append_changes NEW_ENTRIES <<< "$body"
_gh_pr_append_changes() {
  NEW_ENTRIES="$1" awk '
    function flush(   i) {
      # drop trailing blank lines from the section, then append the new entries
      while (n > 0 && buf[n] ~ /^[[:space:]]*$/) n--
      for (i = 1; i <= n; i++) print buf[i]
      print ENVIRON["NEW_ENTRIES"]
      n = 0; in_changes = 0; done = 1
    }
    in_changes && /^##[[:space:]]/            { flush(); print "" }
    !done && /^##[[:space:]]*Changes:?[[:space:]]*$/ { in_changes = 1; print; next }
    in_changes                                { buf[++n] = $0; next }
                                              { print }
    END {
      if (in_changes) flush()
      else if (!done) { print ""; print "## Changes:"; print ENVIRON["NEW_ENTRIES"] }
    }
  '
}

gh_pr_create() {
  local USAGE="Usage: gh_pr_create [-d|--debug] [-h|--help] [-b|--base BASE] [-a|--all-authors] [-- <extra gh pr create args>]
  Creates a PR via 'gh pr create'. Refuses if the branch already has an open PR.
  Title: prompted; default is a humanized version of the current branch name.
  Body:  Jira link (if branch starts with PROJ-123-) + your commit messages since fork from BASE (default: main).
         Only commits authored by the local git user are listed; -a includes commits pulled in from others.
  Find additional args with 'gh pr create --help' or 'gh pr create -- <extra args>'"

  local flag_help flag_verbose flag_base flag_all_authors
  zmodload zsh/zutil
  zparseopts -D -K -- \
    {b,-base}:=flag_base \
    {a,-all-authors}=flag_all_authors \
    {h,-help}=flag_help \
    {d,-debug}=flag_verbose ||
    return 1

  [[ ! -z $flag_help ]] && echo $USAGE && return 0
  [[ ! -z $flag_verbose ]] && echo "DEBUG mode enabled" && DEBUG=true
  local base="${flag_base[-1]:-main}"
  local author_mode=""; [[ -n $flag_all_authors ]] && author_mode="--all-authors"
  local repo="$(git remote get-url origin)"

  _gh_pr_preflight "$base" || return 1

  local branch
  branch=$(git rev-parse --abbrev-ref HEAD)

  local existing
  if existing=$(_gh_pr_find); then
    echo -e "\033[31;1m[ERROR]\033[0m An open PR already exists for $branch: $(print -r -- "$existing" | jq -r '.url')"
    echo "Use gh_pr_update to add new changes to it."
    return 1
  fi

  local jira_id remainder="$branch"
  jira_id=$(_gh_pr_jira_from_branch "$branch")
  if [[ -n "$jira_id" ]]; then
    remainder="${branch#$jira_id-}"
  else
    read "jira_id?Jira ticket ID (blank to skip): "
  fi
  [[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG]: Auto Jira ticket and title search results \033[0m jira_id: $jira_id
    Title: $remainder"

  local default_title="${remainder//[-_\/]/ }"
  default_title="${(C)default_title}"
  local title="$default_title"
  vared -p "PR Title: " -c title
  [[ -z "$title" ]] && title="$default_title"

  local changes
  changes=$(_gh_pr_changes "$base" $author_mode) || return 1
  [[ -z "$changes" ]] && echo -e "\033[33;1m[WARN]\033[0m No non-merge commits by you since fork from $base (use -a to include all authors)"

  local body
  body=$(_gh_pr_body "$jira_id" "$changes")

  [[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG] PR create Parameters \033[0m
  --body:
  $body
  --title: $title
  --base: $base
  --repo \"$repo\"
  Additional args: $@
  "

  # No --head: gh defaults the head to the current branch and pushes it to the
  # remote automatically if it isn't there yet. Passing --head explicitly would
  # make gh assume the ref already exists remotely and skip that push.
  gh pr create --title "$title"  --body "$body" "$@" --base $base
}

gh_pr_update() {
  local USAGE="Usage: gh_pr_update [-d|--debug] [-h|--help] [-b|--base BASE] [-a|--all-authors] [-n|--no-commits] [-m|--message MSG]... [-- <extra gh pr edit args>]
  Appends new entries to the '## Changes:' section of the current branch's open PR.
  By default every non-merge commit authored by you since fork from BASE (default: main)
  that is not already listed in the PR body is appended. Commits pulled in from
  other authors (e.g. via merge/rebase of BASE) are skipped.
  -m MSG            append MSG as an extra entry (repeatable)
  -n|--no-commits   don't scan commits; only append -m messages
  -a|--all-authors  include commits from all authors, not just you
  Find additional args with 'gh pr edit --help'"

  local flag_help flag_verbose flag_base flag_no_commits flag_message flag_all_authors
  zmodload zsh/zutil
  zparseopts -D -K -- \
    {b,-base}:=flag_base \
    {m,-message}+:=flag_message \
    {n,-no-commits}=flag_no_commits \
    {a,-all-authors}=flag_all_authors \
    {h,-help}=flag_help \
    {d,-debug}=flag_verbose ||
    return 1

  [[ ! -z $flag_help ]] && echo $USAGE && return 0
  [[ ! -z $flag_verbose ]] && echo "DEBUG mode enabled" && DEBUG=true
  local base="${flag_base[-1]:-main}"
  local author_mode=""; [[ -n $flag_all_authors ]] && author_mode="--all-authors"

  _gh_pr_preflight "$base" || return 1

  local pr_json pr_number pr_url body
  if ! pr_json=$(_gh_pr_find); then
    echo -e "\033[31;1m[ERROR]\033[0m No open PR found for the current branch (create one with gh_pr_create)"
    return 1
  fi
  pr_number=$(print -r -- "$pr_json" | jq -r '.number')
  pr_url=$(print -r -- "$pr_json" | jq -r '.url')
  body=$(print -r -- "$pr_json" | jq -r '.body' | tr -d '\r')
  [[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG]\033[0m PR #$pr_number $pr_url\n--- current body ---\n$body\n--------------------"

  # Collect entries not already present in the body. A commit is considered
  # present if its first line ("- <subject>") already appears in the body.
  local -a new_entries
  local hash entry subject
  if [[ -z $flag_no_commits ]]; then
    for hash in $(_gh_pr_commits "$base" $author_mode); do
      entry=$(_gh_pr_commit_entry "$hash")
      subject="${entry%%$'\n'*}"
      if grep -qxF -- "$subject" <<< "$body"; then
        [[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG]\033[0m already listed: $subject"
      else
        new_entries+=("$entry")
      fi
    done
  fi

  # -m messages: zparseopts gives (-m msg1 --message msg2 ...); take every value.
  local i
  for ((i = 2; i <= ${#flag_message}; i += 2)); do
    new_entries+=("- ${flag_message[$i]}")
  done

  if (( ${#new_entries} == 0 )); then
    echo -e "\033[32;1m[INFO]\033[0m Nothing new to add to PR #$pr_number"
    return 0
  fi

  local new_block="${(F)new_entries}"
  local new_body
  new_body=$(_gh_pr_append_changes "$new_block" <<< "$body")

  [[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG] PR edit Parameters \033[0m
  PR: #$pr_number
  --body:
  $new_body
  Additional args: $@
  "

  echo -e "\033[32;1m[INFO]\033[0m Appending to PR #$pr_number:\n$new_block"
  gh pr edit "$pr_number" --body "$new_body" "$@"
}

gha_cancel_workflow() {
  local USAGE="Usage: cancel_workflow [OWNER] [REPO] [RUN_ID]
   Input values:
     OWNER         - repo owner or org
     REPO          - repo name
     WORKFLOW_ID   - optional workflow file name or ID to narrow search
   "
  local flag_help flag_verbose
  zmodload zsh/zutil
  zparseopts -D -K -- \
    {h,-help}=flag_help \
    {d,-debug}=flag_verbose ||
    return 1

  [[ ! -z $flag_help ]] && echo $USAGE && return 0
  [[ ! -z $flag_verbose ]] && echo "DEBUG mode enabled" && DEBUG=true
  [[ -z "$GITHUB_TOKEN" ]] && GITHUB_TOKEN=$(gh auth token 2>/dev/null)
  [[ -z "$GITHUB_TOKEN" ]] && echo "GITHUB_TOKEN not set and 'gh auth token' returned nothing — run 'gh auth login'" && return 1
  local OWNER=$1
  local REPO=$2
  local RUN_ID=$3
  local WORKFLOW_ID=$4

  [[ -z $3 ]] && echo "Missing required arguments" && echo "$USAGE" && return 1


#  if [[ -z "${3}" ]]; then
#    RUN_ID="$3"
#  else
#    if [[ -n "$WORKFLOW_ID" ]]; then
#      echo "Finding latest run for workflow: $WORKFLOW_ID"
#      RUN_ID=$(curl -sS -H "Authorization: token $GITHUB_TOKEN" \
#        "https://api.github.com/repos/$OWNER/$REPO/actions/workflows/$WORKFLOW_ID/runs?per_page=1" \
#        | grep -oP '"id":\s*\K[0-9]+' | head -n1)
#    else
#      echo "Finding latest run for repo: $OWNER/$REPO"
#      RUN_ID=$(curl -sS -H "Authorization: token $GITHUB_TOKEN" \
#        "https://api.github.com/repos/$OWNER/$REPO/actions/runs?per_page=1" \
#        | grep -oP '"id":\s*\K[0-9]+' | head -n1)
#    fi
#  fi
#
#  if [[ -z "$RUN_ID" ]]; then
#    echo "Could not determine RUN_ID." >&2
#    return 1
#  fi

  echo -e "\033[32;1mCancelling run ID:\033[0m $RUN_ID for $OWNER/$REPO"

  # Append HTTP status on its own trailing line so we can split it off the body.
  local cancel_response=$(curl -sS -X POST \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/$OWNER/$REPO/actions/runs/$RUN_ID/force-cancel" \
    -w $'\n%{http_code}')
  local http_status=${cancel_response##*$'\n'}
  local cancel_body="${cancel_response%$'\n'*}"

  [[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG]\033[0m Raw response:\n$cancel_body"
  [[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG]\033[0m HTTP status: $http_status"

  echo "Response preview:"
  if command -v jq >/dev/null 2>&1; then
    echo "$cancel_body" | jq -r 'to_entries|map("\(.key): \(.value|tostring)")|.[]' 2>/dev/null || echo "$cancel_body"
  else
    echo "$cancel_body"
  fi
  if [[ $http_status -ne 409 ]]; then
    local message=$(echo "$cancel_body" | jq -r '.message' 2>/dev/null)
    if [[ "$message" == "Cannot cancel a workflow re-run that has not yet queued." ]]; then
      echo -e "\033[32;1m[INFO]\033[0m Cancel request rejected because run is not yet queued. Attempting to delete run $RUN_ID instead."
      local delete_response=$(curl -sS -X DELETE \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github+json" \
        "https://api.github.com/repos/$OWNER/$REPO/actions/runs/$RUN_ID" \
        -w $'\n%{http_code}')
      local delete_http_status="${delete_response##*$'\n'}"
      local delete_body="${delete_response%$'\n'*}"
      [[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG]\033[0m Raw delete response:\n$delete_body"
      [[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG]\033[0m HTTP status: $delete_http_status"
      if [[ "$delete_http_status" -eq 204 ]]; then
        echo -e "\033[32;1m[INFO]\033[0m Run $RUN_ID has been successfully deleted."
      else
        echo -e "\033[31;1m[ERROR]\033[0m Failed to delete run $RUN_ID."
      fi
      return 0
    fi
  fi
}
