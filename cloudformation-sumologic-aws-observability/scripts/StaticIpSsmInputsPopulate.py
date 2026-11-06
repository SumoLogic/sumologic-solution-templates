#!/usr/bin/env python3
"""Populate the AWSO static outbound IP inputs in SSM Parameter Store from a CSV.

One CSV row per account and region. Writes (under /sumologic/awso/network/):
  vpc-id (required), private-subnet-ids, elastic-ip-allocation-id, security-group-id (optional)

Parameters tagged CreatedBy=sumologic-awso are written by the network stack and are never touched.
"""
import argparse
import concurrent.futures
import csv
import datetime
import json
import os
import re
import sys

import boto3
from botocore.exceptions import ClientError

PREFIX = "/sumologic/awso/network"
STACK_TAG = ("CreatedBy", "sumologic-awso")
MANAGED_TAG = ("ManagedBy", "sumologic-awso-static-ip-populate")
REQUIRED = ["account_id", "region", "vpc_id"]
COLUMNS = REQUIRED + ["private_subnet_ids", "elastic_ip_allocation_id", "security_group_id", "role_arn"]
# csv column -> (ssm name, type)
PARAMS = {
    "vpc_id": ("vpc-id", "String"),
    "private_subnet_ids": ("private-subnet-ids", "StringList"),
    "elastic_ip_allocation_id": ("elastic-ip-allocation-id", "String"),
    "security_group_id": ("security-group-id", "String"),
}
PATTERNS = {
    "account_id": re.compile(r"^\d{12}$"),
    "region": re.compile(r"^[a-z]{2}(-[a-z]+)+-\d$"),
    "vpc_id": re.compile(r"^vpc-[0-9a-f]+$"),
    "elastic_ip_allocation_id": re.compile(r"^eipalloc-[0-9a-f]+$"),
    "security_group_id": re.compile(r"^sg-[0-9a-f]+$"),
}
SUBNET = re.compile(r"^subnet-[0-9a-f]+$")


def parse_csv(path):
    """Return (rows, errors). Nothing touches AWS."""
    errors, rows, seen = [], [], {}
    with open(path, newline="") as fh:
        lines = [ln for ln in fh if ln.strip() and not ln.lstrip().startswith("#")]
    reader = csv.DictReader(lines)
    header = [h.strip() for h in (reader.fieldnames or [])]
    missing = [c for c in REQUIRED if c not in header]
    if missing:
        return [], [f"header: missing required column(s): {', '.join(missing)}"]
    unknown = [h for h in header if h not in COLUMNS]
    if unknown:
        return [], [f"header: unknown column(s): {', '.join(unknown)}"]
    for i, raw in enumerate(reader, start=2):
        row = {k.strip(): (v or "").strip() for k, v in raw.items() if k}
        errs = [f"{c} is required" for c in REQUIRED if not row.get(c)]
        for col, pat in PATTERNS.items():
            if row.get(col) and not pat.match(row[col]):
                errs.append(f"{col} '{row[col]}' is invalid")
        subnets = [s for s in row.get("private_subnet_ids", "").split(";") if s.strip()]
        for s in subnets:
            if not SUBNET.match(s.strip()):
                errs.append(f"private_subnet_ids '{s.strip()}' is invalid")
        row["private_subnet_ids"] = ",".join(s.strip() for s in subnets)
        key = (row.get("account_id"), row.get("region"))
        if all(key):
            if key in seen:
                errs.append(f"duplicate account/region (first seen at row {seen[key]})")
            seen.setdefault(key, i)
        if errs:
            errors.extend(f"row {i}: {e}" for e in errs)
        else:
            rows.append(row)
    return rows, errors


def partition_of(session):
    arn = session.client("sts").get_caller_identity()["Arn"]
    return arn.split(":")[1]


def role_arn_for(row, role_name, partition):
    return row.get("role_arn") or f"arn:{partition}:iam::{row['account_id']}:role/{role_name}"


def session_for(row, base, args, partition):
    sts = base.client("sts")
    if args.current_account_only:
        if sts.get_caller_identity()["Account"] != row["account_id"]:
            raise RuntimeError("account differs from the profile account (--current-account-only)")
        return base
    kw = {"RoleArn": role_arn_for(row, args.role_name, partition),
          "RoleSessionName": "awso-static-ip-populate"}
    if args.external_id:
        kw["ExternalId"] = args.external_id
    c = sts.assume_role(**kw)["Credentials"]
    return boto3.Session(aws_access_key_id=c["AccessKeyId"], aws_secret_access_key=c["SecretAccessKey"],
                         aws_session_token=c["SessionToken"], region_name=row["region"])


def validate_resources(ec2, row):
    errs = []
    try:
        vpc = ec2.describe_vpcs(VpcIds=[row["vpc_id"]])["Vpcs"][0]["VpcId"]
        if not ec2.describe_vpc_attribute(VpcId=vpc, Attribute="enableDnsSupport")["EnableDnsSupport"]["Value"]:
            errs.append("VPC has DNS support disabled")
    except ClientError as e:
        return [f"vpc {row['vpc_id']}: {e.response['Error']['Code']}"]
    if row["private_subnet_ids"]:
        ids = row["private_subnet_ids"].split(",")
        try:
            for s in ec2.describe_subnets(SubnetIds=ids)["Subnets"]:
                if s["VpcId"] != row["vpc_id"]:
                    errs.append(f"subnet {s['SubnetId']} is not in {row['vpc_id']}")
        except ClientError as e:
            errs.append(f"subnets: {e.response['Error']['Code']}")
    if row["elastic_ip_allocation_id"]:
        try:
            ec2.describe_addresses(AllocationIds=[row["elastic_ip_allocation_id"]])
        except ClientError as e:
            errs.append(f"elastic ip: {e.response['Error']['Code']}")
    if row["security_group_id"]:
        try:
            sg = ec2.describe_security_groups(GroupIds=[row["security_group_id"]])["SecurityGroups"][0]
            if sg["VpcId"] != row["vpc_id"]:
                errs.append(f"security group is not in {row['vpc_id']}")
        except ClientError as e:
            errs.append(f"security group: {e.response['Error']['Code']}")
    return errs


def _tags(ssm, name):
    t = ssm.list_tags_for_resource(ResourceType="Parameter", ResourceId=name)["TagList"]
    return {x["Key"]: x["Value"] for x in t}


def process_row(row, base, args, partition):
    res = {"account_id": row["account_id"], "region": row["region"], "actions": {}, "status": "ok", "errors": []}
    try:
        sess = session_for(row, base, args, partition)
        if args.validate_resources:
            errs = validate_resources(sess.client("ec2", region_name=row["region"]), row)
            if errs:
                res.update(status="error", errors=errs)
                return res
        ssm = sess.client("ssm", region_name=row["region"])
        for col, (short, typ) in PARAMS.items():
            name = f"{PREFIX}/{short}"
            value = row.get(col, "")
            try:
                current = ssm.get_parameter(Name=name)["Parameter"]["Value"]
            except ClientError as e:
                if e.response["Error"]["Code"] != "ParameterNotFound":
                    raise
                current = None
            if not value:
                if args.prune and current is not None and _tags(ssm, name).get(MANAGED_TAG[0]) == MANAGED_TAG[1]:
                    if not args.dry_run:
                        ssm.delete_parameter(Name=name)
                    res["actions"][short] = "pruned"
                continue
            if current is None:
                if not args.dry_run:
                    ssm.put_parameter(Name=name, Value=value, Type=typ,
                                      Tags=[{"Key": MANAGED_TAG[0], "Value": MANAGED_TAG[1]}])
                res["actions"][short] = "created"
                continue
            if _tags(ssm, name).get(STACK_TAG[0]) == STACK_TAG[1]:
                res["actions"][short] = "conflict"
                res["errors"].append(f"{short} is written by the network stack, not modified")
            elif current == value:
                res["actions"][short] = "unchanged"
            elif args.overwrite:
                if not args.dry_run:
                    ssm.put_parameter(Name=name, Value=value, Type=typ, Overwrite=True)
                res["actions"][short] = "updated"
            else:
                res["actions"][short] = "conflict"
                res["errors"].append(f"{short} exists with a different value (use --overwrite)")
        if res["errors"]:
            res["status"] = "conflict"
    except Exception as e:  # a failed row never stops the others
        res.update(status="error", errors=res["errors"] + [str(e)])
    return res


def run(args):
    rows, errors = parse_csv(args.file)
    if errors:
        print("CSV errors (nothing written):", file=sys.stderr)
        for e in errors:
            print(f"  {e}", file=sys.stderr)
        return 2, []
    if not rows:
        print("CSV has no data rows", file=sys.stderr)
        return 2, []
    base = boto3.Session(profile_name=args.profile) if args.profile else boto3.Session()
    partition = partition_of(base)
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.max_workers) as ex:
        results = list(ex.map(lambda r: process_row(r, base, args, partition), rows))
    tag = "DRY RUN " if args.dry_run else ""
    for r in results:
        acts = ", ".join(f"{k}={v}" for k, v in r["actions"].items()) or "-"
        print(f"{tag}{r['account_id']}/{r['region']}: {r['status']}  [{acts}]")
        for e in r["errors"]:
            print(f"    ! {e}")
    bad = [r for r in results if r["status"] != "ok"]
    print(f"\n{len(results) - len(bad)} ok, {len(bad)} with errors or conflicts")
    return (1 if bad else 0), results


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("-f", "--file", required=True, help="CSV file")
    p.add_argument("-p", "--profile", help="AWS CLI profile used to assume roles")
    p.add_argument("-r", "--role-name", default="OrganizationAccountAccessRole",
                   help="role to assume in each account (default: %(default)s)")
    p.add_argument("--external-id", help="external ID for assume-role")
    p.add_argument("--current-account-only", action="store_true", help="do not assume roles")
    p.add_argument("-n", "--dry-run", action="store_true", help="show changes, write nothing")
    p.add_argument("--overwrite", action="store_true", help="replace existing parameters with a different value")
    p.add_argument("--prune", action="store_true", help="delete script-managed parameters whose CSV cell is blank")
    p.add_argument("--validate-resources", action="store_true", help="check the IDs exist and belong together")
    p.add_argument("--max-workers", type=int, default=4, help="parallel rows (default: %(default)s)")
    args = p.parse_args(argv)
    code, results = run(args)
    if results:
        report = os.path.join(os.path.dirname(os.path.abspath(args.file)),
                              "static_ip_ssm_inputs_report_%s.json" % datetime.datetime.now().strftime("%Y%m%d%H%M%S"))
        with open(report, "w") as fh:
            json.dump(results, fh, indent=2)
        print(f"Report: {report}")
    return code


if __name__ == "__main__":
    sys.exit(main())
