import logging
import boto3
import os
import re
from botocore.exceptions import BotoCoreError, ClientError

# ─────────────────────────────────────────────
# LOGGING CONFIGURATION
# ─────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger(__name__)

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
    "ap-southeast-4": "appdevzipfiles-ap-southeast-4s",
    "ap-southeast-6": "appdevzipfiles-ap-southeast-6ss",
    "ca-central-1": "appdevzipfiles-ca-central-1",
    "eu-central-1": "appdevzipfiles-eu-central-1",
    "eu-central-2": "appdevzipfiles-eu-central-2ss",
    "eu-north-1": "appdevzipfiles-eu-north-1s",
    "eu-south-1": "appdevzipfiles-eu-south-1",
    "eu-west-1": "appdevzipfiles-eu-west-1",
    "eu-west-2": "appdevzipfiles-eu-west-2",
    "eu-west-3": "appdevzipfiles-eu-west-3",
    "me-central-1": "appdevzipfiles-me-central-1",
    # "me-south-1": "appdevzipfiles-me-south-1s",
    "sa-east-1": "appdevzipfiles-sa-east-1",
    "us-east-1": "appdevzipfiles-us-east-1",
    "us-east-2": "appdevzipfiles-us-east-2",
    "us-west-1": "appdevzipfiles-us-west-1",
    "us-west-2": "appdevzipfiles-us-west-2"
}

base_path = "../helper/LambdaFuncs"
modules = ["loggroup-lambda-connector", "cloudwatch-logs-dlq", "sumo-app-utils", "telemetry"]
s3_path_prefix = "sumologic-aws-observability/functions/"


def parse_version(vstring):
    """Convert v1.2.3 into (1,2,3) for comparison."""
    return tuple(map(int, vstring.lstrip("v").split(".")))


def get_latest_version_dir(parent_dir):
    """Find the latest versioned directory inside parent_dir (vX.Y.Z style)."""
    candidates = []

    try:
        for entry in os.listdir(parent_dir):
            full_path = os.path.join(parent_dir, entry)

            if os.path.isdir(full_path) and re.match(r"^v\d+(\.\d+)*$", entry):
                try:
                    candidates.append((parse_version(entry), entry))
                except ValueError:
                    logger.warning(
                        "Skipping invalid version folder '%s' in %s",
                        entry,
                        parent_dir
                    )

    except FileNotFoundError:
        logger.error("Directory not found: %s", parent_dir)
        return None

    if not candidates:
        logger.warning("No versioned directories found in %s", parent_dir)
        return None

    latest = max(candidates, key=lambda x: x[0])[1]
    latest_path = os.path.join(parent_dir, latest)

    logger.info("Latest version selected: %s", latest_path)
    return latest_path


def upload_module_to_region(region, bucket, module):
    """Upload all ZIP files from latest module version to a regional bucket."""
    logger.info(
        "Processing module '%s' for region '%s' using bucket '%s'",
        module,
        region,
        bucket
    )

    module_dir = os.path.join(base_path, module)
    latest_dir = get_latest_version_dir(module_dir)

    if not latest_dir:
        logger.warning("No versioned folder found for module %s", module)
        return

    s3_client = boto3.client("s3", region_name=region)

    for filename in os.listdir(latest_dir):
        if not filename.endswith(".zip"):
            continue

        file_path = os.path.join(latest_dir, filename)

        try:
            functions_index = file_path.find("LambdaFuncs")
            folder = file_path[functions_index:].replace(os.sep, "/")
            folder = folder.split("/")
            folder = "/".join(folder[1:])

            s3_key = f"{s3_path_prefix}{folder}"

            logger.info(
                "Uploading %s to s3://%s/%s",
                file_path,
                bucket,
                s3_key
            )

            s3_client.upload_file(
                file_path,
                bucket,
                s3_key,
                ExtraArgs={"ACL": "public-read"}
            )

            logger.info(
                "Successfully uploaded %s to s3://%s/%s",
                file_path,
                bucket,
                s3_key
            )

        except (BotoCoreError, ClientError):
            logger.exception(
                "Failed to upload %s to s3://%s/%s",
                file_path,
                bucket,
                s3_key
            )

        except Exception:
            logger.exception(
                "Unexpected error while processing %s",
                file_path
            )


def main():
    logger.info("Starting Lambda ZIP upload process")

    for region, bucket in region_to_bucket.items():
        for module in modules:
            upload_module_to_region(region, bucket, module)

    logger.info("Upload process completed")


if __name__ == "__main__":
    main()