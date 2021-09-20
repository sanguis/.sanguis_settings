#!/bin/sh
# this is a tool for fixing the author of an entire git repo history.
# often on this repo I have used various corporate accounts to commit and I need to fix that.
# original snip found at https://blog.tinned-software.net/rewrite-author-of-entire-git-repository/

usage () {
  local usage="Invalid input Please use the correct inputs

  git-replace-author <old_email> <new_email> <new_name>

  OLD_EMAIL     The email address to be replaced in the commits
  NEW_EMAIL     The new author email address to be used in the commit matching OLD_EMAIL
  NEW_NAME      The name which should be used in the commit matching OLD_EMAIL"

  echo  "\\033[32;1m[INFO]\\033[0m ${usage}"
}

if [[ $#  -ne 3 ]]; then
  usage
  exit 1
fi
git filter-branch --env-filter '
if test "$GIT_AUTHOR_EMAIL" = "$1"
then
  GIT_AUTHOR_EMAIL="$2"
  GIT_AUTHOR_NAME="$3"
  fi
  if test "$GIT_COMMITTER_EMAIL" = "$1"
  then
    GIT_COMMITTER_EMAIL="$2"
    GIT_COMMITTER_NAME="$3"
  fi
  ' -- --all
