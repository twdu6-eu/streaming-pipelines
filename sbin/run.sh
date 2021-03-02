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

configure_zookeeper() {
  scp ./zookeeper/seed.sh kafka.${TRAINING_COHORT}.training:/tmp/zookeeper-seed.sh
  ssh kafka.${TRAINING_COHORT}.training <<EOF
set -e
export hdfs_server="emr-master.${TRAINING_COHORT}.training:8020"
export kafka_server="${KAFKA_BROKERS}"
export zk_command="zookeeper-shell localhost:2181"
sh /tmp/zookeeper-seed.sh
EOF
}

configure_hdfs_paths() {
  scp ./hdfs/seed.sh emr-master.${TRAINING_COHORT}.training:/tmp/hdfs-seed.sh
  ssh emr-master.${TRAINING_COHORT}.training <<EOF
set -e
export hdfs_server="emr-master.${TRAINING_COHORT}.training:8020"
export hadoop_path="hadoop"
sh /tmp/hdfs-seed.sh
EOF
}

kill_ingester_process() {
  query=$1
  (pgrep -lf "${query}" | awk '{ print $1 }' | xargs -L1 kill -9) || echo "No process is running"
}

run_ingester_process() {
  jar=$1
  profile=$2
  producer_topic=$3
  nohup java -jar ${jar} --spring.profiles.active=${profile} --producer.topic=${producer_topic} --kafka.brokers=${KAFKA_BROKERS} 1>/tmp/${profile}.log 2>/tmp/${profile}.error.log &
}

run_ingesters() {
  ssh ingester.${TRAINING_COHORT}.training <<EOF
set -e

KAFKA_BROKERS="${KAFKA_BROKERS}"

$(typeset -f kill_ingester_process)
$(typeset -f run_ingester_process)

station_information="station-information"
station_status="station-status"
station_san_francisco="station-san-francisco"

echo "====Kill running producers===="

kill_ingester_process \${station_information}
kill_ingester_process \${station_status}
kill_ingester_process \${station_san_francisco}

echo "====Runing Producers Killed===="

echo "====Deploy Producers===="

run_ingester_process /tmp/prod/tw-citibike-apis-producer0.1.0.jar \${station_information} station_information
run_ingester_process /tmp/prod/tw-citibike-apis-producer0.1.0.jar \${station_san_francisco} station_data_sf
run_ingester_process /tmp/prod/tw-citibike-apis-producer0.1.0.jar \${station_status} station_status

echo "====Producers Deployed===="
EOF
}

kill_consumer_application() {
  applicationName=$1

  echo -n "killing application ${applicationName} ... "

  applicationIds=$(yarn application -list | awk -v name=$applicationName 'match($2,name){print $1}')

  for applicationId in $applicationIds; do
    echo "Kill ${applicationName} with applicationId ${applicationId}"
    yarn application -kill $applicationId
  done

  echo "done"
}

run_consumer_application() {
  jar=$1
  class=$2
  name=$3
  zookeeperPrefix=$4
  logPrefix=$5
  echo -n "Running spark job ${name} ... "
  nohup spark-submit --master yarn --deploy-mode cluster --queue streaming --class ${class} --name ${name} --packages org.apache.spark:spark-sql-kafka-0-10_2.11:2.3.0 --driver-memory 500M --conf spark.streaming.stopGracefullyOnShutdown=true --conf spark.executor.memory=2g --conf spark.cores.max=1 ${jar} ${ZOOKEEPER_CONFIG} ${zookeeperPrefix} 1>/tmp/${logPrefix}.log 2>/tmp/${logPrefix}.error.log &
  echo "done"
}

run_consumers() {
  ssh emr-master.${TRAINING_COHORT}.training <<EOF
set -e

KAFKA_BROKERS="${KAFKA_BROKERS}"
ZOOKEEPER_CONFIG="${ZOOKEEPER_CONFIG}"

$(typeset -f kill_consumer_application)
$(typeset -f run_consumer_application)

echo "====Kill Old Raw Data Saver===="

kill_consumer_application "StationStatusSaverApp"
kill_consumer_application "StationInformationSaverApp"
kill_consumer_application "StationDataSFSaverApp"
kill_consumer_application "StationApp"
kill_consumer_application "StationTransformerNYC"

echo "====Old Raw Data Saver Killed===="

echo "====Deploy Raw Data Saver===="

#                        jar                                        class                           name                       zookeeperPrefix          logPrefix
run_consumer_application /tmp/prod/tw-raw-data-saver_2.11-0.0.1.jar com.tw.apps.StationLocationApp  StationStatusSaverApp      "/tw/stationStatus"      "raw-station-status-data-saver"
run_consumer_application /tmp/prod/tw-raw-data-saver_2.11-0.0.1.jar com.tw.apps.StationLocationApp  StationInformationSaverApp "/tw/stationInformation" "raw-station-information-data-saver"
run_consumer_application /tmp/prod/tw-raw-data-saver_2.11-0.0.1.jar com.tw.apps.StationLocationApp  StationDataSFSaverApp      "/tw/stationDataSF"      "raw-station-data-sf-saver"

run_consumer_application /tmp/prod/tw-station-consumer_2.11-0.0.1.jar        com.tw.apps.StationApp StationApp                 "/tw/unused"             "station-consumer"
run_consumer_application /tmp/prod/tw-station-transformer-nyc_2.11-0.0.1.jar com.tw.apps.StationApp StationTransformerNYC      "/tw/unused"             "station-transformer-nyc"

echo "====Raw Data Saver Deployed===="
EOF
}

main() {
  configure_ssh
  configure_zookeeper
  configure_hdfs_paths
  run_ingesters
  run_consumers
}

[ $# -lt 2 ] && usage && exit 1
main
