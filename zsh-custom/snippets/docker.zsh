docker_run() {
  DIR=$(pwd)
  DOCKER=""
  SSH=""

  local _USAGE="Usage : docker_run  [options] [--] image command
  Runs dokcker condocker_runh volume mounts for the current dir and optiopnally mounts ssh or docker connections
  Options:dock
  -h|help       Display this message
  -d|docker     Mounts docker unix socker from parrent machine
  -s/ssh        Mounts $HOME/.ssh to /root/.ssh
  "

  while getopts "hds" opt
  do
    case $opt in

      h|help     )  echo $_USAGE; return 0   ;;
      d|docker   ) DOCKER="--volume /var/run/docker.sock:/var/run/docker.sock"  ;;
      s|ssh     ) SSH="--volume $HOME/.ssh:/root/.ssh"  ;;

      * ) echo -e "\033[31;1m[ERROR]\033[0m Option does not exist : $OPTARG\n"
        echo "${_USAGE}"; return 1   ;;

    esac
  done

  shift $(($OPTIND-1))

  local IMAGE=$1

  shift $(($OPTIND-1))
  local COMMAND=$@

  local run_command="docker run --rm -it --volume $DIR:$DIR $DOCKER $SSH  -w $DIR ${IMAGE} ${COMMAND}"
  [[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG]\033[0m
  SSH: $SSH
  DOCKER: $DOCKER
  IMAGE: $IMAGE
  COMMAND:  $COMMAND
  Full command to be run:
  ${run_command}"

  eval "${run_command}"

}
