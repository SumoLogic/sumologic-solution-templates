# AWSO v3.0.0 — StackSet Migration Script Design Document

**Script**: `scripts/MigrateAWSOStackSetToV300.sh`
**Supported source versions**: v2.12, v2.13, v2.14, v2.15 deployed via AWS StackSets
**Target version**: v3.0.0
**Companion script**: `scripts/MigrateAWSOStackToV300.sh` (single-stack, single-region migration)

---

## When to Use This Script

`MigrateAWSOStackToV300.sh` migrates a single CloudFormation stack in one account and one region.

Use `MigrateAWSOStackSetToV300.sh` when AWSO was deployed via a CloudFormation StackSet — typically through AWS Control Tower or manual StackSet management — across multiple accounts and/or multiple regions. This script:

- Enumerates every stack instance (account × region) from the StackSet
- Lets the user optionally select a subset of instances to migrate
- Resolves each account's true `Section2aAccountAlias` from the deployed stack's parameters
- Captures per-region S3 bucket names (ALB, CloudTrail, ELB) from each deployed stack
- Runs FER and metric-rule cleanup once at the Sumo org level (not once per account)
- Updates the StackSet in-place (no delete+recreate) and creates instances one per (account, region) to carry unique aliases and bucket overrides
- Patches Sumo source `roleARN`s by assuming the execution role in each member account

---

## Prerequisites (Phase 0)

The script assumes:
- A v2.x StackSet named `SUMO-LOGIC-AWS-OBSERVABILITY` (or overridden via `--stackset-name`) is deployed and has no running operations
- The management account's IAM principal has `cloudformation:Describe*`, `cloudformation:List*`, `cloudformation:UpdateStackSet`, `cloudformation:CreateStackInstances`, `cloudformation:DeleteStackInstances`, `cloudformation:UpdateStackInstances`, `sts:GetCallerIdentity`
- The execution role (e.g. `AWSControlTowerExecution`) exists in each member account and can be assumed from the management account
- Sumo Logic credentials have admin access (to rename FERs, delete metric rules, and patch sources)
- `bash`, `aws` CLI v2, `jq`, and `curl` are available

---

## Architecture Overview

```
Phase 0:  (Assumption)    → StackSet is deployed and all instances are CURRENT
Phase 1:  Validate        → Credentials, StackSet exists, no running operation
Phase 2:  Enumerate       → list-stack-instances → per-instance version detection (get-template); account/region map; instance selection with version table; bucket + alias capture
Phase 3:  Map Params      → v2.x StackSet base params → v3.0.0 format
Phase 4:  Confirm         → Show accounts, regions, mapped params; user approval
Phase 5:  Update ROD      → update-stack-instances on selected instances only (per account) with RemoveOnDeleteStack=false
Phase 6:  Delete Instances → delete-stack-instances + async operation poll + auto-cleanup on failure
Phase 8:  FER Cleanup     → Rename+disable 17 AWSO FERs (org-level, runs once)
Phase 9:  Metric Rules    → Delete 4 AWSO metric rules (org-level, runs once)
Phase 10: Create/Update StackSet → create-stack-set (when -n provided or select mode) or update-stack-set in-place (all mode, no -n)
Phase 11: Create Instances → One create-stack-instances per (account, region) with alias + bucket overrides
Phase 12: Verify          → list-stack-instances — all CURRENT/SUCCEEDED
Phase 13: Patch Roles     → Assume execution role per account; patch Sumo source roleARNs per region
Phase 14: Report          → Summary: accounts, regions, FERs renamed, sources patched
```

> **Note on Phase 7**: An earlier design included a separate "Delete StackSet" phase. This was removed. Phase 10 either updates the existing StackSet in-place (`all` mode + no `-n`) or creates a new StackSet (`-n` provided, or `select` mode). Phase numbers 8–14 were kept as-is to preserve resume compatibility with existing state files.

---

## Phase 1: Validate Prerequisites

### What it does
- Validates Sumo Logic credentials via `GET /api/v1/account/status`
- Validates AWS credentials via `sts get-caller-identity`; captures `MGMT_ACCOUNT_ID`
- Confirms the StackSet exists via `describe-stack-set --region HOME_REGION`
- Auto-detects `AdministrationRoleARN` and `ExecutionRoleName` from the existing StackSet if not provided via flags
- Checks that no StackSet operation is currently `RUNNING`

### Key differences from single-stack validate
- Source version detection moved to Phase 2 (per-instance via `get-template`); if `-v` is provided, it is validated here against supported versions (v2.12–v2.15)
- Admin and execution role ARNs are read from the StackSet's own metadata

### Issues and design decisions

| Issue | Resolution |
|-------|------------|
| `aws` not in PATH on macOS | Wrapped all AWS calls in `aws_cmd()` which uses `/bin/zsh -l -c` |
| Running operation not always obvious | Added `list-stack-set-operations` + filter `Status == RUNNING`; exits with clear error and operation ID |
| Silent script exit after "Execution role name (auto-detected)" | `grep -oE 'v2\...` exits with code 1 under `set -euo pipefail` when no match — fixed by adding `|| true` to grep pipeline |

---

## Phase 2: Enumerate Stack Instances

### What it does
1. Paginates `list-stack-instances` for the StackSet (1000 per page)
2. For each instance, extracts `Account`, `Region`, and `StackId`; calls `aws cloudformation get-template --stack-name <StackId> --region <Region>` to read the template's `Description` field and detect the deployed version (e.g. `v2.15.0`). Marks each instance with its detected version (e.g. `v2.15`, `v3.0.0`, `unknown`).
3. Builds two runtime globals:
   - `INSTANCES_JSON`: array of `{account, region, alias, version}` — used by phases 5, 6, 11, and 13
   - `ACCOUNT_ALIAS_MAP`: `{account: alias}` — alias is a placeholder at this point
3a. Sets `SOURCE_VERSION` from the first instance whose version is in the supported list (v2.12–v2.15), unless already set via `-v`.
4. Calls `_select_instances()` — lets the user pick all instances or a subset interactively
5. For each unique account, calls `_capture_buckets_for_account()` which:
   - Assumes the execution role in the member account
   - Reads the actual `Section2aAccountAlias` from `describe-stacks` on the deployed stack and updates `ACCOUNT_ALIAS_MAP`
   - Captures per-region S3 bucket names (ALB, CloudTrail, ELB) from stack parameters or `CommonS3Bucket` physical resource ID
   - Stores results in `ACCOUNT_BUCKET_MAP` keyed by `account/region`

### Why alias is resolved from the deployed stack (not ParameterOverrides)
`Section2aAccountAlias` is sometimes a StackSet **base parameter** (not a per-instance override), so `ParameterOverrides` on `list-stack-instances` may be empty. The only reliable source is `describe-stacks` on the actual deployed stack, using cross-account credentials.

### Why S3 bucket names are captured per region
Each region's `CreateCommonResources` nested stack creates its own `CommonS3Bucket`. A single account deployed in N regions has N different bucket names. `ACCOUNT_BUCKET_MAP` is keyed by `"account/region"` to hold distinct values per region.

---

## Instance Selection (`_select_instances`)

Called at the end of Phase 2 before bucket capture. Presents an interactive prompt:

```
  Migrate all instances or select specific ones? (all/select) [all]:
```

This sets `MIGRATION_MODE` (`all` or `select`). Combined with whether `-n` was provided, four cases arise:

| Mode | `-n` passed | Target StackSet | Phase 10 action |
|------|-------------|-----------------|-----------------|
| `all` | no | existing `STACKSET_NAME` | `update-stack-set` in-place |
| `all` | yes | `NEW_STACKSET_NAME` | `create-stack-set` |
| `select` | yes | `NEW_STACKSET_NAME` | `create-stack-set` |
| `select` | no | `sumologic-awso-v300` (default) | `create-stack-set` |

**Version table — `all` mode** (no Include? column):

```
  #     Account           Region          Version
  ----  ----------------  --------------  ---------
  1     285573938264      us-east-1       v3.0.0 (Migrated)
  2     285573938264      us-west-2       v2.15.0
  3     111122223333      eu-west-1       v2.10.0 (Unsupported)
```

**Version table — `select` mode** (Include? column with [y/n] prompts):

```
  #     Account           Region          Version       Include?
  ----  ----------------  --------------  ------------  --------
  1     285573938264      us-east-1       v3.0.0        Migrated
  2     285573938264      us-west-2       v2.15.0       [y/n]: y → Yes
  3     111122223333      eu-west-1       v2.10.0       Unsupported
  4     111122223333      us-east-1       unknown       Unsupported
```

**Per-instance routing rules:**

| Instance version | Behavior |
|---|---|
| `v3.x` | Auto-excluded — shown as `Migrated` |
| `v2.12`–`v2.15` (supported) | Auto-included (`all` mode) or prompted `[y/n]` (`select` mode) |
| Any other version | Auto-excluded — shown as `Unsupported` with `[WARN]` log |
| `unknown` (template unreadable) | Auto-excluded — shown as `Unsupported` with `[WARN]` log |

- If 0 eligible instances remain after filtering: exits 0 with `"No instances to migrate."`
- After selection, `INSTANCES_JSON` and `ACCOUNT_ALIAS_MAP` are pruned to only selected instances
- On `--resume`: skipped — instance list and `MIGRATION_MODE` are loaded from the state file

---

## Phase 3: Map Parameters

### What it does
Fetches the StackSet's base parameters and passes them through the same `map_params_v215()` jq filter used by `MigrateAWSOStackToV300.sh` (displayed as "Phase 3: Map Parameters v${SOURCE_VERSION} → v3.0.0" at runtime):

1. **Removes**: `Section10aAppInstallLocation`, `Section10bShare` (not in v3.0.0)
2. **Renames**:
   - `Section7aLambdaCreateCloudWatchLogsSourceOptions` → `Section7aCreateCloudWatchLogsSourceOptions`
   - `Section7bLambdaCloudWatchLogsSourceUrl` → `Section7bCloudWatchLogsSourceUrl`
   - `Section9a–9e` → `Section8a–8e` (ELB section renumbered)
3. **Overrides**:
   - `Section1eSumoLogicResourceRemoveOnDeleteStack` → `false`
   - `Section1bSumoLogicAccessID` → injected from `-i` flag
   - `Section1cSumoLogicAccessKey` → injected from `-k` flag
   - `Section3aInstallObservabilityApps` → from `--install-apps` flag (default: `No`)
   - Source URL params → cleared (forces v3.0.0 to create new sources)

---

## Phase 4: Confirm

### What it does
Displays a full summary and requires the user to type `yes` to proceed:
- Old and new StackSet names
- v3.0.0 template URL
- All instances: account / region / alias
- Mapped shared base parameters (excludes per-account fields)
- Per-account/region table: alias, ALB bucket, CloudTrail bucket, ELB bucket

### Dry-run mode
`--dry-run` prints the enumeration, parameter mapping, and per-account override table, then exits 0. No AWS or Sumo changes are made.

### Resume mode
Confirmation is skipped when resuming.

---

## Phase 5: Update RemoveOnDeleteStack=false

### What it does
For each unique account in the **selected** `INSTANCES_JSON`, issues one `update-stack-instances` call with **only that account's selected regions** and `Section1eSumoLogicResourceRemoveOnDeleteStack=false`. Polls until `SUCCEEDED` (timeout: 1800s per account). Instances that were skipped in Phase 2 (Migrated / Unsupported) are not touched.

### Why one call per account (not one call for all)
A single call with all accounts × all regions creates a cross-product. Non-existent (account, region) pairs are silently skipped, and the operation can report `SUCCEEDED` before all real instances are updated. Per-account calls with exact regions eliminate this risk.

### Why this is critical
If `RemoveOnDeleteStack=true` at the time instances are deleted, the Sumo Lambda custom resource inside each stack will delete the Sumo collector and all sources during stack teardown.

### Why CLI credentials are injected
The `update-stack-instances` call in this phase also overrides `Section1bSumoLogicAccessID` and `Section1cSumoLogicAccessKey` with the CLI `-i`/`-k` values. The stored stack parameter for `AccessKey` is masked (`****`), and those credentials may have expired since the v2.x StackSet was deployed. Injecting fresh credentials ensures the Lambda custom resource can authenticate to Sumo Logic when it processes the stack update.

---

## Phase 6: Delete Stack Instances

### What it does
Issues `delete-stack-instances` across all accounts and regions with `--no-retain-stacks`. Polls until `SUCCEEDED` or error (timeout: 3600s).

On non-SUCCEEDED result, calls `_cleanup_failed_delete_instances()` for automatic remediation instead of immediately exiting.

### `--no-retain-stacks` vs `--retain-stacks`
`--no-retain-stacks` deletes the actual CloudFormation stacks in each account/region — not just the StackSet's bookkeeping entries. The Sumo collector and sources are preserved because `RemoveOnDeleteStack=false` was set in Phase 5.

### Automatic cleanup (`_cleanup_failed_delete_instances`)

When `delete-stack-instances` ends in a non-SUCCEEDED state, the helper separates instances into two categories:

**FAILED instances** (stack stuck in DELETE_FAILED — typically a non-empty S3 bucket):
1. Assumes execution role in the member account
2. Calls `_delete_stack_with_retain()`: finds `DELETE_FAILED` logical resource IDs in nested stacks, deletes nested stacks with `--retain-resources`, then parent stack with `--retain-resources`
3. Removes the instance from the StackSet with `delete-stack-instances --retain-stacks`

**CANCELLED instances** (stack untouched — cancelled due to failure tolerance exceeded):
- Retries **per account** with only that account's cancelled regions and `--no-retain-stacks`
- Per-account calls avoid the "Regions list cannot have duplicate entries" API error that occurs when the same region appears for multiple accounts in a flat list
- Recursively calls itself if the retry also has failures

---

## Phase 8: FER Cleanup (org-level, runs once)

### What it does
Renames 17 AWSO FERs to `v215_backup_<name>` and disables them.

The 17 AWSO FER names:
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

### INSTALL_APPS=No skip
When `--install-apps No` is passed, this phase is skipped automatically. If v3.0.0 is deployed without apps (`Section3aInstallObservabilityApps=No`), it will not create FERs — so there is no quota conflict and cleanup is unnecessary. The phase is marked done to allow resume to continue past it.

### Quota-too-low path
If the remaining FER quota is below 17, the script prints the list of FERs that need manual cleanup and exits with code 2.

### Idempotency
Phase 8 checks if `v215_backup_<name>` already exists before each rename; skips if found.

---

## Phase 9: Metric Rules Cleanup (org-level, runs once)

### INSTALL_APPS=No skip
When `--install-apps No` is passed, this phase is skipped automatically (same reasoning as Phase 8 — no metric rules will be created by v3.0.0).

Deletes 4 AWSO metric rules:
```
AwsObservabilityRDSClusterMetricsEntityRule
AwsObservabilityRDSInstanceMetricsEntityRule
AwsObservabilityNLBMetricsEntityRule
AwsObservabilityApiGatewayApiNameMetricsEntityRule
```

`404` responses are treated as success. `403` responses log a warning but do not abort.

---

## Phase 10: Create or Update StackSet

Branches on whether `NEW_STACKSET_NAME` is set (see the four-case matrix in Instance Selection):

### Path A — `all` mode + no `-n` → `update-stack-set` in-place

All instances were deleted in Phase 6, so `update-stack-set` without `--accounts`/`--regions` scope is a pure definition update — no stacks exist to propagate to. Polls via `wait_for_stackset_operation` (timeout: 600s).

**Why not scope with --accounts/--regions**: AWS throws `StackInstanceNotFoundException` when targeting accounts/regions that have no instances. Since all instances were deleted in Phase 6, scoping to them causes this error.

**Why update instead of delete + create**: Deleting a StackSet requires all instances to be gone first (`StackSetNotEmptyException` otherwise). Updating in-place preserves IAM role configuration and avoids name conflicts.

### Path B — `-n` provided, or `select` mode → `create-stack-set`

Creates a brand-new StackSet with `NEW_STACKSET_NAME`, the v3.0.0 template URL, and mapped base params. The original `STACKSET_NAME` StackSet is left untouched — any non-selected instances remain there at v2.x.

`create-stack-set` does not return an `OperationId` (unlike `update-stack-set`), so no polling is needed; the call is synchronous.

---

## Phase 11: Create Stack Instances (one call per account/region)

The **target StackSet** is `NEW_STACKSET_NAME` if set, otherwise `STACKSET_NAME`.

For each entry in `INSTANCES_JSON` (one entry per account/region pair):
1. Looks up alias from `ACCOUNT_ALIAS_MAP`
2. Looks up bucket names from `ACCOUNT_BUCKET_MAP["account/region"]`
3. Builds `--parameter-overrides` with `Section2aAccountAlias` always set; bucket params (`Section5d`, `Section6c`, `Section8d`) added only if non-empty
4. Issues `create-stack-instances --stack-set-name <target> --accounts <account> --regions <region>`
5. Polls via `wait_for_stackset_operation` (timeout: 5400s)
6. On failure: records `account/region` in `FAILED_INSTANCES`, saves state, continues to next instance

### Why one call per (account, region) — not one call per account
Each region can have different S3 bucket names (one `CommonS3Bucket` per region). A single `create-stack-instances` call for an account covering all its regions cannot carry distinct bucket overrides per region. One call per region allows full per-region parameter control.

---

## Phase 12: Verify

Paginates `list-stack-instances` on the **target StackSet** (`NEW_STACKSET_NAME` if set, otherwise `STACKSET_NAME`) and counts instances in each status. Logs a warning (does not fail) if any instance is not `CURRENT` or `SUCCEEDED`.

---

## Phase 13: Patch Source Role ARNs (per account/region)

For each unique account:
1. Assumes the execution role in the member account (`arn:aws:iam::<account>:role/<EXECUTION_ROLE_NAME>`)
2. For each region:
   - Finds the deployed stack via `list-stack-instances` (called with **management account credentials** — this is a StackSet control-plane API not accessible with member account creds)
   - Locates `CreateCommonResources` nested stack via `list-stack-resources` (cross-account creds)
   - Reads `SumoLogicSourceRole.PhysicalResourceId` via `describe-stack-resource` (cross-account creds)
   - Finds the Sumo collector: exact name match on `aws-observability-<alias>-<account>`, then paginated fallback matching both `startswith("aws-observability")` AND `endswith("-<account>")`
   - Filters stale sources: those whose name **contains the current region** (avoids cross-region patching), have `thirdPartyRef.resources`, and have a non-empty `roleARN` ≠ the new ARN
   - Patches each stale source via `sumo_get_with_etag` + `sumo_put_if_match`

### Why `list-stack-instances` uses management account credentials
`list-stack-instances` is a StackSet management API owned by the management account. Member account credentials (from `sts assume-role`) do not have access to this API. All other calls that query resources within the member account use cross-account credentials.

### Why sources are filtered by region name
Each region's `SumoLogicSourceRole` only has IAM permissions for that region's S3 buckets. Applying `us-east-1`'s role ARN to a `us-east-2` source would be rejected by the Sumo API (HTTP 400). Filtering by `(.name | contains($region))` ensures each region's sources are patched only with that region's role ARN.

### Collector ID reconciliation (mirrors MigrateAWSOStackToV300.sh)
When both CF (`SumoLogicHostedCollector.PhysicalResourceId`) and the Sumo API return a collector ID and they disagree, the script prompts the user interactively:
```
  1) Use CF stack value: <cf_id>
  2) Use Sumo API value: <api_id>
  3) Enter manually
  4) Abort
```

### Standalone mode
`--patch-roles-only` flag: loads state from `--state-file`, skips directly to Phase 13, then reports.

---

## Phase 14: Report

Prints a summary: old and new StackSet names, home region, template version, account/region/instance counts, FERs renamed, sources patched, log file path.

---

## State File (JSON) and Resume Support

### Structure
```json
{
  "stackset_name":       "SUMO-LOGIC-AWS-OBSERVABILITY",
  "new_stackset_name":   "SUMO-LOGIC-AWS-OBSERVABILITY-V300",
  "migration_mode":      "select",
  "source_version":      "2.15",
  "home_region":         "us-east-1",
  "instances":           [{"account": "222222222222", "region": "us-east-1", "alias": "prod1", "version": "v2.15.0"}],
  "v300_base_params":    [{"ParameterKey": "...", "ParameterValue": "..."}],
  "account_alias_map":   {"222222222222": "prod1", "333333333333": "dev1"},
  "account_bucket_map":  {
    "222222222222/us-east-1": {"alb": "bucket-a", "cloudtrail": "bucket-b", "elb": "bucket-c"},
    "222222222222/eu-west-1": {"alb": "bucket-d", "cloudtrail": "bucket-e", "elb": "bucket-f"}
  },
  "phases_completed":    ["validate", "enumerate", "map_params", "confirm", "update_rod", "delete_instances", "fer_cleanup", "metric_rules"],
  "failed_instances":    [],
  "admin_role_arn":      "arn:aws:iam::111111111111:role/AWSCloudFormationStackSetAdministrationRole",
  "execution_role_name": "AWSCloudFormationStackSetExecutionRole"
}
```

`new_stackset_name` is empty string when `all` mode without `-n`. `migration_mode` defaults to `"all"` on load if absent (backwards-compatible with older state files).

### Phase tokens
Each phase writes its name to `phases_completed` on success. The `_phase_done "<name>"` guard at the top of each phase function returns early if the token is present — making every phase idempotent on resume.

### Auto-resume
If `--state-file` points to an existing file and `--resume` was not explicitly passed, the script automatically enables resume mode and logs a warning. This prevents accidentally overwriting a valid state file with empty data from a fresh run.

---

## Script Flags & Modes

### Required Flags

| Flag | Purpose | Example |
|------|---------|---------|
| `-d DEPLOYMENT` | Sumo Logic deployment region | `kr`, `us1`, `us2`, `eu`, `au`, `ca`, `ch`, `de`, `fed`, `jp` |
| `-i ACCESS_ID` | Sumo Logic access ID | `suYXzI02B9l4h3` |
| `-o ORG_ID` | Sumo Logic organization ID | `0000000000009CFA0A` |
| `-r REGION` | AWS home region (where the StackSet is registered) | `us-east-1` |

### Optional Flags

| Flag | Purpose | Default |
|------|---------|---------|
| `-k ACCESS_KEY` | Sumo Logic access key | **Prompted interactively** (hidden input, no echo) if omitted — avoids key appearing in shell history |
| `-s, --stackset-name NAME` | Name of the existing v2.x StackSet | `SUMO-LOGIC-AWS-OBSERVABILITY` |
| `-n, --new-stackset-name NAME` | New StackSet name for v3.0.0 (triggers create-stack-set in Phase 10) | `sumologic-awso-v300` in select mode; not used in all+no-n mode |
| `-v SOURCE_VERSION` | Source version override | Auto-detected from instance template Description in Phase 2 |
| `--admin-role-arn ARN` | StackSet administration role ARN | Auto-detected |
| `--execution-role NAME` | StackSet execution role name | Auto-detected |
| `-p PROFILE` | AWS CLI profile | `default` |
| `--install-apps YES/NO` | Install Sumo observability apps in v3.0.0 | `No` |
| `--concurrency N` | MaxConcurrentCount for StackSet operations | `1` |
| `--failure-tolerance N` | FailureToleranceCount for StackSet operations | `0` |
| `--dry-run` | Enumerate and map params; exit without changes | Off |
| `--resume` | Resume from saved state file | Off (auto-enabled if state file exists) |
| `--state-file PATH` | Path to state JSON | Auto-generated timestamped filename |
| `--from-phase PHASE` | Reset progress to re-run from this phase; implies `--resume` | — |
| `--patch-roles-only` | Skip directly to Phase 13; implies `--resume` | Off |
| `-h, --help` | Show help text | — |

### Examples

```bash
# all mode, no -n: update existing StackSet in-place (access key prompted interactively)
./MigrateAWSOStackSetToV300.sh \
    -d us2 -i suYXzI02B9l4h3 -o 0000000000009CFA0A -r us-east-1
# → choose "all" at prompt → Phase 10: update-stack-set SUMO-LOGIC-AWS-OBSERVABILITY

# all mode, -n provided: create new StackSet for v3.0.0
./MigrateAWSOStackSetToV300.sh \
    -d us2 -i suYXzI02B9l4h3 -o 0000000000009CFA0A -r us-east-1 \
    -n MY-AWSO-STACKSET-V300
# → choose "all" at prompt → Phase 10: create-stack-set MY-AWSO-STACKSET-V300

# select mode, -n provided: select specific instances → create named StackSet
./MigrateAWSOStackSetToV300.sh \
    -d us2 -i suYXzI02B9l4h3 -o 0000000000009CFA0A -r us-east-1 \
    -n MY-AWSO-STACKSET-V300
# → choose "select" at prompt → [y/n] per instance → Phase 10: create-stack-set MY-AWSO-STACKSET-V300

# select mode, no -n: select specific instances → create default-named StackSet
./MigrateAWSOStackSetToV300.sh \
    -d us2 -i suYXzI02B9l4h3 -o 0000000000009CFA0A -r us-east-1
# → choose "select" at prompt → NEW_STACKSET_NAME defaults to "sumologic-awso-v300"

# Dry run — enumerate instances and map params; no changes made
./MigrateAWSOStackSetToV300.sh \
    -d us2 -i suYXzI02B9l4h3 -o 0000000000009CFA0A -r us-east-1 \
    --dry-run

# Resume from saved state (auto-detected when state file already exists)
./MigrateAWSOStackSetToV300.sh \
    -d us2 -i suYXzI02B9l4h3 -o 0000000000009CFA0A -r us-east-1 \
    --state-file ./awso_stackset_migration_20260828_110000.json

# Re-run from Phase 6 (delete_instances) onwards
./MigrateAWSOStackSetToV300.sh \
    -d us2 -i suYXzI02B9l4h3 -o 0000000000009CFA0A -r us-east-1 \
    --state-file ./awso_stackset_migration_20260828_110000.json \
    --from-phase delete_instances

# Patch source role ARNs only (Phase 13) — when v3.0.0 is already deployed
./MigrateAWSOStackSetToV300.sh \
    -d us2 -i suYXzI02B9l4h3 -o 0000000000009CFA0A -r us-east-1 \
    --state-file ./awso_stackset_migration_20260828_110000.json \
    --patch-roles-only
```

---

## Key Helpers

### Logging functions
All log output includes a `[YYYY-MM-DD HH:MM:SS]` timestamp:
```
[INFO]  [2026-09-01 14:32:05] Patching sources in account 285573938264...
[WARN]  [2026-09-01 14:32:07] Collector ID mismatch for account 285573938264!
[ERROR] [2026-09-01 14:32:09] Operation abc123: FAILED
```
Implemented via a `_ts()` helper (`date '+%Y-%m-%d %H:%M:%S'`) called inline in `log_info`, `log_warn`, `log_error`, and `log_phase`. Log output is also written to a file (ANSI codes stripped) via `_log_to_file()`.

| Helper | Purpose |
|--------|---------|
| `aws_cmd()` | macOS-safe AWS CLI wrapper using `/bin/zsh -l`; injects `--profile` |
| `wait_for_stackset_operation(name, op_id, timeout)` | Polls `describe-stack-set-operation` every 30s; logs per-instance failures to stderr on FAILED/STOPPED; returns status string on stdout |
| `sumo_get()` / `sumo_put()` / `sumo_get_with_etag()` / `sumo_put_if_match()` | curl wrappers with basic auth and ETag support |
| `map_params_v215(v2_params_json)` | jq filter; transforms v2.x base params to v3.0.0 format |
| `_select_instances()` | Prompts `all/select`; sets `MIGRATION_MODE` and defaults `NEW_STACKSET_NAME` if needed; shows version table; auto-excludes v3.x (Migrated) and unsupported/unknown (Unsupported); auto-includes eligible in `all` mode, prompts `[y/n]` in `select` mode |
| `_capture_buckets_for_account(account)` | Assumes execution role; resolves alias from deployed stack, reconciles collector ID with Sumo API (with mismatch prompt), captures per-region bucket names |
| `_cleanup_failed_delete_instances(op_id)` | Recovers FAILED (retain+delete) and CANCELLED (per-account retry) instances after a failed delete operation |
| `_delete_stack_with_retain(stack, region, creds)` | Cross-account delete of a stuck stack using `--retain-resources` |
| `_fetch_all_fers()` | Paginates `GET /api/v1/extractionRules?limit=1000` |
| `_save_state()` / `_load_state()` | Serialize/deserialize all runtime globals to/from JSON state file |
| `_phase_done(phase)` / `_mark_phase_done(phase)` | Guard functions for idempotent phase execution |
| `_reset_from_phase(phase)` | Removes a phase and all subsequent phases from `phases_completed`; used by `--from-phase` |

---

## Constants

```bash
V300_TEMPLATE_URL="https://sumologic-appdev-aws-sam-apps.s3.us-east-1.amazonaws.com/aws-observability-versions/v3.0.0/templates/sumologic_observability.master.template.yaml"
DELETE_INSTANCES_TIMEOUT=3600   # 60 min
CREATE_INSTANCES_TIMEOUT=5400   # 90 min
POLL_INTERVAL=30
AWSO_FER_COUNT=17
```

---

## Differences from MigrateAWSOStackToV300.sh (Single-Stack)

| Dimension | MigrateAWSOStackToV300.sh | MigrateAWSOStackSetToV300.sh |
|-----------|-----------------|--------------------------|
| Deployment type | Single CloudFormation stack | CloudFormation StackSet |
| Accounts | 1 | N (enumerated automatically) |
| Regions | 1 | M per account (enumerated automatically) |
| Instance selection | N/A | `all` (auto-include all eligible) or `select` (interactive [y/n] per instance) |
| S3 bucket capture | Fetches from Sumo sources | Fetches from deployed stack params and `CommonS3Bucket` physical resource ID per region |
| Alias source | CLI param or stack param | Resolved from `describe-stacks` on deployed stack via cross-account creds |
| Stack deletion | `delete-stack` + retain-resources fallback | `delete-stack-instances` + automatic FAILED/CANCELLED recovery |
| StackSet lifecycle | N/A | `update-stack-set` in-place (`all`+no `-n`) or `create-stack-set` with new name (all other cases) |
| Instance creation | `create-stack` (single call) | One `create-stack-instances` per (account, region) |
| Role patching | Read role from single nested stack | Assume execution role per account; `list-stack-instances` uses management account creds |
| State / resume | `--params-file` (params JSON only) | `--state-file` (full JSON: phases, instances, aliases, per-region bucket map) |
| Auto-resume | N/A | Automatically enabled when `--state-file` points to existing file |

---

## Known Limitations

1. **Sequential instance creation in Phase 11**: One `create-stack-instances` call per (account, region) pair, each polled to completion before the next. Duration scales with the total number of instances.
2. **Execution role trust required**: Phase 13 assumes the execution role in each member account. If the trust policy does not allow assumption, role patching is skipped for that account with a warning.
3. **FER and metric-rule cleanup is org-wide**: If the same Sumo org is used for both StackSet and standalone AWSO stacks, ensure standalone stacks are also migrated before FER names are reused.
4. **No rollback**: Once instances are deleted, the old v2.x stack configuration is gone. The state file and `--resume` enable forward recovery only.
5. **bash 4+ required**: `read -a` (array read) behaves differently on macOS's built-in bash 3.2. Install bash via Homebrew if the script fails with array-related errors.
