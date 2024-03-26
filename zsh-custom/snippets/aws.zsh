#!/bin/zsh

## Aliases
alias aws_envs="env |grep AWS"
alias aws-id="aws sts get-caller-identity"
alias aws_region_eu1="export AWS_DEFAULT_REGION=eu-west-1"
alias aws_region_eu_w2="export AWS_DEFAULT_REGION=eu-west-2"
alias aws_region_us-e1="export AWS_DEFAULT_REGION=us-east-1"
alias aws_region_us-e2="export AWS_DEFAULT_REGION=us-east-2"
alias aws_region_us-w1="export AWS_DEFAULT_REGION=us-west-1"
alias aws-account-number="aws sts get-caller-identity --query Account --output text"
alias ssm="aws ssm start-session --target"
alias asl="aws sso login"

complete -C '/usr/local/bin/aws_completer' aws

aws_profile() {
  _USAGE="Usage : aws_profile [-h] [--] <profile>
      Switches the AWS profile to input value.

      If ALready set use '-' to switch to previous profile.

      Options:
      -h|help       Display this message
      -d|debug      Debug output"

  while getopts ":hd:" opt
  do
    case $opt in

    h|help      )  echo $_USAGE; return 0   ;;
    d|debug 		) DEBUG=true 		;;

    * ) echo -e "\033[31;1m[ERROR]\033[0m Option does not exist : $OPTARG\n"
        echo $_USAGE; return 1   ;;

    esac    # --- end of case ---
  done
  local OLD_PROFILE=$OLD_AWS_DEFAULT_PROFILE
  local INPUT=$1
  local CURRENT_PROFILE=$AWS_DEFAULT_PROFILE

  if [[ $DEBUG ]]; then
    echo -e "\033[34;1m[DEBUGING INFO]:
    INPUT VALUE:      $INPUT
    Previous Profile: $OLD_PROFILE
    Current Profile:  $AWS_DEFAULT_PROFILE
    \033[0m"
  fi

  [[ -z ${INPUT} ]] && echo -e "\033[31;1m[ERROR]\033[0m No profile set" && return 1

  [[ ! -z ${CURRENT_PROFILE} ]] && export OLD_AWS_DEFAULT_PROFILE=${CURRENT_PROFILE}

  if [[ $1 == "-" ]]; then
    [[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG]\033[0m Switching to previous profile: $OLD_AWS_DEFAULT_PROFILE"
    local NEW_PROFILE=${OLD_PROFILE}
  else
    local NEW_PROFILE=${INPUT}
  fi

  # TODO: Check if profile exists. error if does not.

  export AWS_DEFAULT_PROFILE=${NEW_PROFILE}
  export AWS_PROFILE=${NEW_PROFILE}
  [[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG]\033[0m AWS_PROFILE set to $AWS_PROFILE"
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
  _USAGE="Usage : aws_mfa_session_token [-hmd:] [--] MFACODE
      Adds ENVs for MFA validation.
      Options:
      -h|help       Display this message
      -d|debug      Debug output
      -m|mfa        mfa device arn
  "

  while getopts ":hd:m" opt
  do
    case $opt in

    h|help      ) echo $_USAGE; return 0   ;;
    d|debug 		) DEBUG=true 		;;
    m|mfa       ) AWS_SESSION_TOKEN="${OPTARG}" ;;


    * ) echo -e "\033[31;1m[ERROR]\033[0m Option does not exist : $OPTARG\n"
        echo $_USAGE; return 1   ;;

    esac    # --- end of case ---
  done
  shift $(($OPTIND-1))

  [[ -z $AWS_DEVICE_ARN ]]  && AWS_DEVICE_ARN=$(aws iam list-mfa-devices --query "MFADevices[].SerialNumber" --output text)
  [[ -z $AWS_DEVICE_ARN ]]  && echo -e "\033[31;1m[ERROR]\033[0m \$AWS_DEVICE_ARN unable to retrieve MFA device.
  PLease set $AWS_DEVICE_ARN or use -m flag to set" && return 1
  [[ -z $1 ]] && echo -e "\033[31;1m[ERROR]\033[0m mfa input code required" && return 1
  local device_arn=$AWS_DEVICE_ARN
  local mfa_code=$1
  local json_command="aws sts get-session-token --serial-number $device_arn --token-code $mfa_code"
  [[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG]\033[0m Getting json with:\n $json_command"
  local json=$(eval $json_command)
  export AWS_SESSION_TOKEN=$(echo $json |jq --raw-output ".Credentials.SessionToken" )
 ## export AWS_ACCESS_KEY_ID=$(echo $json |jq --raw-output ".Credentials.AccessKeyId" )
 ##  export AWS_SECRET_ACCESS_KEY=$(echo $json |jq --raw-output ".Credentials.SecretAccessKey" )
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

# by making this an alis and not a fuctiun it's eaier to pass extra flags from the function, also it can override flags set in the alais

alias ec2-ls="aws ec2 describe-instances --output table --query \"Reservations[].Instances[].{Name: Tags[?Key == 'Name'].Value | [0], Id: InstanceId, State: State.Name, Type: InstanceType, Placement: Placement.AvailabilityZone}\""
ssm_by_name () {
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
  local name=$1
  local env=$2
  shift $(($OPTIND[-2]))
  local id_command="aws ec2 describe-instances --filters=Name=tag:Name,Values=$name --query 'Reservations[].Instances[].InstanceId' --output=text"
  [[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG]\033[0m Getting id command: \n $id_command"
  local id=$(eval $id_command)
  [[ -z $connect ]] && echo $id && return 0
  aws ssm start-session --target $id
}
_ssm_by_name() {
# TODO: Figure out partial completion
local instances=($(aws ec2 describe-instances --query "Reservations[*].Instances[*].{Name:Tags[?Key=='Name']|[0].Value}" --output text))
  [[ ${DEBUG} ]] && echo -e "\033[34;1m[DEBUG]\033[0m ${instances}"
  compadd -a ${instances}
}
compdef _ssm_by_name ssm_by_name

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

ssm-connect() {
local id=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values=$1" --output text --query 'Reservations[*].Instances[*].InstanceId')
match="^[a-zA-Z0-9_:-]+$"
if [[ $id =~ $match ]]; then
  aws ssm start-session --target $id
else
  echo "Multiple IDs returned:"
  echo "$id"
fi
}
compdef _aws_ssm ssm-connect

_aws_ssm() {
  local name=($(aws ec2 describe-instances --output text  --filters "Name=instance-state-name,Values=running" --query "Reservations[].Instances[].{Name: Tags[?Key == 'Name'].Value | [0] }"))
  compadd ${name}
}
compdef _aws_ssm aws_ssm

ssm-ls() {

[[ ! -z $1 ]] && local region=" --region $1"
aws ssm get-inventory ${region}
}
compdef _aws_region ssm-ls

aws-ls() {
  _USAGE="Usage: aws-ls [-hrp] [--region --profile] <role arn>
      Assumes a role setting session data as envs
      Options:
      -h|help            Display this messagae
      -p|profile         Set the AWS profile
      -r|region          Set the AWS region to ls
  "

  while getopts ":hr:p:" opt
  do
    case $opt in

    h|help     )  echo $_USAGE; return 0   ;;
    r|region  ) local $AWS_DEFAULT_REGION=${OPTARG} ;;
    p|profile  ) local $AWS_DEFAULT_PROFILE=${OPTARG} ;;
    * ) echo -e "\033[31;1m[ERROR]\033[0m Option does not exist : $OPTARG\n"
        echo $_USAGE; return 1   ;;

    esac    # --- end of case ---
  done
  shift $(($OPTIND-1))
aws ec2 describe-instances \
	--output table \
	--query "Reservations[].Instances[].{Name: Tags[?Key == 'Name'].Value | [0], Id: InstanceId, State: State.Name, Type: InstanceType, Placement: Placement.AvailabilityZone}" \
}
compdef _aws_profile aws-ls

aws_env_unset() {
  unset AWS_ACCESS_KEY_ID
  unset AWS_SECRET_ACCESS_KEY
  unset AWS_SESSION_TOKEN
  unset AWS_DEFAULT_REGION
  unset AWS_DEFAULT_PROFILE
}
aws_env_reset() {
  aws_env_unset
  $(aws configure export-credentials --format env)
}
asg_suspend() {
  _USAGE="Usage : asg_suspend  [-h] [--] <ASG_NAME>
      Suspends autoscaling group
      Options:
      -h|help            Display this messagae
  "

  while getopts ":h" opt
  do
    case $opt in

    h|help     )  echo $_USAGE; return 0   ;;
    * ) echo -e "\033[31;1m[ERROR]\033[0m Option does not exist : $OPTARG\n"
        echo $_USAGE; return 1   ;;

    esac    # --- end of case ---
  done
  shift $(($OPTIND-1))
  aws autoscaling suspend-processes --auto-scaling-group-name $1
  ## TODO:  put function into background and ping once every 5 minutes to restart process
  ##aws autoscaling resume-processes --auto-scaling-group-name $1

}

aws_update_iam_policy() {
  _USAGE="Usage : aws_update_iam_policy  [-h] [--] <policy_arn> <policy_document>
      Updates an IAM policy
      Options:
      -h|help            Display this messagae
  "

  while getopts ":h" opt
  do
    case $opt in
      h|help     )  echo $_USAGE; return 0   ;;
      * ) echo -e "\033[31;1m[ERROR]\033[0m Option does not exist : $OPTARG\n"
        echo $_USAGE; return 1   ;;

    esac
      done
      shift $(($OPTIND-1))
      local ARN=$1
      local DOC=$2
      local VER=$(aws iam list-policy-versions --policy-arn $ARN | jq -r '.Versions[-1:][].VersionId')

      [[ $DEBUG ]] && echo -e "\033[34;1m[DEBUG]\033[0m Deleteing policy version: $VER"

      [[ -z $VER ]] && echo -e "\033[31;1m[ERROR]\033[0m No version to delete" && return 1

      aws iam delete-policy-version --policy-arn $ARN --version-id $VER
      aws iam create-policy-version --policy-arn $ARN --policy-document file://$DOC --set-as-default
    }
