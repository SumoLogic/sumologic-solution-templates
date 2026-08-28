#!/usr/bin/env python3
"""
Backfill 'account' field on sources under aws-observability collectors.

Two-step process:
  Step 1 (prepare): Fetches collectors/sources, generates CSV for user to review
  Step 2 (apply):   Reads user-updated CSV and applies alias changes

Usage:
    # Step 1: Generate CSV
    python3 backfill_aws_account_alias.py --access-id <ID> --access-key <KEY> --deploy-env <ENV>

    # Step 2: Apply changes from edited CSV
    python3 backfill_aws_account_alias.py --access-id <ID> --access-key <KEY> --deploy-env <ENV> --filename <csv_path>

Requirements:
    pip install requests
"""

import argparse
import csv
import os
import re
import sys
import time

import requests

COLLECTOR_PATTERN = re.compile(r"^aws-observability-.*?(\d{12})(?:-|$)")
RETRYABLE_CODES = {429, 500, 502, 503, 504}
CSV_FILE = "backfill_aws_account_alias.csv"
CSV_HEADERS = ["collector_id", "collector_name", "source_id", "source_name", "accountid", "alias", "override_account_field_with_alias"]
AWS_ALIAS_PATTERN = re.compile(r"^[a-z0-9]([a-z0-9-]*[a-z0-9])?$")


def build_base_url(deploy_env):
    """Construct the Sumo Logic API base URL for the given deployment environment."""
    regional = {"au", "ca", "de", "eu", "fed", "in", "jp", "kr", "us1", "us2"}
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
        resp = session.get(url)
        if resp.status_code not in RETRYABLE_CODES:
            return resp
        time.sleep(2 ** attempt)
    return resp


def api_put(session, url, json_body, etag, retries=3):
    """Perform a PUT request with etag-based optimistic locking and retry on transient errors."""
    for attempt in range(retries):
        resp = session.put(url, json=json_body, headers={"If-Match": etag})
        if resp.status_code not in RETRYABLE_CODES:
            return resp
        time.sleep(2 ** attempt)
    return resp


def get_all_collectors(session, base_url):
    """Fetch all collectors from the org using paginated API calls."""
    collectors = []
    offset = 0
    while True:
        resp = api_get(session, f"{base_url}/collectors?limit=1000&offset={offset}")
        if resp.status_code != 200:
            sys.exit(f"ERROR: Failed to fetch collectors (HTTP {resp.status_code})")
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
    if len(alias) < 3 or len(alias) > 63:
        return f"must be 3-63 characters (got {len(alias)})"
    if "--" in alias:
        return "must not contain consecutive hyphens"
    if not AWS_ALIAS_PATTERN.match(alias):
        return "must contain only lowercase letters, digits, and hyphens; must not start/end with hyphen"
    return None


def write_csv(rows, csv_path):
    """Write source rows to a CSV file for user review."""
    with open(csv_path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=CSV_HEADERS)
        writer.writeheader()
        writer.writerows(rows)


def read_csv(csv_path):
    """Read a CSV file and return rows as a list of dictionaries."""
    with open(csv_path, newline="") as f:
        reader = csv.DictReader(f)
        return list(reader)


def step1_prepare(session, base_url, csv_path, args):
    """Step 1: Fetch aws-observability collectors and their sources, generate a CSV for user review."""
    print(f"Fetching collectors from {base_url}...")
    collectors = get_all_collectors(session, base_url)
    print(f"Total collectors: {len(collectors)}")

    matching = []
    for col in collectors:
        account_id = extract_account_id(col["name"])
        if account_id:
            matching.append((col, account_id))

    print(f"Matching aws-observability collectors: {len(matching)}")

    if not matching:
        print("No matching collectors found. Nothing to do.")
        return 0

    csv_rows = []
    for col, account_id in matching:
        print(f"  Fetching sources for: {col['name']}")
        resp = api_get(session, f"{base_url}/collectors/{col['id']}/sources")
        if resp.status_code != 200:
            print(f"    ERROR: Failed to fetch sources (HTTP {resp.status_code})")
            continue

        sources = resp.json().get("sources", [])
        for src in sources:
            fields = src.get("fields", {})
            accountid_value = fields.get("accountid", "")
            account_value = fields.get("account", "")

            accountid_matches = accountid_value == account_id
            account_matches = account_value == account_id

            if not accountid_matches and not account_matches:
                continue

            prefilled_alias = ""
            if accountid_value and account_value and account_value != accountid_value:
                if accountid_matches:
                    prefilled_alias = account_value


            csv_rows.append({
                "collector_id": col["id"],
                "collector_name": col["name"],
                "source_id": src["id"],
                "source_name": src["name"],
                "accountid": account_id,
                "alias": prefilled_alias,
                "override_account_field_with_alias": "No",
            })

    write_csv(csv_rows, csv_path)
    abs_path = os.path.abspath(csv_path)

    print(f"\n{'=' * 60}")
    print(f"'{abs_path}' is prepared.")
    print(f"Total sources: {len(csv_rows)}")
    print(f"\nPlease update 'alias' and 'override_account_field_with_alias'")
    print(f"fields in the CSV, then apply with:\n")

    cmd_parts = [
        f"python3 backfill_aws_account_alias.py",
        f"  --access-id {args.access_id}",
        f"  --access-key {args.access_key}",
        f"  --deploy-env {args.deploy_env}",
        f"  --filename {abs_path}",
    ]

    print(" \\\n".join(cmd_parts))
    print(f"\n{'=' * 60}")
    return 0


def step2_apply(session, base_url, csv_path):
    """Step 2: Read the user-edited CSV and apply alias values to the 'account' field on each source."""
    if not os.path.isfile(csv_path):
        sys.exit(f"ERROR: File not found: {csv_path}")

    print(f"Reading CSV: {os.path.abspath(csv_path)}")
    rows = read_csv(csv_path)

    to_update = [
        r for r in rows
        if r.get("override_account_field_with_alias", "").strip().lower() == "yes"
        and r.get("alias", "").strip()
    ]

    if not to_update:
        print("No rows marked with override_account_field_with_alias=Yes (with alias filled). Nothing to apply.")
        return 0

    valid_rows = []
    skipped = 0
    for row in to_update:
        alias = row["alias"].strip()
        error = validate_alias(alias)
        if error:
            print(f"  WARNING: Skipping '{alias}' ({row.get('collector_name', '').strip()} / {row.get('source_name', '').strip()}) — {error}")
            skipped += 1
        else:
            valid_rows.append(row)

    if not valid_rows:
        print(f"\nNo valid aliases to apply (skipped {skipped}).")
        return 0

    print(f"Applying alias to {len(valid_rows)} sources (skipped {skipped} invalid)...")

    updated, errors = 0, 0

    for row in valid_rows:
        collector_id = row.get("collector_id", "").strip()
        collector_name = row["collector_name"].strip()
        source_id = row.get("source_id", "").strip()
        source_name = row["source_name"].strip()
        alias = row["alias"].strip()

        if not collector_id or not source_id:
            print(f"  ERROR: Missing collector_id or source_id for '{collector_name} / {source_name}'")
            errors += 1
            continue

        src_url = f"{base_url}/collectors/{collector_id}/sources/{source_id}"
        etag_resp = api_get(session, src_url)
        if etag_resp.status_code != 200:
            print(f"  ERROR: Failed to fetch source '{source_name}' (HTTP {etag_resp.status_code})")
            errors += 1
            continue

        etag = etag_resp.headers.get("etag", "")
        source_json = etag_resp.json()["source"]
        source_json.setdefault("fields", {})["account"] = alias

        put_resp = api_put(session, src_url, {"source": source_json}, etag)
        if put_resp.status_code == 200:
            print(f"  Updated: {collector_name} / {source_name} → account='{alias}'")
            updated += 1
        else:
            print(f"  FAILED: {collector_name} / {source_name} (HTTP {put_resp.status_code})")
            errors += 1

    print(f"\n{'=' * 60}")
    print(f"DONE — Updated: {updated} | Errors: {errors}")
    print(f"{'=' * 60}")
    return 1 if errors else 0


def main(argv=None):
    """Parse CLI arguments and run step 1 (prepare) or step 2 (apply) based on --filename flag."""
    parser = argparse.ArgumentParser(
        description="Backfill 'account' field on aws-observability collector sources."
    )
    parser.add_argument("--access-id", required=True, help="Sumo Logic access ID")
    parser.add_argument("--access-key", required=True, help="Sumo Logic access key")
    parser.add_argument("--deploy-env", required=True, help="Deployment (au, us, de, stag, etc.)")
    parser.add_argument("--filename", metavar="FILEPATH", help="Path to edited CSV to apply (Step 2)")
    args = parser.parse_args(argv)

    base_url = build_base_url(args.deploy_env)
    session = create_session(args.access_id, args.access_key)

    if args.filename:
        return step2_apply(session, base_url, args.filename)
    else:
        return step1_prepare(session, base_url, CSV_FILE, args)


if __name__ == "__main__":
    sys.exit(main())
