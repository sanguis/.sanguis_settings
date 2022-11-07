#!/bin/zsh
#
bb_open() {
local USAGE="Usage: bb_open [-hdb:] [--] MFACODE
Adds ENVs for MFA validation.
Options:
-h|help       Display this message
-d|debug      Debug output
-b|browser    Browser to open
"

while getopts ":hd:b" opt
do
  case $opt in

    h|help      ) echo $_USAGE; return 0   ;;
    d|debug 		) DEBUG=true 		;;
    m|mfa       ) local browser="${OPTARG}" ;;


    * ) echo -e "\033[31;1m[ERROR]\033[0m Option does not exist : $OPTARG\n"
      echo ${USAGE}; return 1   ;;

    esac    # --- end of case ---
  done
  shift $(($OPTIND-1))
  local remote=$(git config --get remote.origin.url)
  local https=$(echo ${remote} | sed 's/git@/https:\/\//')
  local egit=$(echo ${https} | sed 's/\.git$//')
  local addSlash=$(echo ${egit} | sed 's|\.org:|.org/|')

  [[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG]\033[0m URL to be opened: $addSlash"

  open "${addSlash}"

}
