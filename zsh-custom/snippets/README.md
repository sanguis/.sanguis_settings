<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [zsh-custom snippets](#zsh-custom-snippets)
- [aws.zsh](#awszsh)
  - [Aliases](#aliases)
  - [Functions](#functions)
- [azure.zsh](#azurezsh)
  - [Functions](#functions-1)
- [bitbucket.zsh](#bitbucketzsh)
  - [Functions](#functions-2)
- [docker.zsh](#dockerzsh)
  - [Aliases](#aliases-1)
  - [Functions](#functions-3)
- [docker_based_applicatins.zsh](#docker_based_applicatinszsh)
  - [Functions](#functions-4)
- [gh.zsh](#ghzsh)
  - [Aliases](#aliases-2)
  - [Functions](#functions-5)
- [git.zsh](#gitzsh)
  - [Aliases](#aliases-3)
  - [Functions](#functions-6)
- [helm.zsh](#helmzsh)
  - [Functions](#functions-7)
- [kubernetes.zsh](#kuberneteszsh)
  - [Aliases](#aliases-4)
  - [Functions](#functions-8)
- [kustomize.zsh](#kustomizezsh)
  - [Functions](#functions-9)
- [minikube.zsh](#minikubezsh)
  - [Functions](#functions-10)
- [onepass.zsh](#onepasszsh)
  - [Functions](#functions-11)
- [terraform.zsh](#terraformzsh)
  - [Aliases](#aliases-5)
  - [Functions](#functions-12)

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
- `aws_profile [-h] [--] <profile>` — Switches the AWS profile to input value.
  ```
  If Already set use '-' to switch to previous profile.

  Options:
  -h|help       Display this message
  -d|debug      Debug output
  -u|unset      Unsets the AWS_PROFILE and AWS_DEFAULT_PROFILE
  ```
- `_aws_profile`
- `aws_mfa_session_token [-hmd:] [--] MFACODE` — Adds ENVs for MFA validation.
  ```
  Options:
  -h|help       Display this message
  -d|debug      Debug output
  -m|mfa        mfa device arn
  ```
- `ecr_login [-hr:] [--] {2:inputs}` — logs into aws ecr based on the account id and default region.
  ```
  Defaults to account number of current aws cli profile

  Options:
  -h|help       Display this message
  -r|region     AWS region
  ```
- `vpc_nuke <VPC-ID>`
- `certbot_to_aws [-h:e:d:] [--] primary_domain` — Creates cert and addts it to aws cert manager
  ```
  Options:
  -h|help       Display this message
  -e|email      Emaill address for cert
  -d|domain     Additional domains Can be multiple, put in quotes for wildcards

  example:

  certbot_to_aws -d "*.foo.bar" foo.com
  ```
- `ssm_by_name [-hc] <NAME> <ENVIRONMENT>`
  ```
  Options:
  -c|connect   Connect with SSM
  ```
- `_ssm_by_name`
- `aws_instance_id_by_project_env [-hc] <NAME> <ENVIRONMENT>`
  ```
  Options:
  -c|connect   Connect with SSM
  ```
- `assume_role [-h] [--] <role arn>` — Assumes a role setting session data as envs
  ```
  Options:
  -h|help            Display this messagae
  -s|session-name    (optional) Session Name. Defaults to, '$USER'
  ```
- `ssm-connect <name>` — start an SSM session to a running instance by Name tag (has completion)
- `_aws_ssm`
- `ssm-ls [region]` — `aws ssm get-inventory`
- `aws-ls [-hrp] [--region --profile] <role arn>` — Assumes a role setting session data as envs
  ```
  Options:
  -h|help            Display this messagae
  -p|profile         Set the AWS profile
  -r|region          Set the AWS region to ls
  ```
- `aws_env_unset` — unset AWS credential/region/profile env vars
- `aws_env_reset` — unset then re-export credentials from `aws configure export-credentials`
- `asg_suspend [-h] [--] <ASG_NAME>` — Suspends autoscaling group
  ```
  Options:
  -h|help            Display this messagae
  ```
- `asg_resume [-h] [--] <ASG_NAME>` — Suspends autoscaling group
  ```
  Options:
  -h|help            Display this messagae
  ```
- `_asg_list`
- `_asg_list_sus`
- `aws_update_iam_policy [-h] [--] <policy_arn> <policy_document>` — Updates an IAM policy
  ```
  Options:
  -h|help            Display this messagae
  ```
- `id_center_add_user_to_group [-h] [--] <identitty_store_id> <user_name> <group_name>` — Adds a user to a group
  ```
  Options:
  -h|help            Display this messagae

  Idenetity Store ID can be found on the settings poage  on the lower part of the console. and looks like d-1234567890
  ```
- `aws_account_switch <profile> <kube_context>` — switch AWS profile and `kubectx` together

---

# azure.zsh

Azure CLI helpers.

## Functions
- `aks_session <cluster_name> <subscription_id>` — set the Azure subscription and switch kube context to the cluster

---

# bitbucket.zsh

Bitbucket helpers.

## Functions
- `bb_open [-hdb:] [--] MFACODE` — Adds ENVs for MFA validation.
  ```
  Options:
  -h|help       Display this message
  -d|debug      Debug output
  -b|browser    Browser to open
  ```

---

# docker.zsh

Docker helpers.

## Aliases
- `docker_kill_all` — kill all running containers

## Functions
- `docker_run [options] [--] image command` — Runs dokcker condocker_runh volume mounts for the current dir and optiopnally mounts ssh or docker connections
  ```
  Options:dock
  -h|help       Display this message
  -d|docker     Mounts docker unix socker from parent machine
  -s/ssh        Mounts $HOME/.ssh to /root/.ssh
  ```

---

# docker_based_applicatins.zsh

Wrappers that run tools as one-off Docker containers, mounting the current directory.

## Functions
- `terraform-compliance` — run `eerkunt/terraform-compliance` against the current dir
- `shdoc` — run `sanguis/shdoc`
- `terraspace` — run `ghcr.io/boltops-tools/terraspace:alpine`

---

# gh.zsh

GitHub helpers using the API and `gh` CLI: enterprise/org user listing, PR creation, and workflow-run cancellation. Requires `GITHUB_API_URL`, `GH_ENTERPRISE`, `GH_TOKEN` for the org/enterprise functions.

## Aliases
- `gh_token` — `$(gh auth token)`

## Functions
- `_gh_reqs` — (internal) verify required GitHub env vars are set
- `_gh_pages_curl` — (internal) paginate through curl results
- `gh_org_users ORG` — Github token must have read:org scope
- `gh_ent_users ORG` — Gets list all users in a github enterprises organization
  ```
  Github token must have read:org and read:enterprise scope
  ```
- `_gh_pr_preflight` — Verify we're inside a git repo, gh is installed, and we're not on BASE.
- `_gh_pr_jira_from_branch` — Print the Jira ID at the start of a branch name (PROJ-123-foo -> PROJ-123).
- `_gh_pr_commits` — Print the hashes of non-merge commits since fork from BASE, oldest first.
- `_gh_pr_find` — Print JSON {number,url,body} for the current branch's open PR, or nothing
- `_gh_pr_commit_entry` — Print one "- <full commit message>" entry for HASH (trailing newlines trimmed).
- `_gh_pr_changes` — Print "- <message>" entries for the local user's non-merge commits since fork
- `_gh_pr_body` — Build a PR body from an (optional) Jira ID and a block of change entries.
- `_gh_pr_append_changes` — Read a PR body on stdin and print it with NEW_ENTRIES appended to the end of
- `flush`
- `gh_pr_create [-d|--debug] [-h|--help] [-b|--base BASE] [-a|--all-authors] [-- <extra gh pr create args>]` — Creates a PR via 'gh pr create'. Refuses if the branch already has an open PR.
  ```
  Title: prompted; default is a humanized version of the current branch name.
  Body:  Jira link (if branch starts with PROJ-123-) + your commit messages since fork from BASE (default: main).
         Only commits authored by the local git user are listed; -a includes commits pulled in from others.
  Find additional args with 'gh pr create --help' or 'gh pr create -- <extra args>'
  ```
- `gh_pr_update [-d|--debug] [-h|--help] [-b|--base BASE] [-a|--all-authors] [-n|--no-commits] [-m|--message MSG]... [-- <extra gh pr edit args>]` — Appends new entries to the '## Changes:' section of the current branch's open PR. By default every non-merge commit authored by you since fork from BASE (default: main) that is not already listed in the PR body is appended. Commits pulled in from other authors (e.g. via merge/rebase of BASE) are skipped.
  ```
  -m MSG            append MSG as an extra entry (repeatable)
  -n|--no-commits   don't scan commits; only append -m messages
  -a|--all-authors  include commits from all authors, not just you
  Find additional args with 'gh pr edit --help'
  ```
- `gha_cancel_workflow [OWNER] [REPO] [RUN_ID]`
  ```
  Input values:
    OWNER         - repo owner or org
    REPO          - repo name
    WORKFLOW_ID   - optional workflow file name or ID to narrow search
  ```

---

# git.zsh

Git aliases and multi-repo helpers.

## Aliases
- `main` — checkout `main` and pull
- `stash_pull` — stash, pull, then pop
- `groot` — cd to the repo root

## Functions
- `fetch_and_checkout <branch>` — fetch all remotes and checkout a branch
- `gup_recursive DIR DEPTH` — DEPTH defaults too 3 is optional
- `git_reclone REPO_PATH` — Deletes and reclones repo.

---

# helm.zsh

Helm chart helpers for templating and manipulating rendered manifests.

## Functions
- `helm_template [-he] [--] {2:inputs}` — what it does
  ```
  Options:
  -h|help       Display this message
  ```
- `helm_replace_in_templates <search_pattern> <replacement_pattern>` — Replace all occurrences of <search_pattern> with <replacement_pattern> in all YAML files within the 'templates' directory.
  ```
   Note: Search and replacement patterns should be provided as regular expressions, for the sed command.
   sed regex doc: https://www.gnu.org/software/sed/manual/sed.html#Regular-Expressions

   Common patterns that need escaping:
     .  (dot)  - escape as \.
     /  (slash)- escape as \/
     *  (asterisk) - escape as \*
     +  (plus) - escape as \+
     ?  (question mark) - escape as \?
     ( ) (parentheses) - escape as \( and \)
     [ ] (brackets) - escape as \[ and \]
     { } (curly braces) - escape as \{ and \}

  Options:
  -h|--help       Display this message
  -d|--debug    Enable debug mode
  ```
- `helm_inflate [<input_yaml>] [<output_dir>]` — Inflate a Helm-rendered multi-document YAML file by splitting each document into a separate file at the path declared in its '# Source: next/templates/<path>' marker, recreating the chart layout.
  ```
   Repeated sources (same path) are concatenated into the same file as
   multiple YAML documents separated by '---'.

   <input_yaml>  File to read (default: ./next.full.yaml)
   <output_dir>  Directory to write into (default: ./inflated)

  Options:
  -h|--help     Display this message
  ```

---

# kubernetes.zsh

kubectl aliases and generic object helpers, krew PATH setup, a base64 decoder, and a recursive kustomization generator.

## Aliases
- `kgpo` — get pods (wide)
- `kgp` — get pods
- `kgpy` — `kubectl get pods -o yaml |less`
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
- `_k_all`
- `ko <action> <object_type> <object_name>`
  ```
  Example: ko get pod my-pod-1234
  Follow Up commands:
   k_ed  to edit the object
   k_des to describe the object
   k_dl  to delete the object
  ```
- `_ko` — auto complete for ko to complete object type and object name
- `_ko_eval` — (internal) verify persisted object type/name are set
- `k_ed` — edit the persisted object
- `k_des` — describe the persisted object
- `k_dl` — delete the persisted object
- `kust_init_recursive [options]` — Recursively creates a kustomization.yaml in the current directory and every subdirectory. Each kustomization.yaml lists every file and subdirectory in its directory (excluding the kustomization.yaml itself) as a resource.
  ```
  Options:
   -h|--HELP   Display this message
   -d|--DEBUG  Enable debug output
  ```

---

# kustomize.zsh

Kustomize edit helpers.

## Functions
- `_create_kust` — (internal) create `kustomize.yaml` if missing
- `kust_add_base <files...>` — add bases to the kustomization and git-add it

---

# minikube.zsh

Use minikube's Docker daemon.

## Functions
- `minikube_as_docker` — point the Docker env at a running minikube (`minikube docker-env`)
- `minikube_unset_as_docker` — unset the Docker env vars set above

---

# onepass.zsh

1Password CLI helper.

## Functions
- `k8s_to_onepass <src_secret> <op_secret> <vault>` — copy a Kubernetes secret's decoded keys into a 1Password item

---

# terraform.zsh

Terraform/Terragrunt helpers: modules, cost, plans, logging, and a smart wrapper.

## Aliases
- `tf-state` — pull terraform state through `less`
- `tf-log-tail` — tail the terraform debug log

## Functions
- `tf_new_module module_name`
- `tf_cost` — generate a plan and run `infracost` breakdown/diff
- `tf_plan_json` — pull state to a JSON file and open in vi
- `tf-log-debug [level]` — enable terraform debug logging (default `TRACE`) to `/tmp/tf_debug.log`
- `t <args>` — run `terragrunt` or `terraform` depending on whether `terragrunt.hcl` is present
