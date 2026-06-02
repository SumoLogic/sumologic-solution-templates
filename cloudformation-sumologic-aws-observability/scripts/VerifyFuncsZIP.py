# ─────────────────────────────────────────────
# LOGGING CONSTANTS
# ─────────────────────────────────────────────
import logging
import boto3
import os
from pathlib import Path
from botocore.exceptions import ClientError

# Setup proper logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

os.environ['AWS_PROFILE'] = 'sumocontent'

S3_PREFIX = "sumologic-aws-observability/functions"
LAMBDA_FUNCS_DIR = Path(__file__).parent.parent / "helper" / "LambdaFuncs"

REGION_TO_BUCKET = {
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
    # "me-south-1":   "appdevzipfiles-me-south-1s",
    "sa-east-1": "appdevzipfiles-sa-east-1",
    "us-east-1": "appdevzipfiles-us-east-1",
    "us-east-2": "appdevzipfiles-us-east-2",
    "us-west-1": "appdevzipfiles-us-west-1",
    "us-west-2": "appdevzipfiles-us-west-2"
}


# ─────────────────────────────────────────────
# DISCOVER ZIP FILES
# ─────────────────────────────────────────────
def discover_zip_files(base_dir):
    """
    Dynamically discover all ZIP files from LambdaFuncs directory.

    Structure:
        LambdaFuncs/
        └── <function-name>/
            └── <version>/
                └── <filename>.zip

    Args:
        base_dir: Path to LambdaFuncs directory

    Returns:
        list: List of dicts with function info
    """
    zip_files = []
    base_path = Path(base_dir)

    if not base_path.exists():
        logger.error("LambdaFuncs directory not found: %s", base_path)
        return zip_files

    for function_dir in sorted(base_path.iterdir()):
        if not function_dir.is_dir():
            continue

        function_name = function_dir.name

        for version_dir in sorted(function_dir.iterdir()):
            if not version_dir.is_dir():
                continue

            version = version_dir.name

            for zip_file in sorted(version_dir.glob("*.zip")):
                s3_key = f"{S3_PREFIX}/{function_name}/{version}/{zip_file.name}"

                zip_files.append({
                    "function_name": function_name,
                    "version": version,
                    "zip_file": zip_file.name,
                    "s3_key": s3_key
                })

    return zip_files


# ─────────────────────────────────────────────
# VERIFY FILE IN S3
# ─────────────────────────────────────────────
def verify_file_in_bucket(s3_client, bucket_name, s3_key):
    """
    Check if a file exists in an S3 bucket.

    Args:
        s3_client: Boto3 S3 client
        bucket_name: S3 bucket name
        s3_key: S3 object key

    Returns:
        tuple: (exists: bool, message: str)
    """
    try:
        response = s3_client.head_object(Bucket=bucket_name, Key=s3_key)
        size = response.get('ContentLength', 0)
        last_modified = response.get('LastModified', 'Unknown')
        return True, f"EXISTS | Size: {size:,} bytes | Modified: {last_modified}"
    except ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code == "404":
            return False, "NOT FOUND"
        elif error_code == "403":
            return False, "ACCESS DENIED"
        else:
            return False, f"ERROR: {error_code} - {e}"


# ─────────────────────────────────────────────
# PRINT SUMMARY
# ─────────────────────────────────────────────
def print_summary(results):
    """
    Print a summary table of verification results.

    Args:
        results: Dict of results
    """
    total_checks = 0
    total_found = 0
    total_missing = 0
    missing_details = []

    for s3_key, region_results in results.items():
        for region, (exists, _) in region_results.items():
            total_checks += 1
            if exists:
                total_found += 1
            else:
                total_missing += 1
                missing_details.append({
                    "file": s3_key,
                    "region": region,
                    "bucket": REGION_TO_BUCKET[region]
                })

    logger.info("=" * 70)
    logger.info("VERIFICATION SUMMARY")
    logger.info("=" * 70)
    logger.info("Total Checks : %d", total_checks)
    logger.info("Found        : %d", total_found)
    logger.info("Missing      : %d", total_missing)

    if missing_details:
        logger.warning("Missing Files:")
        logger.warning("-" * 70)
        for item in missing_details:
            logger.warning("File   : %s", item['file'])
            logger.warning("Region : %s", item['region'])
            logger.warning("Bucket : %s", item['bucket'])
            logger.warning("-" * 70)
    else:
        logger.info("All files verified successfully across all regions")

    logger.info("=" * 70)

    return total_missing == 0


# ─────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────
def main():
    logger.info("=" * 70)
    logger.info("Lambda ZIP File Verification Script")
    logger.info("=" * 70)
    logger.info("LambdaFuncs Dir : %s", LAMBDA_FUNCS_DIR)
    logger.info("S3 Prefix       : %s", S3_PREFIX)
    logger.info("Regions         : %d", len(REGION_TO_BUCKET))
    logger.info("=" * 70)

    # Step 1: Discover ZIP files
    logger.info("Discovering ZIP files...")
    zip_files = discover_zip_files(LAMBDA_FUNCS_DIR)

    if not zip_files:
        logger.error("No ZIP files found in %s", LAMBDA_FUNCS_DIR)
        return 1

    logger.info("Found %d ZIP file(s):", len(zip_files))
    for zf in zip_files:
        logger.info("  [FILE] %s/%s/%s", zf['function_name'], zf['version'], zf['zip_file'])
        logger.info("         S3 Key: %s", zf['s3_key'])

    logger.info("=" * 70)

    # Step 2: Verify each ZIP across all regions
    results = {}

    for zip_info in zip_files:
        s3_key = zip_info['s3_key']
        results[s3_key] = {}

        logger.info("Verifying: %s/%s/%s", zip_info['function_name'], zip_info['version'], zip_info['zip_file'])
        logger.info("S3 Key: %s", s3_key)
        logger.info("-" * 70)

        for region, bucket_name in REGION_TO_BUCKET.items():
            s3_client = boto3.client('s3', region_name=region)
            exists, message = verify_file_in_bucket(s3_client, bucket_name, s3_key)
            results[s3_key][region] = (exists, message)

            if exists:
                logger.info("  [PASS] [%-20s] %-45s %s", region, bucket_name, message)
            else:
                logger.warning("  [FAIL] [%-20s] %-45s %s", region, bucket_name, message)

    # Step 3: Print summary
    all_passed = print_summary(results)

    return 0 if all_passed else 1


if __name__ == "__main__":
    exit(main())