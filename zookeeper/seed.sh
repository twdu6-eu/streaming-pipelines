#!/bin/sh

set -e

ENVIRONMENT=${ENVIRONMENT:=$(
  echo "please set the ENVIRONMENT variable to prod or test"
  exit 2
)}
zk_command=${zk_command:=$(
  echo "please set the zk_command variable"
  exit 2
)}
hdfs_server=${hdfs_server:=$(
  echo "please set the hdfs_server variable"
  exit 2
)}
kafka_servers=${kafka_servers:=$(
  echo "please set the kafka_servers variable"
  exit 2
)}

hdfs_namespace="tw"
topic_nyc="${ENVIRONMENT}_station_data_nyc"
topic_sf="${ENVIRONMENT}_station_data_sf"
topic_station_status="${ENVIRONMENT}_station_status"
topic_station_information="${ENVIRONMENT}_station_information"

$zk_command rmr /tw
$zk_command create /tw ''

$zk_command create /tw/stationDataNYC ''
$zk_command create /tw/stationDataNYC/topic ${topic_nyc}
$zk_command create /tw/stationDataNYC/checkpointLocation hdfs://$hdfs_server/${hdfs_namespace}/prod/rawData/stationDataNYC/checkpoints

$zk_command create /tw/stationInformation ''
$zk_command create /tw/stationInformation/kafkaBrokers ${kafka_servers}
$zk_command create /tw/stationInformation/topic ${topic_station_information}
$zk_command create /tw/stationInformation/checkpointLocation hdfs://$hdfs_server/${hdfs_namespace}/prod/rawData/stationInformation/checkpoints
$zk_command create /tw/stationInformation/dataLocation hdfs://$hdfs_server/${hdfs_namespace}/rawData/stationInformation/data

$zk_command create /tw/stationStatus ''
$zk_command create /tw/stationStatus/kafkaBrokers ${kafka_servers}
$zk_command create /tw/stationStatus/topic ${topic_station_status}
$zk_command create /tw/stationStatus/checkpointLocation hdfs://$hdfs_server/${hdfs_namespace}/prod/rawData/stationStatus/checkpoints
$zk_command create /tw/stationStatus/dataLocation hdfs://$hdfs_server/${hdfs_namespace}/rawData/stationStatus/data

$zk_command create /tw/stationDataSF ''
$zk_command create /tw/stationDataSF/kafkaBrokers ${kafka_servers}
$zk_command create /tw/stationDataSF/topic ${topic_sf}
$zk_command create /tw/stationDataSF/checkpointLocation hdfs://$hdfs_server/${hdfs_namespace}/prod/rawData/stationDataSF/checkpoints
$zk_command create /tw/stationDataSF/dataLocation hdfs://$hdfs_server/${hdfs_namespace}/rawData/stationDataSF/data

$zk_command create /tw/output ''
$zk_command create /tw/output/checkpointLocation hdfs://$hdfs_server/${hdfs_namespace}/prod/stationMart/checkpoints
$zk_command create /tw/output/dataLocation hdfs://$hdfs_server/${hdfs_namespace}/stationMart/data
