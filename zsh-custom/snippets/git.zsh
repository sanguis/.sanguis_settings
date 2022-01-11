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
i

  [[ -z $1 ]] &&
  for i in $(find ~/Desktop/Repos -name .git -type d -maxdepth 3 | cut -f1 -d.)
  do cd $i
    echo $i
    git branch
    gp
  done

}
