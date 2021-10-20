#
# Detect OS and provide settings for options between various OS's
#
# @author Josh Beauregard josh.beaureg@gmail.com
#

os () {
  OS=$(uname)
  [[ $DEBUG ]] && [[ ${DEBUG} ]] && echo -e "\033[34;1m[DEBUG]\033[0m uname: $OS"
  case $OS in
    Darwin ) return 'mac' ;;
    Linux ) return 'linux' ;;
  esac
}

#
clipboard_cmd() {
  case os in
    mac ) pbcopy $@ ;;
    Linux ) xclip $@ ;;
  esac
}
