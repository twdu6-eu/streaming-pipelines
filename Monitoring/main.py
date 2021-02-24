import json
import urllib3
import time
import boto3


cloudWatch = boto3.client('cloudwatch')

timeNow = time.time()
fiveMinutesAgo = timeNow - 60*5
fiveMinutesAgoMilisecs = fiveMinutesAgo * 1000


def csvPartsModifiedInLastFiveMinutes(f):
    return (f["pathSuffix"].startswith("part") and (f["modificationTime"] > fiveMinutesAgoMilisecs))

def sendMetric(healthyFiles):
    response = cloudWatch.put_metric_data(
        MetricData = [
            {
                'MetricName': 'Healthy',
                'Value': healthyFiles
            },
        ],
        Namespace='HdfsFileWatcher'
    )
    print(json.dumps(response))

def lambda_handler(event, context):
    http = urllib3.PoolManager()
    res = http.request("GET", "emr-master.twdu6eu.training:50070/webhdfs/v1/tw/stationMart/data?op=LISTSTATUS")

    resParsed = json.loads(res.data)
    fileStatuses = resParsed["FileStatuses"]["FileStatus"]

    print("Files Statuses in /tw/stationMart/data: ", json.dumps(fileStatuses, sort_keys=True, indent=2))

    healthyFiles = len(list(filter(csvPartsModifiedInLastFiveMinutes, fileStatuses)))


    sendMetric(healthyFiles)

    print("Healthy: ", healthyFiles)

    return {
        'statusCode': res.status,
        'body': {"healthy": healthyFiles}
    }
