#!/usr/bin/env bash

set -ex

BASTION_PUBLIC_IP=$1
TRAINING_COHORT=$2
ZOOKEEPER_CONFIG="kafka1.${TRAINING_COHORT}.training:2181,kafka2.${TRAINING_COHORT}.training:2181,kafka3.${TRAINING_COHORT}.training:2181"
KAFKA_BROKERS="kafka1.${TRAINING_COHORT}.training:9092,kafka2.${TRAINING_COHORT}.training:9092,kafka3.${TRAINING_COHORT}.training:9092"

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

kill_process() {
  query=$1
  (pgrep -lf "${query}" | awk '{ print $1 }' | xargs -L1 kill -9) || echo "No process is running"
}

run_process() {
  jar=$1
  profile=$2
  producer_topic=$3
  nohup java -jar ${jar} --spring.profiles.active=${profile} --producer.topic=${producer_topic} --kafka.brokers=${KAFKA_BROKERS} 1>/tmp/${profile}.log 2>/tmp/${profile}.error.log &
}

run() {
  ssh ingester.${TRAINING_COHORT}.training <<EOF
set -e

KAFKA_BROKERS="${KAFKA_BROKERS}"

$(typeset -f kill_process)
$(typeset -f run_process)

station_information="station-information"
station_status="station-status"
station_san_francisco="station-san-francisco"

echo "====Kill running producers===="

kill_process \${station_information}
kill_process \${station_status}
kill_process \${station_san_francisco}

echo "====Runing Producers Killed===="

echo "====Deploy Producers===="

run_process /tmp/tw-citibike-apis-producer0.1.0.jar \${station_information} station_information
run_process /tmp/tw-citibike-apis-producer0.1.0.jar \${station_san_francisco} station_data_sf
run_process /tmp/tw-citibike-apis-producer0.1.0.jar \${station_status} station_status

echo "====Producers Deployed===="
EOF
}

main() {
  configure_ssh
  run
}

[ $# -lt 2 ] && usage && exit 1
main