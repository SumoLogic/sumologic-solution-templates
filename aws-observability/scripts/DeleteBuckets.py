import subprocess

import boto3

if __name__ == '__main__':
    s3client = boto3.client('s3')
    response = s3client.list_buckets()
    if "Buckets" in response:
        for bucket in response["Buckets"]:
            if "aws-observability-logs-" in bucket["Name"] or "aws-test-observability-logs-" in bucket["Name"]:
                print(bucket["Name"])
                process = subprocess.Popen(["aws", "s3", "rb", "s3://"+bucket["Name"], "--force"])
