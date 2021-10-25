#!/bin/zsho

helm-template() {
  _USAGE="Usage : bal  [-he] [--] {2:inputs}
       what it does
      Options:
      -h|help       Display this message

  "

  while getopts ":he" opt
  do
    case $opt in

    h|help     )  echo $_USAGE; return 0   ;;

    * ) echo -e "\033[31;1m[ERROR]\033[0m Option does not exist : $OPTARG\n"
        echo $_USAGE; return 1   ;;

    esac    # --- end of case ---
  done
  shift $(($OPTIND-1))
  file=/tmp/$1
  helm template $(date) . > $file
  vim $file
}
