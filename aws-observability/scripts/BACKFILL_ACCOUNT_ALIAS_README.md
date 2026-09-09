# Backfill AWS Account Alias

Updates the `account` field on existing AWS Observability collector sources with a human-readable alias (e.g., `prod`, `dev`) instead of the 12-digit AWS account ID.

## Prerequisites

- Python 3.13+
- `pip install requests`
- Sumo Logic Access ID and Access Key with collector/source read+write permissions
- Your Sumo Logic deployment environment (`au`, `ca`, `ch`, `de`, `eu`, `jp`, `fed`, `kr`, `us1`, or `us2`)

## Usage

### Step 1: Generate CSV

```bash
# Access key is prompted interactively (recommended — keeps key out of shell history)
python3 backfill_aws_account_alias.py \
  --access-id <SUMO_ACCESS_ID> \
  --deploy-env <DEPLOYMENT> \
  --log-dir <LOG_DIRECTORY>        # optional
```

This creates `backfill_aws_account_alias.csv` listing all sources under `aws-observability-*` collectors.

### Step 2: Edit the CSV

For each source you want to update:
1. Fill in the `alias` column with your desired alias.
2. Set `override_account_field_with_alias` to `Yes`.

Alias rules: 3-63 chars, lowercase letters/digits/hyphens only, no consecutive hyphens, cannot start/end with hyphen.

### Step 3: Apply changes

```bash
# Preview what would change (no actual updates)
python3 backfill_aws_account_alias.py \
  --access-id <SUMO_ACCESS_ID> \
  --deploy-env <DEPLOYMENT> \
  --filename backfill_aws_account_alias.csv \
  --dry-run

# Apply for real
python3 backfill_aws_account_alias.py \
  --access-id <SUMO_ACCESS_ID> \
  --deploy-env <DEPLOYMENT> \
  --filename backfill_aws_account_alias.csv \
  --log-dir <LOG_DIRECTORY>        # optional
```

> **Note:** When updating more than 100 sources, the script prompts for confirmation. Pass `--yes` to skip the prompt (useful for CI).
>
> `--access-key` can also be passed as a CLI flag for automation/CI use cases.

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--access-id` | Yes | Sumo Logic Access ID |
| `--access-key` | No | Sumo Logic Access Key (prompted interactively if omitted) |
| `--deploy-env` | Yes | Deployment environment (e.g., `us2`, `eu`) |
| `--filename` | Step 2 only | Path to the edited CSV file |
| `--dry-run` | No | Validate and show what would be updated without making API calls |
| `--yes` | No | Skip confirmation prompt for large batch updates (>100 sources) |
| `--log-dir` | No | Directory for the log file (created if it doesn't exist; defaults to current directory) |

## When to use

- You deployed AWS Observability without an account alias and want to add one retroactively.
- You changed your account alias and need to update existing sources.
- You have multiple AWS accounts and want distinct aliases for each.

This script only updates existing sources. New sources created by subsequent deployments will use the alias configured in the CloudFormation/Terraform parameters.
