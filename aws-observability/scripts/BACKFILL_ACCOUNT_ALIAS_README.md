# Backfill AWS Account Alias

Updates the `account` field on existing AWS Observability collector sources with a human-readable alias (e.g., `prod`, `dev`) instead of the 12-digit AWS account ID.

## Prerequisites

- Python 3.6+
- `pip install requests`
- Sumo Logic Access ID and Access Key with collector/source read+write permissions
- Your Sumo Logic deployment environment (`us1`, `us2`, `eu`, `au`, `de`, `jp`, `ca`, `in`, `kr`, `fed`)

## Usage

### Step 1: Generate CSV

```bash
python3 backfill_aws_account_alias.py \
  --access-id <SUMO_ACCESS_ID> \
  --access-key <SUMO_ACCESS_KEY> \
  --deploy-env <DEPLOYMENT>
```

This creates `backfill_aws_account_alias.csv` listing all sources under `aws-observability-*` collectors.

### Step 2: Edit the CSV

For each source you want to update:
1. Fill in the `alias` column with your desired alias.
2. Set `override_account_field_with_alias` to `Yes`.

Alias rules: 3-63 chars, lowercase letters/digits/hyphens only, no consecutive hyphens, cannot start/end with hyphen.

### Step 3: Apply changes

```bash
python3 backfill_aws_account_alias.py \
  --access-id <SUMO_ACCESS_ID> \
  --access-key <SUMO_ACCESS_KEY> \
  --deploy-env <DEPLOYMENT> \
  --filename backfill_aws_account_alias.csv
```

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--access-id` | Yes | Sumo Logic Access ID |
| `--access-key` | Yes | Sumo Logic Access Key |
| `--deploy-env` | Yes | Deployment environment (e.g., `us2`, `eu`) |
| `--filename` | Step 2 only | Path to the edited CSV file |

## When to use

- You deployed AWS Observability without an account alias and want to add one retroactively.
- You changed your account alias and need to update existing sources.
- You have multiple AWS accounts and want distinct aliases for each.

This script only updates existing sources. New sources created by subsequent deployments will use the alias configured in the CloudFormation/Terraform parameters.
