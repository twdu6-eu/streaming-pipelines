#!/bin/sh

set -ex

zk_command=${zk_command:=$(echo "PLEASE SET zk_command VARIABLE"; exit 2)}
hdfs_server=${hdfs_server:=$(echo "PLEASE SET hdfs_server VARIABLE"; exit 2)}
kafka_server=${kafka_server:=$(echo "PLEASE SET kafka_server VARIABLE"; exit 2)}

topic_prefix=$([ $environment ] && echo "${environment}_" || echo "")
hdfs_namespace=${environment:-"tw"}
topic_nyc="${topic_prefix}station_data_nyc"
topic_sf="${topic_prefix}station_data_sf"
topic_station_status="${topic_prefix}station_status"
topic_station_information="${topic_prefix}station_information"

exit 1

$zk_command rmr /tw
$zk_command create /tw ''

$zk_command create /tw/stationDataNYC ''
$zk_command create /tw/stationDataNYC/topic $topic_nyc
$zk_command create /tw/stationDataNYC/checkpointLocation hdfs://$hdfs_server/${hdfs_namespace}/rawData/stationDataNYC/checkpoints

$zk_command create /tw/stationInformation ''
$zk_command create /tw/stationInformation/kafkaBrokers ${kafka_server}
$zk_command create /tw/stationInformation/topic ${topic_station_information}
$zk_command create /tw/stationInformation/checkpointLocation hdfs://$hdfs_server/${hdfs_namespace}/rawData/stationInformation/checkpoints
$zk_command create /tw/stationInformation/dataLocation hdfs://$hdfs_server/${hdfs_namespace}/rawData/stationInformation/data

$zk_command create /tw/stationStatus ''
$zk_command create /tw/stationStatus/kafkaBrokers ${kafka_server}
$zk_command create /tw/stationStatus/topic ${topic_station_status}
$zk_command create /tw/stationStatus/checkpointLocation hdfs://$hdfs_server/${hdfs_namespace}/rawData/stationStatus/checkpoints
$zk_command create /tw/stationStatus/dataLocation hdfs://$hdfs_server/${hdfs_namespace}/rawData/stationStatus/data

$zk_command create /tw/stationDataSF ''
$zk_command create /tw/stationDataSF/kafkaBrokers ${kafka_server}
$zk_command create /tw/stationDataSF/topic ${topic_sf}
$zk_command create /tw/stationDataSF/checkpointLocation hdfs://$hdfs_server/${hdfs_namespace}/rawData/stationDataSF/checkpoints
$zk_command create /tw/stationDataSF/dataLocation hdfs://$hdfs_server/${hdfs_namespace}/rawData/stationDataSF/data

$zk_command create /tw/output ''
$zk_command create /tw/output/checkpointLocation hdfs://$hdfs_server/${hdfs_namespace}/stationMart/checkpoints
$zk_command create /tw/output/dataLocation hdfs://$hdfs_server/${hdfs_namespace}/stationMart/data
