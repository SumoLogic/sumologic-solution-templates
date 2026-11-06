"""Tests for StaticIpSsmInputsPopulate.py. Run: python test_StaticIpSsmInputsPopulate.py (needs boto3, moto)."""
import os
import sys
import tempfile
import unittest
from types import SimpleNamespace

import boto3
from moto import mock_aws

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import StaticIpSsmInputsPopulate as P  # noqa: E402

HEADER = "account_id,region,vpc_id,private_subnet_ids,elastic_ip_allocation_id,security_group_id,role_arn\n"
ROW = "123456789012,us-east-1,vpc-0abc1234,subnet-0aaa1;subnet-0bbb2,eipalloc-0123ab,sg-0123ab,\n"


def write_csv(text):
    f = tempfile.NamedTemporaryFile("w", suffix=".csv", delete=False)
    f.write(text)
    f.close()
    return f.name


def args(**kw):
    d = dict(profile=None, role_name="Role", external_id=None, current_account_only=True, dry_run=False,
             overwrite=False, prune=False, validate_resources=False, max_workers=2)
    d.update(kw)
    return SimpleNamespace(**d)


def ssm(region="us-east-1"):
    return boto3.client("ssm", region_name=region)


class ParseTests(unittest.TestCase):
    def test_valid_with_comments_and_blank_lines(self):
        rows, errs = P.parse_csv(write_csv("# c\n\n" + HEADER + ROW))
        self.assertEqual(errs, [])
        self.assertEqual(rows[0]["private_subnet_ids"], "subnet-0aaa1,subnet-0bbb2")

    def test_missing_required_column(self):
        _, errs = P.parse_csv(write_csv("account_id,region\n1,2\n"))
        self.assertIn("vpc_id", errs[0])

    def test_bad_ids_and_required_cells(self):
        _, errs = P.parse_csv(write_csv(HEADER + "123,us-east-1,vpc-XYZ,subnet-1;bad,eip-1,sg-zz,\n"
                                        "123456789012,,vpc-0a,,,,\n"))
        text = "\n".join(errs)
        for s in ("account_id '123'", "vpc_id 'vpc-XYZ'", "subnet", "elastic_ip", "security_group", "region is required"):
            self.assertIn(s, text)

    def test_duplicates(self):
        _, errs = P.parse_csv(write_csv(HEADER + ROW + ROW))
        self.assertTrue(any("duplicate" in e for e in errs))

    def test_unknown_column(self):
        _, errs = P.parse_csv(write_csv("account_id,region,vpc_id,foo\n"))
        self.assertIn("unknown", errs[0])

    def test_role_arn_and_partition(self):
        row = {"account_id": "123456789012", "role_arn": ""}
        self.assertEqual(P.role_arn_for(row, "R", "aws-cn"), "arn:aws-cn:iam::123456789012:role/R")
        row["role_arn"] = "arn:aws:iam::1:role/X"
        self.assertEqual(P.role_arn_for(row, "R", "aws"), "arn:aws:iam::1:role/X")


@mock_aws
class WriteTests(unittest.TestCase):
    def run_rows(self, text, **kw):
        rows, errs = P.parse_csv(write_csv(text))
        self.assertEqual(errs, [])
        return [P.process_row(r, boto3.Session(region_name="us-east-1"), args(**kw), "aws") for r in rows]

    def test_create_types_tags_and_rerun_unchanged(self):
        r = self.run_rows(HEADER + ROW)[0]
        self.assertEqual(set(r["actions"].values()), {"created"})
        self.assertEqual(ssm().get_parameter(Name=P.PREFIX + "/private-subnet-ids")["Parameter"]["Type"], "StringList")
        tags = {t["Key"]: t["Value"] for t in ssm().list_tags_for_resource(
            ResourceType="Parameter", ResourceId=P.PREFIX + "/vpc-id")["TagList"]}
        self.assertEqual(tags["ManagedBy"], P.MANAGED_TAG[1])
        self.assertEqual(set(self.run_rows(HEADER + ROW)[0]["actions"].values()), {"unchanged"})

    def test_conflict_then_overwrite(self):
        self.run_rows(HEADER + ROW)
        changed = ROW.replace("vpc-0abc1234", "vpc-0def5678")
        r = self.run_rows(HEADER + changed)[0]
        self.assertEqual(r["status"], "conflict")
        self.assertEqual(ssm().get_parameter(Name=P.PREFIX + "/vpc-id")["Parameter"]["Value"], "vpc-0abc1234")
        r = self.run_rows(HEADER + changed, overwrite=True)[0]
        self.assertEqual(r["actions"]["vpc-id"], "updated")
        self.assertEqual(ssm().get_parameter(Name=P.PREFIX + "/vpc-id")["Parameter"]["Value"], "vpc-0def5678")

    def test_stack_written_parameter_never_touched(self):
        ssm().put_parameter(Name=P.PREFIX + "/vpc-id", Value="vpc-0stack", Type="String",
                            Tags=[{"Key": "CreatedBy", "Value": "sumologic-awso"}])
        r = self.run_rows(HEADER + ROW, overwrite=True)[0]
        self.assertEqual(r["actions"]["vpc-id"], "conflict")
        self.assertEqual(ssm().get_parameter(Name=P.PREFIX + "/vpc-id")["Parameter"]["Value"], "vpc-0stack")

    def test_dry_run_writes_nothing(self):
        r = self.run_rows(HEADER + ROW, dry_run=True)[0]
        self.assertEqual(r["actions"]["vpc-id"], "created")
        self.assertEqual(ssm().describe_parameters()["Parameters"], [])

    def test_blank_optional_not_set(self):
        self.run_rows(HEADER + "123456789012,us-east-1,vpc-0abc1234,,,,\n")
        names = [p["Name"] for p in ssm().describe_parameters()["Parameters"]]
        self.assertEqual(names, [P.PREFIX + "/vpc-id"])

    def test_prune_only_script_managed(self):
        self.run_rows(HEADER + ROW)
        ssm().put_parameter(Name=P.PREFIX + "/other", Value="x", Type="String")
        blank = "123456789012,us-east-1,vpc-0abc1234,,,,\n"
        self.run_rows(HEADER + blank)
        self.assertEqual(len(ssm().describe_parameters()["Parameters"]), 5)
        r = self.run_rows(HEADER + blank, prune=True)[0]
        self.assertEqual(r["actions"]["security-group-id"], "pruned")
        names = {p["Name"] for p in ssm().describe_parameters()["Parameters"]}
        self.assertEqual(names, {P.PREFIX + "/vpc-id", P.PREFIX + "/other"})

    def test_account_mismatch_isolated_per_row(self):
        text = HEADER + ROW + "999999999999,us-east-1,vpc-0abc1234,,,,\n"
        res = self.run_rows(text)
        self.assertEqual([x["status"] for x in res], ["ok", "error"])

    def test_validate_resources(self):
        ec2 = boto3.client("ec2", region_name="us-east-1")
        vpc = ec2.create_vpc(CidrBlock="10.0.0.0/16")["Vpc"]["VpcId"]
        other = ec2.create_vpc(CidrBlock="10.1.0.0/16")["Vpc"]["VpcId"]
        sub = ec2.create_subnet(VpcId=other, CidrBlock="10.1.0.0/24")["Subnet"]["SubnetId"]
        row = "123456789012,us-east-1,%s,%s,,,\n" % (vpc, sub)
        r = self.run_rows(HEADER + row, validate_resources=True)[0]
        self.assertEqual(r["status"], "error")
        self.assertEqual(ssm().describe_parameters()["Parameters"], [])
        r = self.run_rows(HEADER + "123456789012,us-east-1,%s,,,,\n" % vpc, validate_resources=True)[0]
        self.assertEqual(r["status"], "ok")


if __name__ == "__main__":
    unittest.main()
