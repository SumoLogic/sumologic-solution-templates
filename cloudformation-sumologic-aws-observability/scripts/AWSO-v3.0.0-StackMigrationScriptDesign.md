# AWSO v3.0.0 — Migration Script Design Document

> **Script**: `scripts/MigrateAWSOStackToV300.sh`
> **Supported source versions**: v2.12, v2.13, v2.14, v2.15
> **Target version**: v3.0.0
> **Status**: Built and validated (2026-07-06, KR org, us-west-2)

---

## Prerequisites (Phase 0)

The script assumes a v2.x (v2.12–v2.15) AWSO stack is already deployed and in `CREATE_COMPLETE` or `UPDATE_COMPLETE` state. The stack must have:
- A working Sumo Logic collector with 5 sources (alb-logs, classic-lb-logs, cloudtrail-logs, cloudwatch-metrics, kinesis-firehose-cloudwatch-logs)
- S3 bucket(s) for log storage
- Valid Sumo API credentials (access ID/key) with admin access

---

## Architecture Overview

The script performs an in-place migration by: ensuring Sumo resources are preserved, fetching bucket names from Sumo sources, deleting the v2.x stack, cleaning up FERs, deploying a fresh v3.0.0 stack with mapped parameters, and patching source roleARNs to the new IAM role.

```
Phase 0:  (Assumption)  → v2.x stack is deployed and healthy
Phase 1:  Validate      → Check AWS/Sumo creds, detect version, confirm stack
Phase 2:  Capture       → Fetch collector, sources, and S3 bucket names from Sumo
Phase 3:  Map Params    → Transform v2.x params to v3.0.0 format
Phase 4:  Confirm       → Show all details + v3.0.0 params + destructive actions, user approval
Phase 5:  Protect       → Ensure RemoveOnDeleteStack=false (update stack if needed)
Phase 6:  Delete        → Delete v2.x stack (retain-resources if bucket blocks); clean up nested stacks
Phase 7:  FER Cleanup   → Rename/disable 17 AWSO FERs to free quota
Phase 8:  Metric Rules  → Delete 4 AWSO metric rules
Phase 9:  Deploy        → Create v3.0.0 stack with mapped params
Phase 10: Verify        → Confirm stack + 5/5 sources alive
Phase 11: Patch Roles   → Update source roleARNs to new IAM role
Phase 12: Report        → Print summary + cleanup instructions
```

---

## Phase 1: Validate Prerequisites

### What it does
- Checks `jq`, `curl`, `aws` CLI are available
- Validates AWS credentials via `sts get-caller-identity`
- Validates Sumo Logic credentials via API ping
- Confirms the source stack exists and is in `CREATE_COMPLETE`, `UPDATE_COMPLETE`, or `UPDATE_ROLLBACK_COMPLETE` state
- Auto-detects source version (v2.12–v2.15) by checking for parameter fingerprint (Section10a + Section7aLambda + Section9a)
- Captures `ACCOUNT_ID` for later use

### Auto-recovery on special stack states

| Stack status | Behavior |
|---|---|
| `DELETE_IN_PROGRESS` | Waits for deletion to complete, then auto-resumes from Phase 7 using a saved params file |
| `DELETE_FAILED` | Calls `phase_delete_retain_only` to delete with `--retain-resources`, then auto-resumes from Phase 7 |
| Stack not found (`DELETE_COMPLETE`) | Auto-detects saved params file for the new stack name, sets `RESUME=true` to continue from Phase 7 |

### Issues Faced & Resolutions

| Issue | Resolution |
|-------|------------|
| `aws` not in PATH | Wrapped all AWS commands in `aws_cmd()` helper that uses `/bin/zsh -l -c 'aws --profile "$1" "${@:2}"'` |
| Version detection only matched v2.15 | All v2.12–v2.15 have identical parameter fingerprints, so the same check works for all |

---

## Phase 2: Capture Sumo Source Details

### What it does
1. Finds the AWSO collector via `find_awso_collector()` (paginated search)
2. Cross-checks collector ID against `SumoLogicHostedCollector` in the old stack's `CreateCommonResources` nested stack
3. Lists all sources on the collector via `GET /api/v1/collectors/{id}/sources`
4. Extracts bucket names directly from each S3 source's configuration:
   - `alb-logs` → `.thirdPartyRef.resources[0].path.bucketName` → ALB bucket
   - `cloudtrail-logs` → CloudTrail bucket
   - `classic-lb-logs` → ELB bucket
5. Verifies each bucket is accessible via `s3api head-bucket`

### Collector ID mismatch handling
If the collector found via Sumo API doesn't match the one recorded in the CF stack, the script now offers three options:
1. **Use Sumo API collector** — proceed with the name-matched collector
2. **Enter correct collector ID manually** — user provides the exact numeric ID to use
3. **Abort** — stop migration for manual investigation

### Why fetch from Sumo sources (not CloudFormation params)
- Works even if CFN params were left empty (auto-created bucket)
- Gets the *actual* bucket the source is reading from, not what was in the template params
- Doesn't require the nested stack to still exist
- More reliable than parsing CloudFormation nested stack resources

### Why this matters
The S3 bucket survives stack deletion (it's non-empty, so CloudFormation can't delete it). v3.0.0 needs the bucket name passed in params to reuse it rather than creating a new one.

---

## Phase 3: Map Parameters

### What it does
Transforms v2.x stack parameters to v3.0.0 format using a single `jq` filter that:

1. **Removes** params not in v3.0.0:
   - `Section10aAppInstallLocation`
   - `Section10bShare`

2. **Renames** params:
   - `Section7aLambdaCreateCloudWatchLogsSourceOptions` → `Section7aCreateCloudWatchLogsSourceOptions`
   - `Section7bLambdaCloudWatchLogsSourceUrl` → `Section7bCloudWatchLogsSourceUrl`
   - `Section9a–9e` → `Section8a–8e` (ELB section moved from 9 to 8)

3. **Overrides** values:
   - Bucket names: populate from Phase 2 capture
   - `RemoveOnDeleteStack`: force to `false`
   - `AccessKey`: inject from `-k` flag (never read from stack — it's masked as `****`)
   - `InstallObservabilityApps`: inject from `--install-apps` flag
   - Source URL params: clear to empty (forces "create new" mode)

### Version Support
All v2.12–v2.15 have identical parameter names. The mapping functions for v2.12/v2.13/v2.14 delegate directly to the v2.15 mapper.

### Issues Faced & Resolutions

| Issue | Resolution |
|-------|------------|
| CloudFormation returns `****` for NoEcho params (`Section1cSumoLogicAccessKey`) | Script injects the real access key from the `-k` flag via `--arg access_key "$ACCESS_KEY"` in jq |
| `${INSTALL_APPS,,}: bad substitution` on macOS | bash 3.2 doesn't support `,,` — replaced with `tr '[:upper:]' '[:lower:]'` |

---

## Phase 4: Confirm Migration Details

### What it does
Displays a full summary of what was captured, the mapped v3.0.0 parameters, and all destructive actions:

1. **Stack details**: name, region, account ID, source version
2. **Collector**: name and ID
3. **Sources**: all source IDs, names, and types on the collector
4. **S3 buckets**: ALB, CloudTrail, and ELB bucket names fetched from sources
5. **v3.0.0 deployment parameters**: new stack name, template URL, deployment, install apps, source mode, bucket names, params file path
6. **Destructive actions**:
   - Stack update to set RemoveOnDeleteStack=false
   - Stack deletion
   - 17 AWSO FER renames (lists each name)
   - 4 AWSO metric rule deletions (lists each name)
7. **Backup instructions**: where to export FERs and view metric rules in Sumo UI
8. Requires user to type `yes` to proceed; aborts on anything else

### Why this runs after Capture + Map but before any modifications
Capture (Phase 2) and Map (Phase 3) are both read-only — they fetch data and transform params without modifying anything. By running them first, the confirmation can show the user:
- The actual collector, source IDs, and bucket names that were found
- The exact v3.0.0 parameters that will be used for deployment
- All destructive actions that target the intended resources

### Note on resume mode
In `--resume` mode, this phase is skipped — the user already confirmed during the original run.

---

## Phase 5: Ensure RemoveOnDeleteStack=false

### What it does
- Reads `Section1eSumoLogicResourceRemoveOnDeleteStack` from the stack parameters
- If already `false`: logs confirmation and moves on
- If `true`: updates the stack to set it to `false`
- Waits for `UPDATE_COMPLETE` before proceeding
- Re-fetches the stack JSON after update

### Why this is a separate phase
This is a **critical safety gate**. If `RemoveOnDeleteStack=true` and we proceed to Phase 6 (delete), the Sumo Lambda helper will delete the collector and all sources — making them unrecoverable.

### Issues Faced & Resolutions

| Issue | Resolution |
|-------|------------|
| Stack update used shell interpolation for `--parameters` (injection risk) | Build JSON array via jq into a temp file, pass `file://` to CloudFormation |
| Update can fail if stack is in a non-updatable state | Check stack status in Phase 1 first; only allow `CREATE_COMPLETE` / `UPDATE_COMPLETE` |

---

## Phase 6: Delete v2.x Stack

### What it does
1. Initiates normal stack deletion
2. Polls until `DELETE_COMPLETE` or `DELETE_FAILED` (timeout: 1800s)
3. On `DELETE_FAILED`: calls `phase_delete_retain_only` (see below)
4. After main stack is deleted: calls `phase_delete_retain_only` on each orphaned nested stack

### `phase_delete_retain_only` helper
When a stack is in `DELETE_FAILED`:
1. Describes stack events to find all `DELETE_FAILED` resources (excluding the stack itself)
2. Calls `delete-stack --retain-resources <logical-ids>` — skips only the blocking resources, deletes everything else cleanly
3. Polls until `DELETE_COMPLETE`
4. For each retained resource that is a nested stack (`AWS::CloudFormation::Stack`): extracts the physical stack name from the ARN and recursively deletes it with `--retain-resources` for its own blocked resources

### `cleanup_orphaned_nested_stacks` helper
Called by `--resume` when the main stack is already deleted:
1. Uses `list-stacks --stack-status-filter DELETE_FAILED` to find stacks prefixed `<parent_stack>-`
2. For each: describes its events, deletes with `--retain-resources` for its blocked logical IDs
3. Warns on any that don't reach `DELETE_COMPLETE`

### Why `--retain-resources` instead of `FORCE_DELETE_STACK`
`--retain-resources` takes explicit logical IDs and skips only those resources, deleting everything else cleanly — the main stack and all other nested stacks reach `DELETE_COMPLETE`. `FORCE_DELETE_STACK` can leave additional orphaned nested stacks in an unpredictable state.

### Why DELETE_FAILED is expected
The `CommonS3Bucket` in `CreateCommonResources` is non-empty (contains logs). CloudFormation cannot delete non-empty S3 buckets. Retaining it leaves it intact for v3.0.0 to reuse.

### Issues Faced & Resolutions

| Issue | Resolution |
|-------|------------|
| `log_info` inside polling loop wrote to stdout, contaminating captured status variable | Added `>&2` to redirect log messages to stderr |
| `--retain-resources` ValidationError: "resources must be in a valid state" | Stack's own name appeared in events with `DELETE_FAILED`. Fixed by filtering `select(.LogicalResourceId != $stack)` before building retain list |
| `mapfile` not available on macOS bash 3.2 | Replaced with portable `while IFS= read -r` loop reading from a heredoc |
| Orphaned nested stack not deleted after main stack | `phase_delete_retain_only` now iterates retained nested stacks from events and deletes them; `cleanup_orphaned_nested_stacks` handles pre-existing orphans on `--resume` |

---

## Phase 7: FER Cleanup

### What it does
1. Checks FER quota via `GET /api/v1/extractionRules/quota`
2. Fetches all existing FERs (paginated)
3. Identifies 17 AWSO FERs by exact name match
4. If quota allows (≥17 free slots): renames each to `v215_backup_<name>` and disables
5. If quota is tight: same operation (rename frees the original name for v3.0.0 to recreate)

### The 17 AWSO FER names
```
AwsObservabilityFieldExtractionRule
AwsObservabilityAlbAccessLogsFER
AwsObservabilityElbAccessLogsFER
AwsObservabilityApiGatewayAccessLogsFER
AwsObservabilityApiGatewayCloudTrailLogsFER
AwsObservabilityALBCloudTrailLogsFER
AwsObservabilityCLBCloudTrailLogsFER
AwsObservabilityNLBCloudTrailLogsFER
AwsObservabilityDynamoDBCloudTrailLogsFER
AwsObservabilityEC2CloudTrailLogsFER
AwsObservabilityECSCloudTrailLogsFER
AwsObservabilityElastiCacheCloudTrailLogsFER
AwsObservabilityLambdaCloudWatchLogsFER
AwsObservabilityGenericCloudWatchLogsFER
AwsObservabilityRdsCloudTrailLogsFER
AwsObservabilitySNSCloudTrailLogsFER
AwsObservabilitySQSCloudTrailLogsFER
```

### Why this is needed
v3.0.0 creates the same 17 FERs. If they already exist (from v2.x), the deploy fails with `fer:invalid_extraction_rule`. Renaming (not deleting) preserves a backup and frees the names.

### Resume mode behavior
In `--resume` mode, this phase runs but is **idempotent**:
- Before doing any work, it checks if any of the 17 AWSO FERs still exist with their original names
- If none found → logs "cleanup already done in previous run" and skips
- If found → proceeds with rename/disable as normal

This handles the case where a first run renamed FERs successfully but the subsequent deploy failed. On resume, the FER phase is a safe no-op.

### Issues Faced & Resolutions

| Issue | Resolution |
|-------|------------|
| FER pagination used wrong field (`.next // ""`) | Sumo API returns `{next: {token: "..."}}` — fixed to `.next.token // ""` |
| ETag required for PUT updates | Used `sumo_get_with_etag()` to capture response headers, extract ETag for `If-Match` |

---

## Phase 8: Metric Rules Cleanup

### What it does
Deletes 4 AWSO metric rules that conflict with v3.0.0's installation:
1. `AwsObservabilityRDSClusterMetricsEntityRule`
2. `AwsObservabilityRDSInstanceMetricsEntityRule`
3. `AwsObservabilityNLBMetricsEntityRule`
4. `AwsObservabilityApiGatewayApiNameMetricsEntityRule`

Uses `DELETE /api/v1/metricsRules/{name}`:
- `204` → deleted successfully
- `404` → already removed (safe to skip)
- `403` → system rule, cannot be deleted (warning only)

### Why this is needed
v3.0.0 creates the same metric rules. If they already exist from v2.x, the deploy fails with `metrics:rule_already_exists`. Unlike FERs (which are renamed as backup), metric rules are deleted outright — they contain no user data and are fully recreated by v3.0.0.

---

## Phase 9: Deploy v3.0.0 Stack

### What it does
1. Loads mapped params (from Phase 3 output or saved file in resume mode)
2. Creates stack via `aws cloudformation create-stack` with:
   - Template URL: `https://sumologic-appdev-aws-sam-apps.s3.us-east-1.amazonaws.com/aws-observability-versions/v3.0.0/templates/sumologic_observability.master.template.yaml`
   - Capabilities: `CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND`
   - Parameters from the mapped JSON file
3. Polls until `CREATE_COMPLETE` or failure (timeout: 2700s)

### Issues Faced & Resolutions

| Issue | Resolution |
|-------|------------|
| `S3 error: Access Denied` on template URL | Original URL was `s3.amazonaws.com` without region and missing `/templates/` path. Correct URL uses `s3.us-east-1.amazonaws.com` and includes `/templates/` |
| `SumoLogicHostedCollector` + `AccountCheck` CREATE_FAILED (401) | Caused by `****` in access key param (NoEcho masking). Fixed by injecting real key from `-k` flag in Phase 3 |
| Stack rollback leaves ROLLBACK_COMPLETE state | Script detects this and instructs user to delete the failed stack before retrying with `--resume` |

---

## Phase 10: Verify Deployment

### What it does
1. Confirms all stack resources are in `CREATE_COMPLETE`
2. Finds the AWSO collector via Sumo API (paginated search for `aws-observability*` prefix)
3. Lists sources on the collector
4. Confirms 5/5 sources are alive (alb-logs, classic-lb-logs, cloudtrail-logs, cloudwatch-metrics, kinesis-firehose-cloudwatch-logs)

### Shared helper: `find_awso_collector()`
Paginated collector lookup. Reads `Section2aAccountAlias` from `STACK_JSON`:
- **If alias available**: matches exactly on `aws-observability-{alias}-{AccountId}` — precise, no false positives
- **If alias unavailable**: falls back to `startswith("aws-observability")` and `endswith("-{AccountId}")`

Sets `COLLECTOR_ID` and `COLLECTOR_NAME` globals. Used by Phase 2, Phase 10, and Phase 11 (fallback).

---

## Phase 11: Patch Source Role ARNs

### What it does
After v3.0.0 deploys, existing sources still reference the old v2.x IAM role ARN (which was deleted with the old stack). This phase:

1. Gets the new role ARN from CloudFormation:
   - `list-stack-resources` on `NEW_STACK_NAME` → find `CreateCommonResources` nested stack
   - `describe-stack-resource` on nested stack → get `SumoLogicSourceRole` physical ID
   - Build ARN: `arn:aws:iam::<ACCOUNT_ID>:role/<physical_id>`
2. Gets the collector ID:
   - **Primary**: `describe-stack-resource` on `CreateCommonResources` → `SumoLogicHostedCollector.PhysicalResourceId` — the authoritative collector created by the new stack
   - **Fallback**: load new stack into `STACK_JSON`, call `find_awso_collector()` (alias-based exact match)
3. Lists all sources on the collector
4. For each source with a stale roleARN:
   - `GET /collectors/{id}/sources/{source_id}` with `-D` to capture ETag
   - `jq` patch: update `.source.thirdPartyRef.resources[].authentication.roleARN`
   - `PUT` with `If-Match: <etag>` header
5. Reports count of patched sources

### Why get collector ID from CF stack (not name search)
The new stack's `SumoLogicHostedCollector` physical resource ID is the authoritative source — it's the exact collector the stack created. Name-based search could match a different collector if multiple `aws-observability-*` collectors exist for the same account.

### Design Decisions
- **GET full body → patch → PUT**: Sumo API requires full source object on PUT
- **ETag for optimistic concurrency**: Required by Sumo API
- **Only patch where roleARN doesn't match**: Idempotent, safe to re-run
- **Log but don't fail on individual source failure**: One source failing shouldn't abort the migration

### Standalone mode
`--patch-roles-only` flag: skips all migration phases, only runs validate + patch + report. Useful for fixing stale roleARNs on existing deployments without re-running the full migration.

---

## Phase 12: Report

### What it does
Prints a summary of the migration including:
- Source and target versions
- Stack name, region, deployment
- Captured bucket names
- FERs renamed count
- Sources patched count
- Log file location
- Cleanup command to resume if needed

---

## Script Flags & Modes

### Required Flags

| Flag | Purpose | Example |
|------|---------|---------|
| `-d DEPLOYMENT` | Sumo Logic deployment region | `kr`, `us1`, `us2`, `eu`, `au`, `ca`, `ch`, `de`, `fed`, `jp` |
| `-i ACCESS_ID` | Sumo Logic access ID | `suYXzI02B9l4h3` |
| `-s STACK_NAME` | Name of the existing v2.x CloudFormation stack | `awso-production-v215` |
| `-r REGION` | AWS region where the stack is deployed | `us-west-2` |
| `-o ORG_ID` | Sumo Logic organization ID (used as IAM external ID) | `0000000000009CFA0A` |

### Optional Flags

| Flag | Purpose | Default | When to use |
|------|---------|---------|-------------|
| `-k ACCESS_KEY` | Sumo Logic access key | **Prompted interactively** (hidden input, no echo) if omitted | Omit to avoid key appearing in shell history |
| `-n NEW_STACK_NAME` | Name for the new v3.0.0 stack | Same as source | When you want the new stack to have a different name |
| `-v VERSION` | Source version override | Auto-detected | When auto-detection fails or you want to be explicit (e.g. `-v 2.14`) |
| `--install-apps Yes/No` | Whether to install Sumo observability apps | `Yes` | Use `No` if deploying to a clean org where Sumo fields don't exist yet |
| `--resume` | Skip phases 2–5; optionally run Phase 6 if old stack still exists | Off | When Phase 9 deploy failed and you need to retry; or when old stack is stuck in DELETE_FAILED |
| `--params-file FILE` | Path to saved params JSON | Required with `--resume` | Points to the params file saved by a previous Phase 3 run |
| `--patch-roles-only` | Only run roleARN patching (requires `-n NEW_STACK_NAME`) | Off | When v3.0.0 is already deployed but sources have stale roleARNs |
| `-p PROFILE` | AWS CLI profile name | `default` | When using named AWS profiles |
| `--dry-run` | Validate and map params without modifying anything | Off | Preview migration plan without executing |

### Execution Modes

#### 1. Full Migration (default)
**When**: First time migrating a v2.x stack to v3.0.0.

```bash
# Access key prompted interactively (recommended — keeps key out of shell history)
./MigrateAWSOStackToV300.sh \
  -d kr -i suYXzI02B9l4h3 \
  -o 0000000000009CFA0A \
  -s awso-production-v215 -r us-west-2 \
  -n awso-production-v300 --install-apps Yes
```

Runs all 12 phases in sequence. The script saves a params file automatically — if the deploy fails, retry with `--resume`.

#### 2. Dry Run (`--dry-run`)
**When**: Preview the mapped v3.0.0 parameters without making any changes.

```bash
./MigrateAWSOStackToV300.sh \
  -d kr -i suYXzI02B9l4h3 \
  -o 0000000000009CFA0A \
  -s awso-production-v215 -r us-west-2 \
  --dry-run
```

Runs Phases 1–3 (validate, capture, map params) and prints the mapped parameter list, then exits. No stack updates, deletions, or Sumo changes are made.

#### 3. Resume / Continue Mode (`--resume`)

**When to use**:
- Phase 9 (deploy) failed — stack rolled back or errored
- The v2.x stack is already deleted and FERs are already renamed
- Old stack is stuck in `DELETE_FAILED` and needs to be cleaned up before Phase 7+

**How `--resume` handles the old stack** (when `-s STACK_NAME` is also provided):

| Old stack status | Action taken |
|---|---|
| Doesn't exist / `DELETE_COMPLETE` | Skip Phase 6; check for orphaned nested stacks |
| `DELETE_FAILED` | Run `phase_delete_retain_only` then continue to Phase 7 |
| `DELETE_IN_PROGRESS` | Wait for deletion to complete then continue to Phase 7 |
| `UPDATE_COMPLETE` / `CREATE_COMPLETE` | Run full `phase_delete` then continue to Phase 7 |

After any of the above, `cleanup_orphaned_nested_stacks` runs to delete any orphaned nested stacks (e.g. `CreateCommonResources`) left behind by a previous `--retain-resources` run.

**How the params file works**:
- Phase 3 saves: `migration_params_<NEW_STACK_NAME>_<YYYYMMDD>_<HHMMSS>.json`
- On failure the script prints the exact resume command to copy/paste

**How to resume**:
```bash
# Step 1: Delete the failed/rolled-back v3.0.0 stack if in ROLLBACK_COMPLETE
aws cloudformation delete-stack --stack-name awso-production-v300 --region us-west-2
aws cloudformation wait stack-delete-complete --stack-name awso-production-v300 --region us-west-2

# Step 2: Re-run with --resume (add -s if old stack may still need deletion)
./MigrateAWSOStackToV300.sh \
  -d kr -i suYXzI02B9l4h3 -k <key> \
  -s awso-production-v215 -r us-west-2 \
  -n awso-production-v300 \
  --resume --params-file ./migration_params_awso-production-v300_20260706_180418.json
```

**What `--resume` skips**: Phases 2–5 (capture, map, confirm, protect)
**What `--resume` runs**: Phase 1 (creds only), Phase 6 (if old stack still exists), Phase 7–12

**Common resume scenarios**:

| Failure | Fix before resuming |
|---------|-------------------|
| `ROLLBACK_COMPLETE` (bad params) | Delete rolled-back stack, fix params file |
| `ROLLBACK_COMPLETE` (access key `****`) | Delete rolled-back stack — script auto-injects real key from `-k` flag |
| `S3 error: Access Denied` (bad template URL) | Delete rolled-back stack — correct URL is hardcoded |
| Old stack stuck in `DELETE_FAILED` | Pass `-s <old-stack>` with `--resume` — script handles it automatically |
| Orphaned nested stack remaining | Pass `-s <old-stack>` with `--resume` — `cleanup_orphaned_nested_stacks` handles it |
| Timeout during create | Check stack status first; if failed, delete and resume |

#### 4. Patch-Only Mode (`--patch-roles-only`)
**When**: v3.0.0 is already deployed and working, but sources still point to the old/deleted IAM role ARN.

```bash
./MigrateAWSOStackToV300.sh \
  -d kr -i suYXzI02B9l4h3 \
  -o 0000000000009CFA0A \
  -r us-west-2 \
  -n awso-production-v300 \
  --patch-roles-only
```

Requires `-n NEW_STACK_NAME` (the deployed v3.0.0 stack name — not `-s`). Only runs: validate → patch roles → report.

### Decision Flowchart

```
Is v2.x stack still running?
├── YES → Use full migration (default mode)
└── NO → Is v3.0.0 stack deployed?
    ├── NO (failed/rolled back) → Delete failed stack, then use --resume
    └── YES (CREATE_COMPLETE)
        └── Are sources working?
            ├── YES → Nothing to do
            └── NO (stale roleARN) → Use --patch-roles-only
```

---

## Key Helpers

### Logging functions
All log output includes a `[YYYY-MM-DD HH:MM:SS]` timestamp:
```
[INFO]  [2026-09-01 14:32:05] AWS credentials: OK
[WARN]  [2026-09-01 14:32:07] Stack in ROLLBACK_COMPLETE — will delete first
[ERROR] [2026-09-01 14:32:09] Missing required arguments: -d DEPLOYMENT
```
Implemented via a `_ts()` helper (`date '+%Y-%m-%d %H:%M:%S'`) called inline in `log_info`, `log_warn`, `log_error`, and `log_phase`. Log output is also written to a file (ANSI codes stripped) via `_log_to_file()`.

### `aws_cmd()`
Safe AWS CLI wrapper that handles PATH issues and argument quoting:
```bash
aws_cmd() {
    /bin/zsh -l -c 'aws --profile "$1" "${@:2}"' _ "${AWS_PROFILE}" "$@"
}
```

### `sumo_get()` / `sumo_get_with_etag()` / `sumo_put_if_match()`
Curl wrappers for Sumo Logic API with:
- Basic auth (`ACCESS_ID:ACCESS_KEY`)
- `--max-redirs 0` (Sumo redirects based on deployment)
- ETag capture/send for optimistic concurrency

### `find_awso_collector()`
Paginated collector search (1000 per page). Reads `Section2aAccountAlias` from `STACK_JSON`:
- If alias available: exact match on `aws-observability-{alias}-{AccountId}`
- Otherwise: `startswith("aws-observability")` + `endswith("-{AccountId}")`

Sets `COLLECTOR_ID` and `COLLECTOR_NAME` globals.

### `phase_delete_retain_only()`
Deletes a `DELETE_FAILED` stack using `--retain-resources` with only the specific blocked logical IDs (filtering out the stack's own name). After the main stack is deleted, iterates any retained nested stacks and deletes them the same way.

### `cleanup_orphaned_nested_stacks(parent)`
Lists all `DELETE_FAILED` stacks prefixed `{parent}-` via `list-stacks`, then deletes each with `--retain-resources` for its own blocked resources. Used by `--resume` when the main stack is already gone.

### `wait_for_stack()`
Polls CloudFormation stack status at `POLL_INTERVAL` (30s) until terminal state or timeout.

---

## Constants

```bash
V300_TEMPLATE_URL="https://sumologic-appdev-aws-sam-apps.s3.us-east-1.amazonaws.com/aws-observability-versions/v3.0.0/templates/sumologic_observability.master.template.yaml"
UPDATE_TIMEOUT=1800   # 30 min  (Phase 5 stack update)
DELETE_TIMEOUT=1800   # 30 min  (Phase 6 stack deletion)
CREATE_TIMEOUT=2700   # 45 min  (Phase 9 stack creation)
POLL_INTERVAL=30      # seconds
AWSO_FER_COUNT=17     # expected FERs to rename
```

---

## Validated Migration Run (2026-07-06)

**Source**: `awso-migration-v215` (v2.15, us-west-2, KR org)
**Target**: `awso-migration-v300`

| Phase | Result | Duration |
|-------|--------|----------|
| 1. Validate | OK (account 692859911666) | <1s |
| 2. Capture | Collector + 5 sources + `aws-observability-logs-4bc184f0` (from Sumo sources) | <1s |
| 3. Map Params | 32 parameters mapped, saved to file | <1s |
| 4. Confirm | User approved (stack, sources, buckets, v3.0.0 params, destructive actions shown) | ~10s |
| 5. Protect | RemoveOnDeleteStack already false | <1s |
| 6. Delete | DELETE_FAILED → retain-resources → nested stack cleanup | ~7 min |
| 7. FER Cleanup | 17/17 renamed and disabled | ~10s |
| 8. Metric Rules | 4/4 deleted | <5s |
| 9. Deploy | CREATE_COMPLETE | ~5 min |
| 10. Verify | 5/5 sources alive | <5s |
| 11. Patch Roles | 4 sources patched | ~5s |
| 12. Report | Summary printed | <1s |
| **Total** | | **~13 min** |

---

## Known Limitations

1. **No rollback**: If v3.0.0 deploy fails, the v2.x stack is already deleted. Use `--resume` to retry.
2. **Single region**: Script handles one region at a time. Multi-region deployments need one run per region.
3. **Apps may fail on clean org**: If Sumo fields don't exist, FER creation fails. Deploy with `--install-apps No` first, then update stack.
4. **CloudWatch Metrics source type change**: v2.x may use "CloudWatch Metrics Source" while v3.0.0 only supports "Kinesis Firehose Metrics Source". The script carries over whatever the user had — if they had CW Metrics, they'll get CW Metrics in v3.0.0 (if supported by template).
5. **Retained S3 bucket requires manual cleanup**: After migration, the old `CommonS3Bucket` remains in AWS (intentionally retained). It must be emptied and deleted manually once v3.0.0 is confirmed healthy, or left in place for v3.0.0 to continue reading from.
