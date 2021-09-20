#!/bin/sh
# this is a tool for fixing the author of an entire git repo history.
# often on this repo I have used various corporate accounts to commit and I need to fix that.
# original snip found at https://blog.tinned-software.net/rewrite-author-of-entire-git-repository/

function git-replace-author() {

if [[ $#  -ne 3 ]]; then
  local usage="Invalid input Please use the correct inputs
  git-replace-author <old_email> <new_email> <new_name>"

  echo -e "\\033[32;1m[INFO]\\033[0m ${usage}"
fi
if [[ $# -eq 3 ]]; then
  git filter-branch --env-filter '
  if [ "$GIT_COMMITTER_EMAIL" = "'$1'" ]; then
    export GIT_COMMITTER_NAME='$2'
    export GIT_COMMITTER_EMAIL='$3'
fi
if [ "$GIT_AUTHOR_EMAIL" = "'$1'" ]; then
  export GIT_AUTHOR_NAME='$2'
  export GIT_AUTHOR_EMAIL='$3'
    fi
    ' --tag-name-filter cat -- --all
  else
    echo "usage: $0 old_email new_email new_name"
    echo ""
    echo "    OLD_EMAIL     The email address to be replaced in the commits"
    echo "    NEW_EMAIL     The new author email address to be used in the commit matching OLD_EMAIL"
    echo "    NEW_NAME      The name which should be used in the commit matching OLD_EMAIL"
fi
}

git-replace-author $1 $2 $3
