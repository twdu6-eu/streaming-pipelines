#!/usr/bin/env bash

set -e

BASTION_PUBLIC_IP=$1
TRAINING_COHORT=$2
GIT_REVISION=$3

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

upload() {
  local target_host="$1.${TRAINING_COHORT}.training"

  local src=$2
  local program_name
  program_name=$(basename "$src")

  local target_versioned_dir="/tmp/streaming-pipelines-${GIT_REVISION}/"
  local target_versioned="${target_versioned_dir}${program_name}"

  ssh "${target_host}" mkdir -p "${target_versioned_dir}"
  echo -n "copying ${src} to ${target_host}:${target_versioned} ... "
  scp "${src}" "${target_host}:${target_versioned}"
  echo "done"
}

usage() {
  echo "Deployment script usage"
  echo "./upload.sh BASTION_PUBLIC_IP TRAINING_COHORT GIT_REVISION"
}

main() {
  configure_ssh
  upload ingester CitibikeApiProducer/build/libs/tw-citibike-apis-producer0.1.0.jar
  upload emr-master RawDataSaver/target/scala-2.11/tw-raw-data-saver_2.11-0.0.1.jar
  upload emr-master StationConsumer/target/scala-2.11/tw-station-consumer_2.11-0.0.1.jar
  upload emr-master StationTransformerNYC/target/scala-2.11/tw-station-transformer-nyc_2.11-0.0.1.jar
}

[ $# -lt 3 ] && usage && exit 1
main
