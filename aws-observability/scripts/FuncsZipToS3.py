import boto3
import os
import re
from botocore.exceptions import BotoCoreError, ClientError

os.environ['AWS_PROFILE'] = 'sumocontent'

# Mapping regions to buckets
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
    "me-south-1": "appdevzipfiles-me-south-1s",
    "sa-east-1": "appdevzipfiles-sa-east-1",
    "us-east-1": "appdevzipfiles-us-east-1",
    "us-east-2": "appdevzipfiles-us-east-2",
    "us-west-1": "appdevzipfiles-us-west-1",
    "us-west-2": "appdevzipfiles-us-west-2"
}

# Base path to the apps folder
base_path = "../apps/SumoLogicAWSObservabilityHelper"

# Submodules we care about
modules = ["sumo_app_utils", "telemetry", "loggroup-lambda-connector"]

s3_path_prefix = "sumologic-aws-observability/functions/"

def parse_version(vstring):
    """Convert v1.2.3 into (1,2,3) for comparison."""
    return tuple(map(int, vstring.lstrip("v").split(".")))

def get_latest_version_dir(parent_dir):
    """Find the latest versioned directory inside parent_dir (vX.Y.Z style)."""
    candidates = []
    for entry in os.listdir(parent_dir):
        full_path = os.path.join(parent_dir, entry)
        if os.path.isdir(full_path) and re.match(r"^v\d+(\.\d+)*$", entry):
            try:
                candidates.append((parse_version(entry), entry))
            except ValueError:
                continue
    if not candidates:
        return None
    latest = max(candidates, key=lambda x: x[0])[1]
    return os.path.join(parent_dir, latest)

for region, bucket in region_to_bucket.items():
    s3_client = boto3.client("s3", region_name=region)

    for module in modules:
        module_dir = os.path.join(base_path, module)
        latest_dir = get_latest_version_dir(module_dir)

        if not latest_dir or not os.path.exists(latest_dir):
            print(f"No versioned folder found for {module}")
            continue

        for filename in os.listdir(latest_dir):
            if filename.endswith(".zip"):
                file_path = os.path.join(latest_dir, filename)

                # Build S3 key (preserve relative structure)
                functions_index = file_path.find("SumoLogicAWSObservabilityHelper")
                folder = file_path[functions_index:].replace(os.sep, "/")
                folder = folder.split("/")
                folder = "/".join(folder[1:])  # drop "SumoLogicAWSObservabilityHelper"
                s3_key = f"{s3_path_prefix}{folder}"

                try:
                    s3_client.upload_file(file_path, bucket, s3_key, ExtraArgs={'ACL': 'public-read'})
                    print(f"Uploaded {file_path} → s3://{bucket}/{s3_key} in {region}")
                except (BotoCoreError, ClientError) as e:
                    print(f"Failed to upload {file_path} → s3://{bucket}/{s3_key} in {region}")
                    print(f"Error: {e}")