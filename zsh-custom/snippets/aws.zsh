#!/bin/zsh

## Aliases
alias aws_envs="env |grep AWS"
complete -C '/usr/local/bin/aws_completer' aws
alias aws-id="aws sts get-caller-identity"
alias aws_region_eu1="export AWS_DEFAULT_REGION=eu-west-1"
alias aws_region_us1="export AWS_DEFAULT_REGION=us-east-1"
alias aws_region_us2="export AWS_DEFAULT_REGION=us-east-2"
alias aws-account-number="aws sts get-caller-identity --query Account --output text"

aws_profile() {
  [[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG]\033[0m switching aws profile to $1"
  export AWS_DEFAULT_PROFILE=$1
  export AWS_PROFILE=$1
  #aws-id
}
_aws_profile() {
# TODO: Figure out partial completion
  local profiles=($(aws configure list-profiles))
  [[ ${DEBUG} ]] && echo -e "\033[34;1m[DEBUG]\033[0m ${profiles}"
  compadd ${profiles}
}
compdef _aws_profile aws_profile


aws_mfa_session_token() {
  [[ -z $AWS_DEVICE_ARN ]] && echo -e "\033[31;1m[ERROR]\033[0m \$AWS_DEVICE_ARN note set please set this as a global before using" && return 1
  [[ -z $1 ]] && echo -e "\033[31;1m[ERROR]\033[0m mfa input code required" && return 1
  local device_arn=$AWS_DEVICE_ARN
  local mfa_code=$1
  local json_command="aws sts get-session-token --serial-number $device_arn --token-code $mfa_code"
  [[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG]\033[0m Getting json with:\n $json_command"
  local json=$(eval $json_command)
  export AWS_SESSION_TOKEN=$(echo $json |jq --raw-output ".Credentials.SessionToken" )
  [[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG]\033[0m AWS_SESSION_TOKEN set to: \n $AWS_SESSION_TOKEN"
}

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
