#compdef aws-profle

_aws_profile() {
  compadd "$(aws configure list-profiles)"
}
compdef _aws-profile aws_profile
