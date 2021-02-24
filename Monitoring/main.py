import json
import urllib3
import time

from pprint import pprint


# s3 = boto3.client('s3')

timeNow = time.time()
fiveMinutesAgo = timeNow - 60*5
fiveMinutesAgoMilisecs = fiveMinutesAgo * 1000

def csvPartsModifiedInLastFiveMinutes(f):
    return (f["pathSuffix"].startswith("part") and (f["modificationTime"] > fiveMinutesAgoMilisecs))

def lambda_handler(event, context):
    http = urllib3.PoolManager()
    res = http.request("GET", "emr-master.twdu6eu.training:50070/webhdfs/v1/tw/stationMart/data?op=LISTSTATUS")

    resParsed = json.loads(res.data)
    fileStatuses = resParsed["FileStatuses"]["FileStatus"]

    print("Files Statuses in /tw/stationMart/data: ", json.dumps(fileStatuses, sort_keys=True, indent=2))

    healthy = len(list(filter(csvPartsModifiedInLastFiveMinutes, fileStatuses))) > 0

    print("Healthy: ", healthy)

    return {
        'statusCode': res.status,
        'body': {"healthy": healthy}
    }
