#!/bin/zsh

fetch_and_checkout() {
git fetch --all && git checkout $1
}


# @description Pulls all repos in targeted directory
#
#  @example
#     gup src
#
#  @arg $1 Directory to scan.
#  @arf $2 Depth (defaults to 3)
#
#  @exitcode 0 If successful.
#  @exitcode 1 If an empty string passed.)
gup () {
  local USAGE='USAGE:
  gup DIR DEPTHj (Optional)'
  [[ -z $1 ]] && echo -e "\033[31;1m[ERROR]\033[0m Directory input required" && echo $USAGE && return 1
  [[ -z $2 ]] && local DEPTH=3 || local DEPTH=$2

  for i in $(find $1 -name .git -type d -maxdepth $DEPTH | cut -f1 -d.)
  do cd $i
    echo $i
    git branch
    gp
  done

}
