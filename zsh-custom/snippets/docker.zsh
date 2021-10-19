docker_run() {
  DIR=$(pwd)
  DOCKER=''
  SSH=''
  _USAGE="Usage : docker_run  [options] [--] image command
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
    s|ssh     ) SSH="--volume $DIR:$DIR"  ;;

    * ) echo -e "\033[31;1m[ERROR]\033[0m Option does not exist : $OPTARG\n"
        echo ${usage}; return 1   ;;

    esac    # --- end of case ---
  done
  shift $(($OPTIND-1))

  IMAGE=$1

  shift $((OPTIND-1))
  COMMAND=$@


  docker run --rm -it --volume `pwd`:`pwd` -v /var/run/docker.sock:/var/run/docker.sock -w `pwd` node-docker /bin/sh
}
