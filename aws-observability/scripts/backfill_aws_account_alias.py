#!/usr/bin/env python3
"""
Backfill 'account' field on sources under aws-observability collectors.

Two-step process:
  Step 1 (prepare): Fetches collectors/sources, generates CSV for user to review
  Step 2 (apply):   Reads user-updated CSV and applies alias changes

Usage:
    # Step 1: Generate CSV (access key prompted interactively — recommended)
    python3 backfill_aws_account_alias.py --access-id <ID> --deploy-env <ENV>

    # Step 2: Apply changes from edited CSV
    python3 backfill_aws_account_alias.py --access-id <ID> --deploy-env <ENV> --filename <csv_path>

    # Dry run — validate and preview what would change, without making API calls
    python3 backfill_aws_account_alias.py --access-id <ID> --deploy-env <ENV> --filename <csv_path> --dry-run

    # Skip confirmation prompt for large batches (>100 sources)
    python3 backfill_aws_account_alias.py --access-id <ID> --deploy-env <ENV> --filename <csv_path> --yes

    # Access key can also be passed via --access-key for automation/CI
    python3 backfill_aws_account_alias.py --access-id <ID> --access-key <KEY> --deploy-env <ENV>

Requirements:
    pip install requests
"""

import argparse
import csv
import getpass
import logging
import os
import re
import sys
import time

import requests

COLLECTOR_PATTERN = re.compile(r"^aws-observability-.*?(\d{12})(?:-|$)")
RETRYABLE_CODES = {429, 500, 502, 503, 504}
CSV_FILE = "backfill_aws_account_alias.csv"
LOG_FILE = "backfill_aws_account_alias.log"
CSV_HEADERS = [
    "collector_id", "collector_name", "source_id", "source_name",
    "accountid", "alias", "override_account_field_with_alias",
]
AWS_ALIAS_PATTERN = re.compile(r"^[a-z0-9]([a-z0-9]|-(?!-)){1,61}[a-z0-9]$")

logger = logging.getLogger(__name__)


def build_base_url(deploy_env):
    """Construct the Sumo Logic API base URL for the given deployment environment."""
    regional = {"au", "ca", "ch", "de", "eu", "jp", "fed", "kr", "us1", "us2"}
    if deploy_env == "us":
        return "https://api.sumologic.com/api/v1"
    if deploy_env in regional:
        return f"https://api.{deploy_env}.sumologic.com/api/v1"
    return f"https://{deploy_env}-api.sumologic.net/api/v1"


def create_session(access_id, access_key):
    """Create an authenticated requests session for the Sumo Logic API."""
    session = requests.Session()
    session.auth = (access_id, access_key)
    session.headers.update({"Content-Type": "application/json"})
    return session


def api_get(session, url, retries=3):
    """Perform a GET request with exponential backoff retry on transient errors."""
    for attempt in range(retries):
        resp = session.get(url, timeout=30)
        if resp.status_code not in RETRYABLE_CODES:
            return resp
        logger.warning(
            "Retryable status %d on %s (attempt %d/%d)",
            resp.status_code, url, attempt + 1, retries,
        )
        time.sleep(2 ** attempt)
    return resp


def api_put(session, url, json_body, etag, retries=3):
    """Perform a PUT request with etag-based optimistic locking and retry on transient errors."""
    for attempt in range(retries):
        resp = session.put(url, json=json_body, headers={"If-Match": etag}, timeout=30)
        if resp.status_code not in RETRYABLE_CODES:
            return resp
        logger.warning(
            "Retryable status %d on %s (attempt %d/%d)",
            resp.status_code, url, attempt + 1, retries,
        )
        time.sleep(2 ** attempt)
    return resp


def get_all_collectors(session, base_url):
    """Fetch all collectors from the org using paginated API calls."""
    collectors = []
    offset = 0
    while True:
        resp = api_get(session, f"{base_url}/collectors?limit=1000&offset={offset}")
        if resp.status_code != 200:
            logger.critical("Failed to fetch collectors (HTTP %d)", resp.status_code)
            sys.exit(1)
        batch = resp.json().get("collectors", [])
        if not batch:
            break
        collectors.extend(batch)
        if len(batch) < 1000:
            break
        offset += 1000
    return collectors


def extract_account_id(collector_name):
    """Extract the 12-digit AWS account ID from an aws-observability collector name."""
    match = COLLECTOR_PATTERN.match(collector_name)
    if match:
        return match.group(1)
    return None


def validate_alias(alias):
    """Validate alias against AWS account alias rules. Returns error message or None if valid."""
    if not AWS_ALIAS_PATTERN.match(alias):
        return ("must be 3-63 chars, lowercase letters/digits/hyphens only, "
                "no leading/trailing or consecutive hyphens")
    return None


def write_csv(rows, csv_path):
    """Write source rows to a CSV file for user review."""
    with open(csv_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=CSV_HEADERS)
        writer.writeheader()
        writer.writerows(rows)


def read_csv(csv_path):
    """Read a CSV file and return rows as a list of dictionaries."""
    with open(csv_path, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        return list(reader)


def _collect_source_rows(session, base_url, col, account_id):
    """Fetch sources for a collector and return CSV-ready rows."""
    logger.info("  Fetching sources for: %s", col["name"])
    resp = api_get(session, f"{base_url}/collectors/{col['id']}/sources")
    if resp.status_code != 200:
        logger.error("  Failed to fetch sources (HTTP %d)", resp.status_code)
        return []

    rows = []
    for src in resp.json().get("sources", []):
        fields = src.get("fields", {})
        accountid_value = fields.get("accountid", "")
        account_value = fields.get("account", "")

        if account_id not in (accountid_value, account_value):
            continue

        prefilled_alias = ""
        if (accountid_value and account_value
                and account_value != accountid_value
                and accountid_value == account_id):
            prefilled_alias = account_value

        rows.append({
            "collector_id": col["id"],
            "collector_name": col["name"],
            "source_id": src["id"],
            "source_name": src["name"],
            "accountid": account_id,
            "alias": prefilled_alias,
            "override_account_field_with_alias": "No",
        })
    return rows


def step1_prepare(session, base_url, csv_path, args):
    """Step 1: Fetch aws-observability collectors and their sources, generate CSV."""
    logger.info("Fetching collectors from %s...", base_url)
    collectors = get_all_collectors(session, base_url)
    logger.info("Total collectors: %d", len(collectors))

    matching = []
    for col in collectors:
        account_id = extract_account_id(col["name"])
        if account_id:
            matching.append((col, account_id))

    logger.info("Matching aws-observability collectors: %d", len(matching))

    if not matching:
        logger.info("No matching collectors found. Nothing to do.")
        return 0

    csv_rows = []
    for col, account_id in matching:
        csv_rows.extend(_collect_source_rows(session, base_url, col, account_id))

    write_csv(csv_rows, csv_path)
    abs_path = os.path.abspath(csv_path)

    logger.info("")
    logger.info("=" * 60)
    logger.info("'%s' is prepared.", abs_path)
    logger.info("Total sources: %d", len(csv_rows))
    logger.info("")
    logger.info("Please update 'alias' and 'override_account_field_with_alias'")
    logger.info("fields in the CSV, then apply with:")
    logger.info("")

    cmd_parts = [
        "python3 backfill_aws_account_alias.py",
        f"  --access-id {args.access_id}",
        f"  --deploy-env {args.deploy_env}",
        f"  --filename {abs_path}",
    ]

    logger.info(" \\\n".join(cmd_parts))
    logger.info("=" * 60)
    return 0


def _validate_rows(to_update):
    """Validate aliases and return (valid_rows, skipped_count)."""
    valid_rows = []
    skipped = 0
    for row in to_update:
        alias = row["alias"].strip()
        error = validate_alias(alias)
        if error:
            col_name = row.get("collector_name", "").strip()
            src_name = row.get("source_name", "").strip()
            logger.warning(
                "Skipping '%s' (%s / %s) — %s",
                alias, col_name, src_name, error,
            )
            skipped += 1
        else:
            valid_rows.append(row)
    return valid_rows, skipped


def _apply_alias(session, base_url, row):
    """Apply alias to a single source. Returns ('updated', 'error', or 'skipped')."""
    collector_id = row.get("collector_id", "").strip()
    collector_name = row["collector_name"].strip()
    source_id = row.get("source_id", "").strip()
    source_name = row["source_name"].strip()
    alias = row["alias"].strip()

    if not collector_id or not source_id:
        logger.error(
            "Missing collector_id or source_id for '%s / %s'",
            collector_name, source_name,
        )
        return "error"

    src_url = (f"{base_url}/collectors/{collector_id}"
               f"/sources/{source_id}")
    etag_resp = api_get(session, src_url)
    if etag_resp.status_code != 200:
        logger.error(
            "Failed to fetch source '%s' (HTTP %d)",
            source_name, etag_resp.status_code,
        )
        return "error"

    etag = etag_resp.headers.get("etag", "")
    source_json = etag_resp.json()["source"]
    source_json.setdefault("fields", {})["account"] = alias

    put_resp = api_put(session, src_url, {"source": source_json}, etag)
    if put_resp.status_code == 200:
        logger.info(
            "Updated: %s / %s → account='%s'",
            collector_name, source_name, alias,
        )
        return "updated"

    logger.error(
        "FAILED: %s / %s (HTTP %d)",
        collector_name, source_name, put_resp.status_code,
    )
    return "error"


def step2_apply(session, base_url, csv_path, args):
    """Step 2: Read the user-edited CSV and apply alias values."""
    if not os.path.isfile(csv_path):
        logger.critical("File not found: %s", csv_path)
        sys.exit(1)

    logger.info("Reading CSV: %s", os.path.abspath(csv_path))
    rows = read_csv(csv_path)

    to_update = [
        r for r in rows
        if (r.get("override_account_field_with_alias", "")
            .strip().lower() == "yes")
        and r.get("alias", "").strip()
    ]

    if not to_update:
        logger.info(
            "No rows marked with override_account_field_with_alias=Yes"
            " (with alias filled). Nothing to apply.",
        )
        return 0

    valid_rows, skipped = _validate_rows(to_update)

    if not valid_rows:
        logger.info("No valid aliases to apply (skipped %d).", skipped)
        return 0

    if len(valid_rows) > 100 and not args.yes:
        resp = input(f"About to update {len(valid_rows)} sources. Continue? [y/N] ")
        if resp.lower() != "y":
            logger.info("Aborted by user.")
            return 0

    if args.dry_run:
        logger.info("DRY RUN — %d sources would be updated:", len(valid_rows))
        for row in valid_rows:
            logger.info(
                "  Would update: %s / %s → account='%s'",
                row["collector_name"].strip(), row["source_name"].strip(),
                row["alias"].strip(),
            )
        logger.info("DRY RUN complete. No changes made.")
        return 0

    logger.info(
        "Applying alias to %d sources (skipped %d invalid)...",
        len(valid_rows), skipped,
    )

    updated, errors = 0, 0
    for row in valid_rows:
        result = _apply_alias(session, base_url, row)
        if result == "updated":
            updated += 1
        elif result == "error":
            errors += 1

    logger.info("")
    logger.info("=" * 60)
    logger.info("DONE — Updated: %d | Errors: %d", updated, errors)
    logger.info("=" * 60)
    return 1 if errors else 0


def main(argv=None):
    """Parse CLI arguments and run step 1 (prepare) or step 2 (apply) based on --filename flag."""
    parser = argparse.ArgumentParser(
        description="Backfill 'account' field on aws-observability collector sources."
    )
    parser.add_argument("--access-id", required=True, help="Sumo Logic access ID")
    parser.add_argument(
        "--access-key", default=None,
        help="Sumo Logic access key (prompted interactively if omitted)",
    )
    parser.add_argument(
        "--deploy-env", required=True,
        help="Deployment (au, us, de, stag, etc.)",
    )
    parser.add_argument(
        "--filename", metavar="FILEPATH",
        help="Path to edited CSV to apply (Step 2)",
    )
    parser.add_argument(
        "--dry-run", action="store_true",
        help="Validate and show what would be updated, but skip actual API calls",
    )
    parser.add_argument(
        "--yes", action="store_true",
        help="Skip confirmation prompt for large batch updates (>100 sources)",
    )
    parser.add_argument(
        "--log-dir", metavar="DIRPATH", default=None,
        help="Directory for log file (created if missing; defaults to current directory)",
    )
    args = parser.parse_args(argv)

    root_logger = logging.getLogger()
    root_logger.setLevel(logging.INFO)

    log_dir = args.log_dir if args.log_dir else "."
    os.makedirs(log_dir, exist_ok=True)
    log_path = os.path.join(log_dir, LOG_FILE)
    file_handler = logging.FileHandler(log_path, encoding="utf-8")
    file_handler.setFormatter(
        logging.Formatter("%(asctime)s [%(levelname)s] %(message)s",
                          datefmt="%Y-%m-%d %H:%M:%S")
    )
    root_logger.addHandler(file_handler)
    logger.info("Log file: %s", os.path.abspath(log_path))

    access_key = args.access_key
    if not access_key:
        access_key = getpass.getpass("Enter Sumo Logic Access Key: ")
        if not access_key:
            logger.critical("Access key is required.")
            sys.exit(1)

    base_url = build_base_url(args.deploy_env)
    session = create_session(args.access_id, access_key)

    if args.filename:
        return step2_apply(session, base_url, args.filename, args)
    return step1_prepare(session, base_url, CSV_FILE, args)


if __name__ == "__main__":
    sys.exit(main())
