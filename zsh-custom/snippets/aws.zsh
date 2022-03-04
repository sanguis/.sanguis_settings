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

vpc_nuke(){
  local usage="USAGE: vpc_nuke <VPC-ID>"
  [[ -z $1 ]] && echo -e "\033[31;1m[ERROR]\033[0m $usage" && return 1
  local vpc=$1

  aws ec2 describe-internet-gateways --filters 'Name=attachment.vpc-id,Values='$vpc | grep InternetGatewayId
  aws ec2 describe-subnets --filters 'Name=vpc-id,Values='$vpc | grep SubnetId
  aws ec2 describe-route-tables --filters 'Name=vpc-id,Values='$vpc | grep RouteTableId
  aws ec2 describe-network-acls --filters 'Name=vpc-id,Values='$vpc | grep NetworkAclId
  aws ec2 describe-vpc-peering-connections --filters 'Name=requester-vpc-info.vpc-id,Values='$vpc | grep VpcPeeringConnectionId
  aws ec2 describe-vpc-endpoints --filters 'Name=vpc-id,Values='$vpc | grep VpcEndpointId
  aws ec2 describe-nat-gateways --filter 'Name=vpc-id,Values='$vpc | grep NatGatewayId
  aws ec2 describe-security-groups --filters 'Name=vpc-id,Values='$vpc | grep GroupId
  aws ec2 describe-instances --filters 'Name=vpc-id,Values='$vpc | grep InstanceId
  aws ec2 describe-vpn-connections --filters 'Name=vpc-id,Values='$vpc | grep VpnConnectionId
  aws ec2 describe-vpn-gateways --filters 'Name=attachment.vpc-id,Values='$vpc | grep VpnGatewayId
  aws ec2 describe-network-interfaces --filters 'Name=vpc-id,Values='$vpc | grep NetworkInterfaceId
}

certbot_to_aws () {

_USAGE="Usage : certbot_to_aws  [-h:e:d:] [--] primary_domain
Creates cert and addts it to aws cert manager
Options:
-h|help       Display this message
-e|email      Emaill address for cert
-d|domain     Additional domains Can be multiple, put in quotes for wildcards

example:

certbot_to_aws -d \"*.foo.bar\" foo.com
"

_EMAIL="devops@maark.com"
_DOMAINS=""
while getopts ":he:d:" opt
do
  case $opt in

    h|help     )  echo $_USAGE; return 0   ;;
    e|email   ) _EMAIL="${OPTARG}"       ;;
    d|domain 		) _DOMAINS="$_DOMAINS -d ${OPTARG}" 		;;


    * ) echo -e "\033[31;1m[ERROR]\033[0m Option does not exist : $OPTARG\n"
      echo $_USAGE; return 1   ;;

    esac    # --- end of case ---
  done
  shift $(($OPTIND-1))

  [[ -z $1 ]]  && echo -e "\033[31;1m[ERROR]\033[0m At least one domain reqired. \n $_USAGE" && return 1

  local PRIMARY=$1
  local CERT_PATH="/tmp/live/$PRIMARY"
  _DOMAINS="-d $PRIMARY $_DOMAINS"
  # TODO: Check for existing cert and prompt for reimport

  echo -e "\033[32;1m[INFO]\033[0m Generating ceret for $1"
  certbot certonly -n --config-dir /tmp/ --work-dir /tmp/ --logs-dir /tmp \
    -m $_EMAIL \
    --agree-tos \
    --dns-route53 --server https://acme-v02.api.letsencrypt.org/directory \
    $_DOMAINS


  echo -e "\033[32;1m[INFO]\033[0m Adding Generated cert to AWS"
  aws acm import-certificate --certificate fileb://$CERT_PATH/cert.pem \
    --certificate-chain fileb://$CERT_PATH/fullchain.pem \
    --private-key fileb://$CERT_PATH/privkey.pem
}

aws_instance_id_by_project_env(){

local _USAGE="Usage: aws_instance_id_by_project_env [-hc] <NAME> <ENVIRONMENT>
Options:
-c|connect   Connect with SSM"

while getopts ":hc" opt
do
  case $opt in

    h|help     )  echo $_USAGE; return 0   ;;
    c|connect  )  local connect=TRUE       ;;

    * ) echo -e "\033[31;1m[ERROR]\033[0m Option does not exist : $OPTARG\n"
      echo $_USAGE; return 1   ;;

    esac    # --- end of case ---
  done
  shift $(($OPTIND-1))
  local project=$1
  local env=$2
  [[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG]\033[0m Project is $project
  Environment is $env"
  shift $(($OPTIND[-2]))
  local id_command="aws ec2 describe-instances --filters=Name=tag:Project,Values=$project --filters=Name=tag:Environment,Values=$env --query 'Reservations[].Instances[].InstanceId' --output=text"
  [[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG]\033[0m Getting id command: \n $id_command"
  local id=$(eval $id_command)
  [[ -z $connect ]] && echo $id && return 0
  aws ssm start-session --target $id
}

assume_role() {
  _USAGE="Usage : assume_role  [-h] [--] <role arn>
      Assumes a role setting session data as envs
      Options:
      -h|help            Display this messagae
      -s|session-name    (optional) Session Name. Defaults to, '$USER'

  "

  while getopts ":hs:" opt
  do
    case $opt in

    h|help     )  echo $_USAGE; return 0   ;;
    s|session-name  ) local SESSION_NAME=${OPTARG} ;;
    * ) echo -e "\033[31;1m[ERROR]\033[0m Option does not exist : $OPTARG\n"
        echo $_USAGE; return 1   ;;

    esac    # --- end of case ---
  done
  shift $(($OPTIND-1))
  [[ -z $1 ]] && echo -e "\033[31;1m[ERROR]\033[0m Please add a role arn to assume" && return 1
  [[ -z $SESSION_NAME ]] && local SESSION_NAME=$USER

  local GET_SESSION="aws sts assume-role \
    --role-arn $1 \
    --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
    --output text   --role-session-name $SESSION_NAME"\

  [[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG]\033[0m Get Session Command:\n $GET_SESSION"

  export $(printf "AWS_ACCESS_KEY_ID=%s AWS_SECRET_ACCESS_KEY=%s AWS_SESSION_TOKEN=%s" \
    $(eval $GET_SESSION))

}
