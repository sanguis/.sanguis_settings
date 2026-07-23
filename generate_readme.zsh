#!/bin/zsh
# @file generate_readme.zsh
# @brief Regenerate README.md from the *.zsh snippet files in this directory.
# @description
#   Scans every *.zsh file (except this generator) for aliases and function
#   definitions and rebuilds README.md with a `# <filename>` section per file,
#   each holding `## Aliases` and `## Functions` subsections.
#
#   Existing hand-written descriptions are PRESERVED: for any alias/function
#   already documented (matched by name) the current bullet line is kept
#   verbatim. Newly discovered items get an auto-generated description (the
#   alias target, or the comment immediately above a function). Items removed
#   from the source files are dropped. Per-file blurbs and the top intro
#   paragraph are also carried over.
#
#   Finally, if `doctoc` is installed the table of contents is regenerated.
#
# @example
#   ./generate_readme.zsh                 # rewrite README.md in place
#   ./generate_readme.zsh -d ~/snippets   # target another directory
#   ./generate_readme.zsh -h              # help

emulate -L zsh
setopt extended_glob

local SELF=${0:t}

# ---------------------------------------------------------------------------
# 0. Parse options.
#    -h/--help  show usage
#    -d/--dir   directory whose README.md should be (re)generated
#               (defaults to this script's own directory)
# ---------------------------------------------------------------------------
local -a o_help o_dir
zparseopts -D -E -F -- \
  {h,-help}=o_help \
  {d,-dir}:=o_dir \
  || { print -ru2 -- "Usage: $SELF [-h] [-d DIR]"; return 1 2>/dev/null || exit 1; }

local DIR=${0:A:h}
if (( ${#o_dir} )); then
  DIR=${o_dir[-1]:A}
fi
local README="$DIR/README.md"

if (( ${#o_help} )); then
  print -r -- "Usage: $SELF [-h] [-d DIR]
  Regenerates \$DIR/README.md from the *.zsh files in DIR, preserving existing
  descriptions and re-running doctoc for the table of contents.

  -d, --dir DIR   directory to scan (default: the script's own directory,
                  currently $DIR)
  -h, --help      show this help"
  return 0 2>/dev/null || exit 0
fi

if [[ ! -d $DIR ]]; then
  print -ru2 -- "\033[31;1m[ERROR]\033[0m Not a directory: $DIR"
  return 1 2>/dev/null || exit 1
fi

# ---------------------------------------------------------------------------
# 1. Parse the existing README to preserve curated text.
#    desc[<file>::<name>]  -> full bullet line
#    blurb[<file>]         -> intro paragraph for that file (\n joined)
#    blurb[__MAIN__]       -> top intro paragraph
# ---------------------------------------------------------------------------
typeset -A desc blurb
local curfile="" cursub="" line rest name heading

if [[ -f $README ]]; then
  while IFS= read -r line; do
    if [[ $line == '## Aliases'* ]]; then cursub=aliases; continue; fi
    if [[ $line == '## Functions'* ]]; then cursub=functions; continue; fi
    if [[ $line == '#'[[:space:]]* && $line != '##'* ]]; then
      heading=${line#'# '}
      if [[ $heading == 'zsh-custom snippets' ]]; then
        curfile=__MAIN__
      else
        curfile=$heading
      fi
      cursub=intro
      continue
    fi
    case $cursub in
      aliases|functions)
        if [[ $line == '- `'* ]]; then
          rest=${line#'- `'}
          name=${rest%%\`*}      # up to closing backtick
          name=${name%% *}       # ...then up to first space (drop args)
          [[ -n $name ]] && desc[$curfile::$name]=$line
        fi
        ;;
      intro)
        [[ -n $curfile && $line != '---' ]] && blurb[$curfile]+="$line"$'\n'
        ;;
    esac
  done < $README
fi

# Strip leading/trailing blank lines from a stored blurb.
_trim_blanks() {
  local s=$1
  while [[ $s == $'\n'* ]]; do s=${s#$'\n'}; done
  while [[ $s == *$'\n' ]]; do s=${s%$'\n'}; done
  print -r -- "$s"
}

# Clean a raw comment line into a description candidate.
_clean_comment() {
  local c=$1
  while [[ $c == '#'* ]]; do c=${c#\#}; done      # drop leading #'s
  c=${c##[[:space:]]#}                            # drop leading spaces
  c=${c#@description}; c=${c#@brief}              # drop doc tags
  c=${c##[[:space:]]#}
  print -r -- "$c"
}

# ---------------------------------------------------------------------------
# 2. Emit the new README (without TOC; doctoc adds it afterwards).
#    Written to a temp file first, then moved into place, so a mid-run error
#    can never truncate the existing README.
# ---------------------------------------------------------------------------
local -a files
files=($DIR/*.zsh(N))
local TMP="$README.tmp.$$"

{
  print -r -- "# zsh-custom snippets"
  print
  if [[ -n ${blurb[__MAIN__]} ]]; then
    print -r -- "$(_trim_blanks ${blurb[__MAIN__]})"
  else
    print -r -- "Custom zsh aliases, functions, and completions grouped by tool. Each file is sourced into the shell to add helpers for a particular CLI or workflow."
  fi

  local f base b
  local -a alias_list funcs
  local prev_comment block_first t ctext aname aval fdesc key n
  for f in $files; do
    base=${f:t}
    [[ $base == $SELF ]] && continue   # never document the generator itself

    # --- scan this file for aliases and functions (in order) ---
    alias_list=(); funcs=()
    prev_comment=0; block_first=""
    while IFS= read -r line || [[ -n $line ]]; do
      # shebang
      if [[ $line == '#!'* ]]; then prev_comment=1; continue; fi

      t=${line##[[:space:]]#}          # trimmed line

      # comment line -> track first meaningful line of the block
      if [[ $t == '#'* ]]; then
        if (( ! prev_comment )); then block_first=""; fi
        ctext=$(_clean_comment "$t")
        if [[ -z $block_first && -n $ctext && $ctext != [-=#]## ]]; then
          block_first=$ctext
        fi
        prev_comment=1
        continue
      fi

      # blank line breaks comment adjacency
      if [[ -z $t ]]; then prev_comment=0; block_first=""; continue; fi

      # function: `function name ... {`
      if [[ $t == (#b)function[[:space:]]##([A-Za-z0-9_-]##)*'{'* ]]; then
        funcs+=("${match[1]}"$'\t'"$block_first")
        prev_comment=0; block_first=""; continue
      fi
      # function: `name() {` or `name () {`
      if [[ $t == (#b)([A-Za-z0-9_-]##)[[:space:]]#'()'[[:space:]]#'{'* ]]; then
        funcs+=("${match[1]}"$'\t'"$block_first")
        prev_comment=0; block_first=""; continue
      fi
      # alias: `alias name=value`
      if [[ $t == (#b)alias[[:space:]]##([A-Za-z0-9_-]##)=(*) ]]; then
        aname=${match[1]}; aval=${match[2]}
        aval=${aval%%[[:space:]]#}                       # trim trailing ws
        if [[ $aval == \"*\" || $aval == \'*\' ]]; then  # strip wrapping quotes
          aval=${aval[2,-2]}
        fi
        alias_list+=("$aname"$'\t'"$aval")
        prev_comment=0; block_first=""; continue
      fi

      prev_comment=0; block_first=""
    done < $f

    # --- emit the section ---
    print
    print -r -- "---"
    print
    print -r -- "# $base"
    print
    b=${blurb[$base]}
    if [[ -n $b ]]; then
      print -r -- "$(_trim_blanks $b)"
    else
      print -r -- "_TODO: describe this file._"
    fi

    print
    print -r -- "## Aliases"
    if (( ${#alias_list} == 0 )); then
      print -r -- "None."
    else
      for n in $alias_list; do
        aname=${n%%$'\t'*}; aval=${n#*$'\t'}
        key="$base::$aname"
        if [[ -n ${desc[$key]} ]]; then
          print -r -- "${desc[$key]}"
        else
          print -r -- "- \`$aname\` — \`$aval\`"
        fi
      done
    fi

    print
    print -r -- "## Functions"
    if (( ${#funcs} == 0 )); then
      print -r -- "None."
    else
      for n in $funcs; do
        aname=${n%%$'\t'*}; fdesc=${n#*$'\t'}
        key="$base::$aname"
        if [[ -n ${desc[$key]} ]]; then
          print -r -- "${desc[$key]}"
        elif [[ -n $fdesc ]]; then
          print -r -- "- \`$aname\` — $fdesc"
        else
          print -r -- "- \`$aname\`"
        fi
      done
    fi
  done
} > $TMP

mv -f $TMP $README
print -r -- "\033[32;1m[INFO]\033[0m Wrote $README"

# ---------------------------------------------------------------------------
# 3. Regenerate the table of contents.
# ---------------------------------------------------------------------------
if command -v doctoc >/dev/null 2>&1; then
  doctoc "$README" >/dev/null && print -r -- "\033[32;1m[INFO]\033[0m Updated table of contents with doctoc"
else
  print -r -- "\033[33;1m[WARN]\033[0m doctoc not found; skipped table of contents (npm i -g doctoc)"
fi
