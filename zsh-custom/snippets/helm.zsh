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

helm_inflate() {
  local _USAGE="Usage : helm_inflate \033[34m[<input_yaml>] [<output_dir>]\033[0m
       Inflate a Helm-rendered multi-document YAML file by splitting each
       document into a separate file at the path declared in its
       '# Source: next/templates/<path>' marker, recreating the chart layout.

       Repeated sources (same path) are concatenated into the same file as
       multiple YAML documents separated by '---'.

       \033[34m<input_yaml>\033[0m  File to read (default: ./next.full.yaml)
       \033[34m<output_dir>\033[0m  Directory to write into (default: ./inflated)

      Options:
      -h|--help     Display this message"

  zmodload zsh/zutil
  local -a help
  zparseopts -D -F -K -- \
    h=help -help=help ||
  return 1

  [[ -n $help ]] && { echo -e $_USAGE; return 0; }

  [[ -z $1 ]] && echo -e "\033[31;1m[ERROR]\033[0m Input File is required.\n" && echo -e $_USAGE && return 1
  local input=${1}
  local outdir=${2:-./}

  if [[ ! -f $input ]]; then
    echo -e "\033[31;1m[ERROR]\033[0m Input file not found: $input" >&2
    return 1
  fi

  mkdir -p -- $outdir

  awk -v outdir="$outdir" '
    BEGIN { state = "init"; target = "" }

    /^---$/ {
      state = "expect_source"
      target = ""
      next
    }

    state == "expect_source" {
      if ($0 ~ /^# Source: next\/templates\//) {
        rel = $0
        sub(/^# Source: next\/templates\//, "", rel)
        target = outdir "/" rel
        dir = target
        sub(/\/[^\/]+$/, "", dir)
        if (!(dir in dirs_made)) {
          system("mkdir -p \"" dir "\"")
          dirs_made[dir] = 1
        }
        print "---" >> target
        print $0 >> target
        state = "in_block"
        next
      } else {
        state = "init"
        target = ""
      }
    }

    state == "in_block" && target != "" {
      print $0 >> target
    }
  ' "$input"

  local n=$(grep -c "^# Source: next/templates/" "$input")
  echo "helm_inflate: wrote $n document(s) from \"$input\" into \"$outdir\""
}
