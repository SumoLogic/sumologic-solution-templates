import boto3
from botocore.exceptions import ClientError

# Set the AWS profile
import os

os.environ['AWS_PROFILE'] = 'sumocontent'

# Mapping regions to bucket names
region_to_bucket = {
    "af-south-1": "appdevzipfiles-af-south-1s",
    "ap-east-1": "appdevzipfiles-ap-east-1s",
    "ap-northeast-1": "appdevzipfiles-ap-northeast-1",
    "ap-northeast-2": "appdevzipfiles-ap-northeast-2",
    "ap-northeast-3": "appdevzipfiles-ap-northeast-3s",
    "ap-south-1": "appdevzipfiles-ap-south-1",
    "ap-southeast-1": "appdevzipfiles-ap-southeast-1",
    "ap-southeast-2": "appdevzipfiles-ap-southeast-2",
    "ap-southeast-3": "appdevzipfiles-ap-southeast-3",
    "ca-central-1": "appdevzipfiles-ca-central-1",
    "eu-central-1": "appdevzipfiles-eu-central-1",
    "eu-central-2": "appdevzipfiles-eu-central-2ss",
    "eu-north-1": "appdevzipfiles-eu-north-1s",
    "eu-south-1": "appdevzipfiles-eu-south-1",
    "eu-west-1": "appdevzipfiles-eu-west-1",
    "eu-west-2": "appdevzipfiles-eu-west-2",
    "eu-west-3": "appdevzipfiles-eu-west-3",
    "me-central-1": "appdevzipfiles-me-central-1",
    #"me-south-1": "appdevzipfiles-me-south-1s",
    "sa-east-1": "appdevzipfiles-sa-east-1",
    "us-east-1": "appdevzipfiles-us-east-1",
    "us-east-2": "appdevzipfiles-us-east-2",
    "us-west-1": "appdevzipfiles-us-west-1",
    "us-west-2": "appdevzipfiles-us-west-2"
}

# File path to check
file_path = "sumologic-aws-observability/apps/SumoLogicAWSObservabilityHelper/SumoLogicAWSObservabilityHelperv2.0.23.zip"

# Check each bucket
for region, bucket_name in region_to_bucket.items():
    s3 = boto3.client('s3', region_name=region)
    print(f"Checking in region: {region} -> bucket: {bucket_name}")

    try:
        s3.head_object(Bucket=bucket_name, Key=file_path)
        print(f"File exists in {bucket_name}")
    except ClientError as e:
        if e.response['Error']['Code'] == "404":
            print(f"File NOT found in {bucket_name}")
        else:
            print(f"Error checking {bucket_name}: {e}")

    print("---------------------------------")
