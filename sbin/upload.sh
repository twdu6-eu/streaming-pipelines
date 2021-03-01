#!/usr/bin/env bash

set -e
[ ${CI} ] && set -x

BASTION_PUBLIC_IP=$1
TRAINING_COHORT=$2
GIT_REVISION=$3

configure_ssh() {
  if [ -z "${CI}" ]; then
    echo "SSH should be reconfigured only in CI/CD environment. Skipping."
  else
    echo "
    Host *
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
      ProxyCommand ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@${BASTION_PUBLIC_IP} -W %h:%p 2>/dev/null
      User ec2-user
        StrictHostKeyChecking no
        UserKnownHostsFile /dev/null

    Host bastion.${TRAINING_COHORT}.training
        User ec2-user
        HostName ${BASTION_PUBLIC_IP}
        DynamicForward 6789
    " >>~/.ssh/config
  fi
}

upload() {
  local target_host="$1.${TRAINING_COHORT}.training"
  local src=$2
  local program_name
  program_name=$(basename "$src")
  local target="${target_host}:/tmp/${program_name}"
  local target_versioned="${target_host}:/tmp/${GIT_REVISION}/${program_name}"
  scp "${src}" "${target_versioned}"
  ssh "${target_host}" bash -c "rm -f ${target}; ln -s '${target_versioned}' '${target}'"
}

usage() {
  echo "Deployment script "
  echo "./upload.sh BASTION_PUBLIC_IP TRAINING_COHORT GIT_REVISION"
}

main() {
  [ $# -lt 3 ] && usage && exit 1

  configure_ssh
  upload ingester CitibikeApiProducer/build/libs/tw-citibike-apis-producer0.1.0.jar
  upload emr-master RawDataSaver/target/scala-2.11/tw-raw-data-saver_2.11-0.0.1.jar
  upload emr-master StationConsumer/target/scala-2.11/tw-station-consumer_2.11-0.0.1.jar
  upload emr-master StationTransformerNYC/target/scala-2.11/tw-station-transformer-nyc_2.11-0.0.1.jar
}

# shellcheck disable=SC2068
main $@
