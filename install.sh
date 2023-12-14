#!/usr/bin/env zsh
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
	-b|backup     Backup directory for existing files
	-D|debug      Set debugging output

	"
}    # ----------  end of function usage  ----------

#-----------------------------------------------------------------------
#  Handle command line arguments
#-----------------------------------------------------------------------

while getopts ":hvd:b:D" opt
do
	case $opt in

		h|help     )  usage; exit 0   ;;
		v|version  )  echo "$0 -- Version $__ScriptVersion"; exit 0   ;;
		d|dir 		) P=$OPTARG		;;
		b|backup	) local BACKUP_DIR=$OPTARG ;;
		D|debug		) DEBUG=true ;;

		* )  echo -e "\n  Option does not exist : $OPTARG\n"
			usage; exit 1   ;;

		esac    # --- end of case ---
	done
	shift $(($OPTIND-1))
	## set defaults

	[[ -z $P ]] && P=$HOME/.sanguis_settings
	[[ -z $BACKUP_DIR ]] && BACKUP_DIR=$HOME/.pre_sang_dotfiles


	OS=$(uname)

clone() {
	if [[ ! -d $P ]]
	then
		git clone --recursive https://github.com/sanguis/.sanguis_settings.git "$P"
		cd "$P" || exit 1
	fi
}
mac() {
	[[ $OS == "Darwin" ]] && source "$P/mac.sh"
}
update() {
	source update.sh "$P"
}

	## install powerline fonts
packages() {
  bash ./fonts/install.sh

	pip3 install powerline-status

}

# setup localfiles to be symbolic links and kept in local version control
# ~/.zshrc_user
# ~/.ssh/config
# TODO ~/.gitconfig
local_configs(){
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
}
#local_configs "${local_config_files[@]}"
# create symlinks
}

get_links() {
    local csv_file=$1
    local assoc_array_name=$2
    local column1_name=$3
    local column2_name=$4

    [[ ! -f $csv_file ]] && echo "links file not found." && return

    declare -A $assoc_array_name
local header_line=1
    while IFS=, read -r $column1_name $column2_name; do
        if [[ "$header_line" == "1"  ]]; then
            header_line=0
            continue
        fi
        $assoc_array_name[$column1_name]=$column2_name
    done < "$csv_file"

  if [[ $DEBUG  ]]; then
        echo "CSV file '$csv_file' has been converted to associative array '$assoc_array_name'"
        for key in "${!assoc_array_name[@]}"; do
            echo "Key: $key, Value: ${assoc_array_name[$key]}"
        done
  fi
}

function links() {
	[[ -z $1 ]] && echo "symlinks is empty or missing cant contunue" && return
	local symlinks=$1

	for k in $(symlinks[@]); do
		local target=$P/${k}
		local link=$(symlinks[${k}])
		#backup files
		if [ -f $link ]; then
			[ ! -d $BACKUP_DIR ] && mkdir $BACKUP_DIR
local backup_loc=$BACKUP_DIR/$link
			echo "$Link exists. moving existing file to $backup_loc"
			mv $link $backup_loc
		fi
#create symlinks
		[[ $DEBUG ]] && echo "ln -s ${target} ${link}"
		ln -s ${target} ${link}
	done
}

# Run all this if not debugging
if [[ ! $DEBUG ]]; then
 #clone
 #update
 #packages
 #mac
 # local_configs
  get_links "$P/links.csv" "symlinks" "target" "link"
  links $symlinks
	# source zshrc to start
source "$HOME/.zshrc"
fi
