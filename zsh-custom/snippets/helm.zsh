#!/bin/zsho

helm_template() {
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

helm_replace_in_templates() {
  local _USAGE="Usage : helm_replace_in_templates \033[34m<search_pattern> <replacement_pattern>\033[0m
       Replace all occurrences of \033[34m<search_pattern>\033[0m with \033[34m<replacement_pattern>\033[0m in all YAML files within the 'templates' directory.
       Note: Search and replacement patterns should be provided as regular expressions, for the sed command.
       sed regex doc: https://www.gnu.org/software/sed/manual/sed.html#Regular-Expressions

       Common patterns that need escaping:
         .  (dot)  - escape as \.
         /  (slash)- escape as \/
         *  (asterisk) - escape as \*
         +  (plus) - escape as \+
         ?  (question mark) - escape as \?
         ( ) (parentheses) - escape as \( and \)
         [ ] (brackets) - escape as \[ and \]
         { } (curly braces) - escape as \{ and \}

      Options:
      -h|--help       Display this message
      -d|--debug    Enable debug mode"

  zmodload zsh/zutil
  zparseopts -D -F -K -- \
    d=debug -DEBUG=debug \
    h=help -HELP=help ||
  return 1

  [[ $#HELP == true ]] && echo $_USAGE && return 0

  [[ -n $DEBUG ]] && echo -e "\033[33;1m[DEBUG]\033[0m Called with arguments: $*\n"

  #[[ -z $1 || ! -v $2 ]] && { echo -e "\033[31;1m[ERROR]\033[0m Both \033[34m<search_pattern>\033[0m and \033[34m<replacement_pattern>\033[0m are required."; echo $_USAGE; return 1; }
  find templates -type f -name '*.yaml' -exec gsed -i -E "s/$1/$2/g" {} +
}
