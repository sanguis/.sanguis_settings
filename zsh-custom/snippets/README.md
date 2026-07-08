<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [zsh-custom snippets](#zsh-custom-snippets)
- [aws.zsh](#awszsh)
  - [Aliases](#aliases)
  - [Functions](#functions)
- [azure.zsh](#azurezsh)
  - [Aliases](#aliases-1)
  - [Functions](#functions-1)
- [bitbucket.zsh](#bitbucketzsh)
  - [Aliases](#aliases-2)
  - [Functions](#functions-2)
- [completions.zsh](#completionszsh)
  - [Aliases](#aliases-3)
  - [Functions](#functions-3)
- [docker_based_applicatins.zsh](#docker_based_applicatinszsh)
  - [Aliases](#aliases-4)
  - [Functions](#functions-4)
- [docker.zsh](#dockerzsh)
  - [Aliases](#aliases-5)
  - [Functions](#functions-5)
- [gh.zsh](#ghzsh)
  - [Aliases](#aliases-6)
  - [Functions](#functions-6)
- [git.zsh](#gitzsh)
  - [Aliases](#aliases-7)
  - [Functions](#functions-7)
- [helm.zsh](#helmzsh)
  - [Aliases](#aliases-8)
  - [Functions](#functions-8)
- [kubernetes.zsh](#kuberneteszsh)
  - [Aliases](#aliases-9)
  - [Functions](#functions-9)
- [kubernets.zsh](#kubernetszsh)
  - [Aliases](#aliases-10)
  - [Functions](#functions-10)
- [kustomize.zsh](#kustomizezsh)
  - [Aliases](#aliases-11)
  - [Functions](#functions-11)
- [minikube.zsh](#minikubezsh)
  - [Aliases](#aliases-12)
  - [Functions](#functions-12)
- [onepass.zsh](#onepasszsh)
  - [Aliases](#aliases-13)
  - [Functions](#functions-13)
- [terraform.zsh](#terraformzsh)
  - [Aliases](#aliases-14)
  - [Functions](#functions-14)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# zsh-custom snippets

Custom zsh aliases, functions, and completions grouped by tool. Each file is sourced into the shell to add helpers for a particular CLI or workflow.

---

# aws.zsh

AWS CLI helpers: profile/region switching, MFA and role assumption, SSM session helpers, ECR login, EC2/VPC inspection, IAM and Identity Center management. Sets `AWS_PAGER=""` and wires up the `aws_completer`.

## Aliases
- `aws_envs` — show all `AWS*` environment variables
- `aws-id` — `aws sts get-caller-identity`
- `aws_region_eu1` — set `AWS_DEFAULT_REGION=eu-west-1`
- `aws_region_eu_w2` — set `AWS_DEFAULT_REGION=eu-west-2`
- `aws_region_us-e1` — set `AWS_DEFAULT_REGION=us-east-1`
- `aws_region_us-e2` — set `AWS_DEFAULT_REGION=us-east-2`
- `aws_region_us-w1` — set `AWS_DEFAULT_REGION=us-west-1`
- `aws-account-number` — print the current account number
- `ssm` — `aws ssm start-session --target`
- `asl` — `aws sso login`
- `ec2-ls` — describe EC2 instances as a table (Name, Id, State, Type, AZ)

## Functions
- `aws_profile <profile>` — switch `AWS_PROFILE`/`AWS_DEFAULT_PROFILE`; `-` restores previous, `-u` unsets (has completion)
- `aws_mfa_session_token <MFACODE>` — export an MFA session token (`-m` sets the device ARN)
- `ecr_login [-r region] [account]` — docker login to ECR for the account/region
- `vpc_nuke <VPC-ID>` — list all resources attached to a VPC (for teardown)
- `certbot_to_aws [-e email] [-d domain] <primary_domain>` — issue a Let's Encrypt cert via DNS-01 and import into ACM
- `ssm_by_name [-c] <NAME>` — get instance ID by Name tag, `-c` to connect via SSM (has completion)
- `aws_instance_id_by_project_env [-c] <PROJECT> <ENV>` — get instance ID by Project/Environment tags, `-c` to connect
- `assume_role [-s session] <role-arn>` — assume a role and export the credentials
- `ssm-connect <name>` — start an SSM session to a running instance by Name tag (has completion)
- `ssm-ls [region]` — `aws ssm get-inventory`
- `aws-ls [-r region] [-p profile]` — describe EC2 instances as a table (has completion)
- `aws_env_unset` — unset AWS credential/region/profile env vars
- `aws_env_reset` — unset then re-export credentials from `aws configure export-credentials`
- `asg_suspend <ASG_NAME>` — suspend an Auto Scaling group's processes (has completion)
- `asg_resume <ASG_NAME>` — resume an Auto Scaling group's processes (completes suspended groups)
- `aws_update_iam_policy <policy_arn> <policy_document>` — replace the latest policy version with a new default
- `id_center_add_user_to_group <identity_store_id> <user> <group>` — add an Identity Center user to a group
- `aws_account_switch <profile> <kube_context>` — switch AWS profile and `kubectx` together

---

# azure.zsh

Azure CLI helpers.

## Aliases
None.

## Functions
- `aks_session <cluster_name> <subscription_id>` — set the Azure subscription and switch kube context to the cluster

---

# bitbucket.zsh

Bitbucket helpers.

## Aliases
None.

## Functions
- `bb_open [-d] [-b browser]` — open the current git repo's remote URL in the browser (converts SSH remote to HTTPS)

---

# completions.zsh

Completion stub.

## Aliases
None.

## Functions
None. (Contains only a `#compdef aws-profle` directive.)

---

# docker_based_applicatins.zsh

Wrappers that run tools as one-off Docker containers, mounting the current directory.

## Aliases
None.

## Functions
- `terraform-compliance` — run `eerkunt/terraform-compliance` against the current dir
- `shdoc` — run `sanguis/shdoc`
- `terraspace` — run `ghcr.io/boltops-tools/terraspace:alpine`

---

# docker.zsh

Docker helpers.

## Aliases
- `docker_kill_all` — kill all running containers

## Functions
- `docker_run [-d] [-s] <image> [command]` — run a container mounting the current dir; `-d` mounts the Docker socket, `-s` mounts `~/.ssh`

---

# gh.zsh

GitHub helpers using the API and `gh` CLI: enterprise/org user listing, PR creation, and workflow-run cancellation. Requires `GITHUB_API_URL`, `GH_ENTERPRISE`, `GH_TOKEN` for the org/enterprise functions.

## Aliases
None.

## Functions
- `_gh_reqs` — (internal) verify required GitHub env vars are set
- `_gh_pages_curl` — (internal) paginate through curl results
- `gh_org_users [-n] [-c] <ORG>` — list members of an org (`-n` no header, `-c` count)
- `gh_ent_users [ORG]` — list users across all orgs in the enterprise (or one org)
- `gh_pr_create [-d] [--base branch]` — create a PR; title defaults from branch name, body auto-links Jira ticket and lists commits since fork from main
- `gha_cancel_workflow <OWNER> <REPO> <RUN_ID>` — force-cancel (or delete) a GitHub Actions run

---

# git.zsh

Git aliases and multi-repo helpers.

## Aliases
- `main` — checkout `main` and pull
- `stash_pull` — stash, pull, then pop
- `groot` — cd to the repo root

## Functions
- `fetch_and_checkout <branch>` — fetch all remotes and checkout a branch
- `gup_recursive <dir> [depth]` — recursively pull every git repo under a directory (default depth 3)
- `git_reclone <repo>` — remove and re-clone a repo from its origin URL

---

# helm.zsh

Helm chart helpers for templating and manipulating rendered manifests.

## Aliases
None.

## Functions
- `helm_template <file>` — render the chart with `helm template` and open the output in vim
- `helm_replace_in_templates <search> <replacement>` — `gsed` regex replace across all YAML in `templates/`
- `helm_inflate <input_yaml> [output_dir]` — split a rendered multi-doc YAML back into per-`# Source:` files, recreating the chart layout

---

# kubernetes.zsh

kubectl aliases and generic object helpers, plus krew PATH setup and a base64 decoder. (Note: a similarly named `kubernets.zsh` also exists.)

## Aliases
- `kgpo` — get pods (wide)
- `kgp` — get pods
- `kdep` — describe pod
- `keti` — exec into a pod interactively
- `kdlp` — delete pod
- `rollout` — rollout restart deployment
- `rollStatus` — rollout status deployment
- `kdes` — describe
- `kgs` — get secrets
- `kvs` — get secret as YAML
- `kgsb` — get secret's `.data` as jsonpath
- `kg1p` — list OnePassword items with status columns

## Functions
- `64d <string>` — base64 decode a string
- `k_all <action> <object_type>` — run an action on all objects of a type (has completion)
- `ko <action> <object_type> <object_name>` — run a command and persist type/name for follow-ups (has completion)
- `_ko_eval` — (internal) verify persisted object type/name are set
- `k_ed` — edit the persisted object
- `k_des` — describe the persisted object
- `k_dl` — delete the persisted object

---

# kubernets.zsh

Kustomize helper (filename is a typo of "kubernetes").

## Aliases
None.

## Functions
- `kust_init_recursive [-d]` — recursively create a `kustomization.yaml` in every directory listing its files/subdirs as resources

---

# kustomize.zsh

Kustomize edit helpers.

## Aliases
None.

## Functions
- `_create_kust` — (internal) create `kustomize.yaml` if missing
- `kust_add_base <files...>` — add bases to the kustomization and git-add it
- (`kust_add_patch_dir` is present but commented out)

---

# minikube.zsh

Use minikube's Docker daemon.

## Aliases
None.

## Functions
- `minikube_as_docker` — point the Docker env at a running minikube (`minikube docker-env`)
- `minikube_unset_as_docker` — unset the Docker env vars set above

---

# onepass.zsh

1Password CLI helper.

## Aliases
None.

## Functions
- `k8s_to_onepass <src_secret> <op_secret> <vault>` — copy a Kubernetes secret's decoded keys into a 1Password item

---

# terraform.zsh

Terraform/Terragrunt helpers: modules, cost, plans, logging, and a smart wrapper.

## Aliases
- `tf-state` — pull terraform state through `less`
- `tf-log-tail` — tail the terraform debug log

## Functions
- `tf_new_module <name>` — add the terraform-module-scaffolding repo as a squashed subtree
- `tf_cost` — generate a plan and run `infracost` breakdown/diff
- `tf_plan_json` — pull state to a JSON file and open in vi
- `tf-log-debug [level]` — enable terraform debug logging (default `TRACE`) to `/tmp/tf_debug.log`
- `t <args>` — run `terragrunt` or `terraform` depending on whether `terragrunt.hcl` is present
