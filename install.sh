#!/usr/bin/env bash
__ScriptVersion="rolling"

#===  FUNCTION  ================================================================
#         NAME:  usage
#  DESCRIPTION:  Display usage information.
#===============================================================================
function usage ()
{
  echo "Usage Installs sanguis's dot files :  $0 [options] [--]

    Options:
    -h|help       Display this message
    -v|version    Display script version
    -d|dir        Sets install dir defaults to $HOME/.sanguis_settings
"
}    # ----------  end of function usage  ----------

#-----------------------------------------------------------------------
#  Handle command line arguments
#-----------------------------------------------------------------------

while getopts ":hvd:" opt
do
  case $opt in

  h|help     )  usage; exit 0   ;;
  v|version  )  echo "$0 -- Version $__ScriptVersion"; exit 0   ;;
  d|dir 		) P=$OPTARG		;;

  * )  echo -e "\n  Option does not exist : $OPTARG\n"
      usage; exit 1   ;;

  esac    # --- end of case ---
done
shift $(($OPTIND-1))
[[ -z $P ]] && P=$HOME/.sanguis_settings

OS=$(uname)

if [[ ! -d $P ]]
then
  git clone --recursive https://github.com/sanguis/.sanguis_settings.git "$P"
  cd "$P" || exit 1
fi

[[ $OS == "Darwin" ]] && source "$P/mac.sh"

source update.sh "$P"
## install powerline fonts
bash ./fonts/install.sh

pip3 install powerline-status

if [ -f "$HOME/.zshrc" ]; then
  echo "backing up zshrc"
  ZSHDATA=$(cat ~/.zshrc)
  mv "$HOME/.zshrc" "$HOME/.zshrc_old"
  rm $HOME/.zshrc
  echo $ZSHDATA >> "$P/zshrc"
fi

# setup localfiles to be symbolic links and kept in local version control
# ~/.zshrc_user
# ~/.ssh/config
# TODO ~/.gitconfig

declare -A local_config_files
local_config_files['ssh_config']=$HOME/.ssh/config
local_config_files['zshrc_user']=$HOME/.zshrc_user
# local_config_files['gitconfig']=$HOME/.gitconfig
LOCAL_CONFIGS=$HOME/.local_configs
function local_configs() {
if [[ ! -d $LOCAL_CONFIGS ]]; then
  CUR=$(pwd)
  mkdir "$LOCAL_CONFIGS"
  cd "$LOCAL_CONFIGS" || exit 1
  echo "creating local con figs git repo and adding symbolic links"
  git init
  #links "${1[@]}"
  git add config
  git commit config --message "Adding empty config files"
  cd "$CUR" || exit 1

fi
#function_body
}
#local_configs "${local_config_files[@]}"
# create symlinks

source "$P/links.sh"

function links() {
  for k in $(links[@]); do
    [[ -f $(links[${k}]) ]] && return
    [[ $DEBUG ]] && echo "ln -s $P/${k} ${links[${k}]}"
    ln -s $P/${k} $(links[${k}])
  done
}
links

source "$HOME/.zshrc"
