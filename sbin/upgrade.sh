#!/usr/bin/env bash

set -e

BASTION_PUBLIC_IP=$1
TRAINING_COHORT=$2
GIT_REVISION=$3
ENVIRONMENT=${4:-test}

configure_ssh() {
  if [ -z "${CI}" ]; then
    echo "SSH should be reconfigured only in CI/CD environment. Skipping."
  else
    grep "bastion.${TRAINING_COHORT}.training" ~/.ssh/config || echo "
  User ec2-user
  IdentitiesOnly yes
  ForwardAgent yes
  DynamicForward 6789
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null

Host emr-master.${TRAINING_COHORT}.training
  User hadoop

Host *.${TRAINING_COHORT}.training !bastion.${TRAINING_COHORT}.training
  ForwardAgent yes
  ProxyCommand ssh ${BASTION_PUBLIC_IP} -W %h:%p 2>/dev/null
  User ec2-user
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
" >>~/.ssh/config
  fi
}

upgrade() {
  [ $# -lt 3 ] && echo "function usage: upgrade TARGET GIT_REVISION ENVIRONMENT" && exit 2
  local target_host="$1.${TRAINING_COHORT}.training"
  local target_versioned_dir="/tmp/streaming-pipelines-$2"
  local target_dir="/tmp/$3"

  echo -n "Upgrading ${target_dir} to ${target_versioned_dir} ... "
  # shellcheck disable=SC2087
  ssh "${target_host}" <<EOF
rm -f "${target_dir}"
ln -s "${target_versioned_dir}" "${target_dir}"
EOF
  echo "done"
}

usage() {
  echo "Deployment script usage"
  echo "./upload.sh BASTION_PUBLIC_IP TRAINING_COHORT GIT_REVISION [ENVIRONMENT]"
  echo "  NOTE: default for ENVIRONMENT is test"
}

main() {
  configure_ssh
  upgrade ingester "${GIT_REVISION}" "${ENVIRONMENT}"
  upgrade emr-master "${GIT_REVISION}" "${ENVIRONMENT}"
}

[ $# -lt 3 ] && usage && exit 1
main
