#!/bin/zsh
# @file git_snippets
# @brief custom settings and alias's for the git cli
# @description


fetch_and_checkout() {
git fetch --all && git checkout $1
}


# @description Recursively Pulls all repos in targeted directory
#
#  @example
#     gup_recursive src
#
#  @arg $1 Directory to scan.
#  @arf $2 Depth (defaults to 3)
#
#  @exitcode 0 If successful.
#  @exitcode 1 If an empty string passed.)
gup_recursive() {
  local USAGE="USAGE: gup DIR DEPTH
  DEPTH defaults too 3 is optional "
  [[ -z $1 ]] && echo -e "\033[31;1m[ERROR]\033[0m Directory input required" && echo $USAGE && return 1
  [[ -z $2 ]] && local DEPTH=3 || local DEPTH=$2

  for i in $(find $1 -name .git -type d -maxdepth $DEPTH | cut -f1 -d.)
  do cd $i
    echo $i
    git branch
    git pull
  done
}

git_reclone() {

repo=$1
base=$(pwd)
cd $repo
git remote show origin
git remote get-url origin
remote-repo=$(git remote get-url origin)
remote_repo=$(git remote get-url origin)
cd $base
rm -rf $repo
git clone --recursive $remote_repo $repo
}
