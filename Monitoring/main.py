import json
import urllib3
import time
import boto3

cloudWatch = boto3.client('cloudwatch')

def csvPartsModifiedInLast(fiveMinutesAgoMilisecs):
    return lambda f: (f["pathSuffix"].startswith("part") and (f["modificationTime"] > fiveMinutesAgoMilisecs))

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
    timeNow = time.time()
    fiveMinutesAgo = timeNow - 60*5
    fiveMinutesAgoMilisecs = fiveMinutesAgo * 1000

    http = urllib3.PoolManager()
    res = http.request("GET", "emr-master.twdu6eu.training:50070/webhdfs/v1/tw/stationMart/data?op=LISTSTATUS")

    resParsed = json.loads(res.data)
    fileStatuses = resParsed["FileStatuses"]["FileStatus"]

    print("TimeNow: ", timeNow)
    print("FiveMinutesAgo: ", fiveMinutesAgo)
    print("FiveMinutesAgoMilliseconds: ", fiveMinutesAgoMilisecs)

    print("Files Statuses in /tw/stationMart/data: ", json.dumps(fileStatuses, sort_keys=True, indent=2))

    healthyFiles = list(filter(csvPartsModifiedInLast(fiveMinutesAgoMilisecs), fileStatuses))

    sendMetric(len(healthyFiles))

    print("Healthy Files: ", json.dumps(healthyFiles, sort_keys=True, indent=2), len(healthyFiles))

    return {
        'statusCode': res.status,
        'body': {"healthy": healthyFiles}
    }
