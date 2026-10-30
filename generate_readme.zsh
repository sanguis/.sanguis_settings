#!/bin/zsh
# @file generate_readme.zsh
# @brief Regenerate README.md from the *.zsh snippet files in this directory.
# @description
#   Scans every *.zsh file (except this generator) for aliases and function
#   definitions and rebuilds README.md with a `# <filename>` section per file,
#   each holding `## Aliases` and `## Functions` subsections. Blank sections
#   are never written: a subsection with no entries is omitted, and a file
#   with no aliases and no functions gets no section at all (even if the old
#   README had a blurb for it).
#
#   Function descriptions come from, in order of precedence:
#     1. A `USAGE="..."` (also `_USAGE`/`usage`, single- or multi-line) string
#        defined inside the function. The `Usage: name ARGS` line becomes the
#        backticked signature (the first word is replaced by the real function
#        name), the next line becomes the one-line description, and any
#        remaining lines are emitted as an indented code block under the
#        bullet. Literal ANSI escapes (\033[..m) are stripped.
#     2. The existing bullet line in README.md (matched by name), kept
#        verbatim so hand-written descriptions survive regeneration.
#     3. The comment immediately above the function definition.
#   Aliases use the existing README line if present, else the alias target.
#   Items removed from the source files are dropped. Per-file blurbs and the
#   top intro paragraph are also carried over.
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
  Regenerates \$DIR/README.md from the *.zsh files in DIR and re-runs doctoc
  for the table of contents. Files with no aliases or functions get no
  section. A function's USAGE string (if it defines one) is used as its
  description; otherwise the existing README line, then the comment above
  the function, are used.

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
        # Only top-level bullets are curated text; indented continuation
        # lines (USAGE code blocks) are regenerated from source every run.
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

# Strip the common leading indentation from the caller's `dlines` array.
_dedent_dlines() {
  local l ind minind=-1 i
  for l in "${(@)dlines}"; do
    [[ -z $l ]] && continue
    ind=${#${l%%[^[:space:]]*}}
    (( minind < 0 || ind < minind )) && minind=$ind
  done
  if (( minind > 0 )); then
    for (( i = 1; i <= ${#dlines}; i++ )); do
      dlines[i]=${dlines[i]:$minind}
    done
  fi
}

# Render a function's USAGE string as README bullet line(s).
#   $1 function name, $2 raw USAGE text (may be multi-line)
# The "Usage: cmd ARGS" line (or a line whose first word is the function
# name) supplies the signature; the first other line is the inline
# description; any further lines go into an indented fenced block.
_usage_bullet() {
  local name=$1 raw=$2
  local -a lines dlines
  local l tok sig="" first="" i
  lines=("${(@f)raw}")

  for (( i = 1; i <= ${#lines}; i++ )); do
    l=${lines[i]}
    l=${l//\\033\[[0-9;]#m/}       # literal ANSI colour escapes
    l=${l//\\e\[[0-9;]#m/}
    l=${l//\\\"/\"}                # unescape \" and \'
    l=${l//\\\'/\'}
    l=${l//\`/\'}                  # backticks would break the markdown
    l=${l%%[[:space:]]#}           # trailing whitespace
    lines[i]=$l
  done

  for l in "${(@)lines}"; do
    tok=${${l##[[:space:]]#}%%[[:space:]]*}
    if [[ -z $sig && $l == (#i)[[:space:]]#usage[[:space:]]#:* ]]; then
      sig=${l#*:}
    elif [[ -z $sig && $tok == "$name" ]]; then
      sig=$l
    else
      dlines+=("$l")
    fi
  done

  if [[ -n $sig ]]; then
    sig=${${sig##[[:space:]]#}%%[[:space:]]#}
    sig=${sig//[[:space:]]##/ }
    # Always lead with the real function name (USAGE strings go stale).
    if [[ $sig == *' '* ]]; then sig="$name ${sig#* }"; else sig=$name; fi
  else
    sig=$name
  fi

  # Drop surrounding blank lines, then dedent by the common indentation.
  while (( ${#dlines} )) && [[ -z ${dlines[1]} ]]; do shift dlines; done
  while (( ${#dlines} )) && [[ -z ${dlines[-1]} ]]; do dlines[-1]=(); done
  _dedent_dlines

  # Inline description = the first paragraph: consecutive lines up to a blank
  # line, an option line (`-x`), a short `Label:` line (Options:, Example:,
  # Note: ...) or a line indented deeper than the paragraph's first line.
  # Wrapped prose is re-joined into one line.
  local -a para
  local pl ind base_ind=-1
  while (( ${#dlines} )); do
    l=${dlines[1]}
    [[ -z ${l//[[:space:]]/} ]] && break
    ind=${#${l%%[^[:space:]]*}}
    (( base_ind < 0 )) && base_ind=$ind
    (( ind > base_ind )) && break
    pl=${${l##[[:space:]]#}%%[[:space:]]#}
    [[ $pl == -* ]] && break
    [[ $pl == [[:alpha:]]##([[:space:]]##[[:alpha:]]##)(#c0,2):* ]] && break
    para+=("$pl")
    shift dlines
  done
  first=${(j: :)para}

  # Whatever is left becomes the code block; dedent it on its own.
  while (( ${#dlines} )) && [[ -z ${dlines[1]} ]]; do shift dlines; done
  _dedent_dlines

  if [[ -n $first ]]; then
    print -r -- "- \`$sig\` — $first"
  else
    print -r -- "- \`$sig\`"
  fi
  if (( ${#dlines} )); then
    print -r -- '  ```'
    for l in "${(@)dlines}"; do
      if [[ -n $l ]]; then print -r -- "  $l"; else print; fi
    done
    print -r -- '  ```'
  fi
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
  local -A fusage
  local prev_comment block_first t ctext aname aval fdesc key n
  local curfunc in_usage ubuf uquote rtrim
  for f in $files; do
    base=${f:t}
    [[ $base == $SELF ]] && continue   # never document the generator itself

    # --- scan this file for aliases, functions and USAGE strings (in order) ---
    alias_list=(); funcs=(); fusage=()
    prev_comment=0; block_first=""
    curfunc=""; in_usage=0; ubuf=""; uquote=""
    while IFS= read -r line || [[ -n $line ]]; do
      # inside a multi-line USAGE string: accumulate until the closing quote
      if (( in_usage )); then
        rtrim=${line%%[[:space:]]#}
        if [[ $rtrim == *$uquote && $rtrim != *\\$uquote ]]; then
          ubuf+=${rtrim%$uquote}
          fusage[$curfunc]=$ubuf
          in_usage=0; ubuf=""
        else
          ubuf+="$line"$'\n'
        fi
        continue
      fi

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

      # unindented `}` closes the current top-level function
      if [[ $line == '}'* ]]; then
        curfunc=""; prev_comment=0; block_first=""; continue
      fi

      # function: `function name ... {`
      if [[ $t == (#b)function[[:space:]]##([A-Za-z0-9_-]##)*'{'* ]]; then
        funcs+=("${match[1]}"$'\t'"$block_first")
        curfunc=${match[1]}
        prev_comment=0; block_first=""; continue
      fi
      # function: `name() {` or `name () {`
      if [[ $t == (#b)([A-Za-z0-9_-]##)[[:space:]]#'()'[[:space:]]#'{'* ]]; then
        funcs+=("${match[1]}"$'\t'"$block_first")
        curfunc=${match[1]}
        prev_comment=0; block_first=""; continue
      fi
      # USAGE / _USAGE / usage="..." inside a function (first one wins)
      if [[ -n $curfunc && -z ${fusage[$curfunc]} && \
            $t == (#b)(local[[:space:]]##|)(_|)([Uu][Ss][Aa][Gg][Ee])=([\"\'])(*) ]]; then
        uquote=${match[4]}; rest=${match[5]}
        rtrim=${rest%%[[:space:]]#}
        if [[ $rtrim == *$uquote && $rtrim != *\\$uquote ]]; then
          fusage[$curfunc]=${rtrim%$uquote}
        else
          in_usage=1; ubuf="$rest"$'\n'
        fi
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
    # Nothing to document: no section at all, regardless of any old blurb.
    (( ${#alias_list} + ${#funcs} == 0 )) && continue

    b=$(_trim_blanks ${blurb[$base]})

    print
    print -r -- "---"
    print
    print -r -- "# $base"
    print
    if [[ -n $b ]]; then
      print -r -- "$b"
    else
      print -r -- "_TODO: describe this file._"
    fi

    # Subsections are only emitted when they have content; a file with no
    # aliases (or no functions) simply has no such heading.
    if (( ${#alias_list} )); then
      print
      print -r -- "## Aliases"
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

    if (( ${#funcs} )); then
      print
      print -r -- "## Functions"
      for n in $funcs; do
        aname=${n%%$'\t'*}; fdesc=${n#*$'\t'}
        key="$base::$aname"
        if [[ -n ${fusage[$aname]} ]]; then
          _usage_bullet "$aname" "${fusage[$aname]}"
        elif [[ -n ${desc[$key]} ]]; then
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
