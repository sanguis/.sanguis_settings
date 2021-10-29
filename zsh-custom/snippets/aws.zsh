#!/bin/zsh
alias aws_envs="env |grep AWS"

ecr_login() {
  _USAGE="Usage : ecr_login  [-hr:] [--] {2:inputs}
      logs into aws ecr based on the account id and default region.
      defaults to accunt number of current aws cli profile
      Options:
      -h|help       Display this message
      -r|region     AWS region
  "

  while getopts ":hr" opt
  do
    case $opt in

    h|help     )  echo $_USAGE; return 0   ;;
    r|region   ) _REGION="${OPTARG}"       ;;


    * ) echo -e "\033[31;1m[ERROR]\033[0m Option does not exist : $OPTARG\n"
        echo $_USAGE; return 1   ;;

    esac    # --- end of case ---
  done
  shift $(($OPTIND-1))
  # REGION setting
  [[ -z $_REGION ]] && [[ -z $AWS_DEFAULT_REGION ]] && echo -e "\033[31;1m[ERROR]\033[0m No region or default region set" && return 1
  [[ -z $_REGION ]] && _REGION=$AWS_DEFAULT_REGION
  [[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG]\033[0m Region: $_REGION"

  # Account number
  if [[ -z $1 ]]; then
    _ACCOUNT_NUMBER=$(aws sts get-caller-identity --output text --query 'Account')
  else
    _ACCOUNT_NUMBER=$1
  fi

  [[ $DEBUG ]]  && echo -e "\033[34;1m[DEBUG]\033[0m AWS Accoount #: $_ACCOUNT_NUMBER"
  _COMMAND="aws ecr get-login-password --region $_REGION| docker login --username AWS --password-stdin $_ACCOUNT_NUMBER.dkr.ecr.$_REGION.amazonaws.com"
  [[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG]\033[0m Running command:
  $_COMMAND"
  eval $_COMMAND
}