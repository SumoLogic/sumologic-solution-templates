#!/bin/bash
set -euo pipefail

# ============================================================
# AWSO StackSet Migration Script: v2.x → v3.0.0
# ============================================================
# Migrates AWS Observability deployed via StackSet (e.g. Control Tower)
# across multiple accounts and regions.
#
# Phases:
#   1  Validate            — credentials, StackSet exists, no running operation
#   2  Enumerate           — list all stack instances (account/region/alias)
#   3  Map Parameters      — v2.x StackSet base params → v3.0.0 format
#   4  Confirm             — user approval gate (accounts, regions, params)
#   5  Update ROD=false    — update-stack-instances with RemoveOnDeleteStack=false
#   6  Delete Instances    — delete-stack-instances + wait
#   7  Delete StackSet     — delete-stack-set (requires 0 instances)
#   8  FER Cleanup         — rename+disable 17 AWSO FERs (org-level, once)
#   9  Metric Rules        — delete 4 AWSO metric rules (org-level, once)
#  10  Create StackSet     — create-stack-set with v3.0.0 template + base params
#  11  Create Instances    — one create-stack-instances per account (alias override)
#  12  Verify              — all instances CURRENT/SUCCEEDED
#  13  Patch Role ARNs     — assume execution role per account, fix Sumo source roleARNs
#  14  Report              — summary
#
# Dependencies: bash, aws cli v2, jq, curl

SCRIPT_VERSION="1.0.0"
V300_TEMPLATE_URL="https://sumologic-appdev-aws-sam-apps.s3.us-east-1.amazonaws.com/aws-observability-versions/v3.0.0/templates/sumologic_observability.master.template.yaml"

DELETE_INSTANCES_TIMEOUT=3600   # 60 min
CREATE_INSTANCES_TIMEOUT=5400   # 90 min
DELETE_STACKSET_TIMEOUT=300     # 5 min
POLL_INTERVAL=30
AWSO_FER_COUNT=17

AWSO_FER_NAMES=(
    "AwsObservabilityAlbAccessLogsFER"
    "AwsObservabilityApiGatewayAccessLogsFER"
    "AwsObservabilityApiGatewayCloudTrailLogsFER"
    "AwsObservabilityDynamoDBCloudTrailLogsFER"
    "AwsObservabilityEC2CloudTrailLogsFER"
    "AwsObservabilityECSCloudTrailLogsFER"
    "AwsObservabilityElastiCacheCloudTrailLogsFER"
    "AwsObservabilityElbAccessLogsFER"
    "AwsObservabilityFieldExtractionRule"
    "AwsObservabilityGenericCloudWatchLogsFER"
    "AwsObservabilityLambdaCloudWatchLogsFER"
    "AwsObservabilityRdsCloudTrailLogsFER"
    "AwsObservabilitySNSCloudTrailLogsFER"
    "AwsObservabilitySQSCloudTrailLogsFER"
    "AwsObservabilityALBCloudTrailLogsFER"
    "AwsObservabilityCLBCloudTrailLogsFER"
    "AwsObservabilityNLBCloudTrailLogsFER"
)

AWSO_METRIC_RULES=(
    "AwsObservabilityRDSClusterMetricsEntityRule"
    "AwsObservabilityRDSInstanceMetricsEntityRule"
    "AwsObservabilityNLBMetricsEntityRule"
    "AwsObservabilityApiGatewayApiNameMetricsEntityRule"
)

# ---- Colours ----
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

# ---- Logging ----
LOG_FILE="/dev/null"
_log_to_file() { sed 's/\x1b\[[0-9;]*m//g' >> "$LOG_FILE"; }
log_info()  { echo -e "${GREEN}[INFO]${NC}  $*" | tee >( _log_to_file ); }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*" | tee >( _log_to_file ); }
log_error() { echo -e "${RED}[ERROR]${NC} $*" | tee >( _log_to_file ); }
log_phase() {
    echo -e "\n${BLUE}════════════════════════════════════════${NC}" | tee >( _log_to_file )
    echo -e "${BLUE}  $*${NC}" | tee >( _log_to_file )
    echo -e "${BLUE}════════════════════════════════════════${NC}" | tee >( _log_to_file )
}

# ---- Input globals ----
DEPLOYMENT=""
ACCESS_ID=""
ACCESS_KEY=""
ORG_ID=""
STACKSET_NAME="SUMO-LOGIC-AWS-OBSERVABILITY"
NEW_STACKSET_NAME=""           # defaults to STACKSET_NAME if not set
ADMIN_ROLE_ARN=""              # auto-detected from StackSet
EXECUTION_ROLE_NAME=""         # auto-detected from StackSet
HOME_REGION=""                 # AWS region where the StackSet is registered (Control Tower home region)
AWS_PROFILE="default"
INSTALL_APPS="No"
CONCURRENCY=1
FAILURE_TOLERANCE=0
DRY_RUN=false
RESUME=false
STATE_FILE=""
PATCH_ROLES_ONLY=false
FROM_PHASE=""                  # when set, clears this phase + all subsequent from PHASES_COMPLETED

# ---- Runtime globals ----
SUMO_API_URL=""
MGMT_ACCOUNT_ID=""
INSTANCES_JSON="[]"            # array of {account, region, alias}
ACCOUNT_ALIAS_MAP="{}"         # {account: alias}
ACCOUNT_BUCKET_MAP="{}"        # {"account/region": {alb, cloudtrail, elb}} — per region
V300_BASE_PARAMS="[]"
FER_RENAMED_COUNT=0
SOURCES_PATCHED=0
PHASES_COMPLETED=()
FAILED_INSTANCES=()
TEMP_FILES=()

# ---- Cleanup ----
_cleanup() {
    for f in "${TEMP_FILES[@]:-}"; do
        [[ -n "$f" && -f "$f" ]] && rm -f "$f"
    done
}
trap _cleanup EXIT

# ============================================================
# Core Helpers
# ============================================================

get_sumo_api_url() {
    case "$1" in
        us1) echo "https://api.sumologic.com" ;;
        us2) echo "https://api.us2.sumologic.com" ;;
        eu)  echo "https://api.eu.sumologic.com" ;;
        de)  echo "https://api.de.sumologic.com" ;;
        au)  echo "https://api.au.sumologic.com" ;;
        jp)  echo "https://api.jp.sumologic.com" ;;
        ca)  echo "https://api.ca.sumologic.com" ;;
        kr)  echo "https://api.kr.sumologic.com" ;;
        fed) echo "https://api.fed.sumologic.com" ;;
        ch)  echo "https://api.ch.sumologic.com" ;;
        esc) echo "https://api.esc.sumologic.com" ;;
        *)   log_error "Unknown deployment: $1"; exit 1 ;;
    esac
}

aws_cmd() {
    if [[ "$(uname)" == "Darwin" ]]; then
        /bin/zsh -l -c 'aws --profile "$1" "${@:2}"' _ "${AWS_PROFILE}" "$@"
    else
        aws --profile "${AWS_PROFILE}" "$@"
    fi
}

# Assume a cross-account role and run aws_cmd with those credentials.
# Usage: aws_cmd_as_role ROLE_ARN EXTERNAL_ID aws_subcommand...
# (EXTERNAL_ID may be empty string)
aws_cmd_as_role() {
    local role_arn="$1" external_id="$2"; shift 2
    local creds
    if [[ -n "$external_id" ]]; then
        creds=$( aws_cmd sts assume-role \
            --role-arn "$role_arn" \
            --role-session-name "awso-stackset-migration" \
            --external-id "$external_id" \
            --output json )
    else
        creds=$( aws_cmd sts assume-role \
            --role-arn "$role_arn" \
            --role-session-name "awso-stackset-migration" \
            --output json )
    fi
    AWS_ACCESS_KEY_ID=$(    echo "$creds" | jq -r '.Credentials.AccessKeyId' ) \
    AWS_SECRET_ACCESS_KEY=$( echo "$creds" | jq -r '.Credentials.SecretAccessKey' ) \
    AWS_SESSION_TOKEN=$(    echo "$creds" | jq -r '.Credentials.SessionToken' ) \
    aws "$@"
}

sumo_get() {
    local path="$1"
    curl -s --max-redirs 0 \
        -u "${ACCESS_ID}:${ACCESS_KEY}" \
        -H "Accept: application/json" \
        "${SUMO_API_URL}${path}"
}

sumo_put() {
    local path="$1" body="$2"
    curl -s --max-redirs 0 \
        -u "${ACCESS_ID}:${ACCESS_KEY}" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -w "\n%{http_code}" \
        -X PUT -d "$body" \
        "${SUMO_API_URL}${path}"
}

sumo_get_with_etag() {
    local path="$1" header_file="$2"
    curl -s --max-redirs 0 \
        -D "$header_file" \
        -u "${ACCESS_ID}:${ACCESS_KEY}" \
        -H "Accept: application/json" \
        "${SUMO_API_URL}${path}"
}

sumo_put_if_match() {
    local path="$1" body="$2" etag="$3"
    curl -s --max-redirs 0 \
        -u "${ACCESS_ID}:${ACCESS_KEY}" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -H "If-Match: ${etag}" \
        -w "\n%{http_code}" \
        -X PUT -d "$body" \
        "${SUMO_API_URL}${path}"
}

# Capture ALB/CloudTrail/ELB bucket names for one account from Sumo sources.
# Captures collector ID (once per account) and S3 bucket names (per region).
# ACCOUNT_BUCKET_MAP key is "account/region" so each region can have distinct buckets.
#
# Collector lookup (mirrors MigrateToV300.sh phase_capture):
#   1. CF cross-check  — SumoLogicHostedCollector PhysicalResourceId from CreateCommonResources
#   2. Sumo API search — exact name, then paginated startswith+endswith
#   3. Mismatch prompt — interactive if CF and API disagree
#
# Bucket lookup per region (from CF — authoritative):
#   - Stack params Section5d/6c/8d if explicitly set
#   - Otherwise CommonS3Bucket PhysicalResourceId from CreateCommonResources

# ============================================================
# Instance selection — called at the end of phase_enumerate
# before bucket capture. Skipped when --resume is active.
# ============================================================
_select_instances() {
    # When resuming, INSTANCES_JSON is loaded from the state file — skip selection.
    if _phase_done "enumerate"; then
        return 0
    fi

    local total
    total=$( echo "$INSTANCES_JSON" | jq 'length' )

    echo ""
    local choice
    read -r -p "  Migrate all instances or select specific ones? (all/select) [all]: " choice < /dev/tty
    choice="${choice:-all}"

    if [[ "$choice" == "all" || "$choice" == "a" ]]; then
        log_info "Proceeding with all ${total} instances."
        return 0
    fi

    echo ""
    printf "  %-4s  %-16s  %-14s  %s\n" "#" "Account" "Region" "Include?"
    printf "  %-4s  %-16s  %-14s  %s\n" "----" "----------------" "--------------" "--------"

    local selected="[]" idx=0
    while IFS= read -r inst; do
        idx=$(( idx + 1 ))
        local acct region yn
        acct=$(   echo "$inst" | jq -r '.account' )
        region=$( echo "$inst" | jq -r '.region' )
        read -r -p "  $(printf '%-4s  %-16s  %-14s' "$idx" "$acct" "$region")  [y/n]: " yn < /dev/tty
        if [[ "$yn" == "y" || "$yn" == "Y" ]]; then
            selected=$( echo "$selected" | jq --argjson i "$inst" '. + [$i]' )
        fi
    done < <( echo "$INSTANCES_JSON" | jq -c '.[]' )

    local sel_count
    sel_count=$( echo "$selected" | jq 'length' )
    if [[ "$sel_count" -eq 0 ]]; then
        log_info "No instances selected. Exiting."
        exit 0
    fi

    INSTANCES_JSON="$selected"
    log_info "Selected ${sel_count} of ${idx} instance(s)."

    # Prune ACCOUNT_ALIAS_MAP to only accounts that still have selected instances
    local selected_accounts
    selected_accounts=$( echo "$INSTANCES_JSON" | jq '[.[].account] | unique' )
    ACCOUNT_ALIAS_MAP=$( echo "$ACCOUNT_ALIAS_MAP" | jq --argjson keep "$selected_accounts" \
        'to_entries | map(select(.key as $k | $keep | index($k) != null)) | from_entries' )
}

_capture_buckets_for_account() {
    local account="$1"
    local alias
    alias=$( echo "$ACCOUNT_ALIAS_MAP" | jq -r --arg a "$account" '.[$a]' )

    # Assume execution role once for this account — reused across all its regions
    local AKI="" SAK="" ST=""
    if [[ -n "$EXECUTION_ROLE_NAME" ]]; then
        local exec_role_arn="arn:aws:iam::${account}:role/${EXECUTION_ROLE_NAME}"
        local creds
        creds=$( aws_cmd sts assume-role \
            --role-arn "$exec_role_arn" \
            --role-session-name "awso-capture-buckets" \
            --output json 2>/dev/null ) || creds=""
        if [[ -n "$creds" ]]; then
            AKI=$( echo "$creds" | jq -r '.Credentials.AccessKeyId' )
            SAK=$( echo "$creds" | jq -r '.Credentials.SecretAccessKey' )
            ST=$(  echo "$creds" | jq -r '.Credentials.SessionToken' )
        fi
    fi

    # ── Collector ID (once per account) ──────────────────────────────────────
    local cf_collector_id="" api_collector_id="" collector_id=""
    local first_region
    first_region=$( echo "$INSTANCES_JSON" | jq -r \
        --arg a "$account" '.[] | select(.account == $a) | .region' | head -1 )

    if [[ -n "$AKI" && -n "$first_region" ]]; then
        local stack_id
        stack_id=$( aws_cmd cloudformation describe-stack-instance \
            --stack-set-name "$STACKSET_NAME" \
            --stack-instance-account "$account" \
            --stack-instance-region  "$first_region" \
            --region "$HOME_REGION" \
            --output json 2>/dev/null \
            | jq -r '.StackInstance.StackId // ""' )

        if [[ -n "$stack_id" && "$stack_id" != "null" ]]; then
            # Correct alias from deployed stack (base param not visible in ParameterOverrides)
            local stack_alias
            stack_alias=$( AWS_ACCESS_KEY_ID="$AKI" AWS_SECRET_ACCESS_KEY="$SAK" AWS_SESSION_TOKEN="$ST" \
                aws cloudformation describe-stacks \
                --stack-name "$stack_id" --region "$first_region" --output json 2>/dev/null \
                | jq -r '[.Stacks[0].Parameters[] | select(.ParameterKey == "Section2aAccountAlias")] | .[0].ParameterValue // ""' )
            if [[ -n "$stack_alias" && "$stack_alias" != "null" ]]; then
                log_info "  Account ${account}: alias = '${stack_alias}' (from deployed stack)"
                alias="$stack_alias"
                ACCOUNT_ALIAS_MAP=$( echo "$ACCOUNT_ALIAS_MAP" | jq \
                    --arg a "$account" --arg al "$stack_alias" '.[$a] = $al' )
            else
                log_warn "  Account ${account}: Section2aAccountAlias not found in deployed stack — using account ID as alias"
            fi

            # CF cross-check: SumoLogicHostedCollector PhysicalResourceId
            local nested_stack_id
            nested_stack_id=$( AWS_ACCESS_KEY_ID="$AKI" AWS_SECRET_ACCESS_KEY="$SAK" AWS_SESSION_TOKEN="$ST" \
                aws cloudformation list-stack-resources \
                --stack-name "$stack_id" --region "$first_region" --output json 2>/dev/null \
                | jq -r '.StackResourceSummaries[] | select(.LogicalResourceId == "CreateCommonResources") | .PhysicalResourceId // ""' )

            if [[ -n "$nested_stack_id" && "$nested_stack_id" != "null" ]]; then
                cf_collector_id=$( AWS_ACCESS_KEY_ID="$AKI" AWS_SECRET_ACCESS_KEY="$SAK" AWS_SESSION_TOKEN="$ST" \
                    aws cloudformation list-stack-resources \
                    --stack-name "$nested_stack_id" --region "$first_region" --output json 2>/dev/null \
                    | jq -r '.StackResourceSummaries[] | select(.LogicalResourceId == "SumoLogicHostedCollector") | .PhysicalResourceId // "" | split("/")[-1]' )
                [[ "$cf_collector_id" == "null" ]] && cf_collector_id=""
            fi
        fi
    fi

    # Sumo API name search
    local expected_name="aws-observability-${alias}-${account}"
    api_collector_id=$( sumo_get "/api/v1/collectors?name=${expected_name}" \
        | jq -r --arg n "$expected_name" '.collectors[] | select(.name == $n) | .id' 2>/dev/null | head -1 )
    if [[ -z "$api_collector_id" ]]; then
        local _off=0
        while true; do
            local _pg
            _pg=$( sumo_get "/api/v1/collectors?limit=1000&offset=${_off}" )
            api_collector_id=$( echo "$_pg" | jq -r --arg acct "$account" \
                '[.collectors[] | select((.name | startswith("aws-observability")) and (.name | endswith("-" + $acct)))] | .[0].id // ""' )
            [[ -n "$api_collector_id" ]] && break
            local _ret; _ret=$( echo "$_pg" | jq '.collectors | length' )
            [[ "$_ret" -lt 1000 ]] && break
            _off=$(( _off + 1000 ))
        done
    fi

    # Reconcile — prompt on mismatch
    if [[ -n "$cf_collector_id" && -n "$api_collector_id" ]]; then
        if [[ "$cf_collector_id" == "$api_collector_id" ]]; then
            log_info "  Account ${account}: collector ${cf_collector_id} (CF and Sumo API agree ✓)"
            collector_id="$cf_collector_id"
        else
            log_warn "  Collector ID mismatch for account ${account}!"
            log_warn "    CF stack recorded: ${cf_collector_id}"
            log_warn "    Sumo API found:    ${api_collector_id} (${expected_name})"
            log_warn "    The collector found via Sumo API does not match the one created by this CF stack."
            while true; do
                read -r -p "  Options: (1) Use CF collector (${cf_collector_id}), (2) Use Sumo API collector (${api_collector_id}), (3) Enter ID manually, (4) Abort: " _choice < /dev/tty
                case "$_choice" in
                    1) collector_id="$cf_collector_id";  log_info "  Using CF collector: ${collector_id}";       break ;;
                    2) collector_id="$api_collector_id"; log_info "  Using Sumo API collector: ${collector_id}"; break ;;
                    3) while true; do
                           read -r -p "  Enter collector ID: " _manual_id < /dev/tty
                           if [[ "$_manual_id" =~ ^[0-9]+$ ]]; then
                               collector_id="$_manual_id"
                               log_info "  Using manually provided collector ID: ${collector_id}"; break
                           else
                               log_warn "  Invalid — must be numeric. Try again."
                           fi
                       done; break ;;
                    4) log_error "Migration aborted by user."; exit 1 ;;
                    *) log_warn "  Enter 1, 2, 3, or 4." ;;
                esac
            done
        fi
    elif [[ -n "$cf_collector_id" ]]; then
        collector_id="$cf_collector_id"
        log_info "  Account ${account}: collector ${collector_id} (CF cross-check; no Sumo API match)"
    elif [[ -n "$api_collector_id" ]]; then
        collector_id="$api_collector_id"
        log_info "  Account ${account}: collector ${collector_id} (Sumo API; CF cross-check skipped)"
    fi

    if [[ -z "$collector_id" ]]; then
        log_warn "  Could not find Sumo collector for account ${account} — buckets will be empty for all regions."
    fi

    # Fetch sources once (used for region-level bucket matching below)
    local sources_json=""
    [[ -n "$collector_id" ]] && sources_json=$( sumo_get "/api/v1/collectors/${collector_id}/sources" )

    # ── Bucket names per region (each region has its own CreateCommonResources) ──
    local regions_for_account
    regions_for_account=$( echo "$INSTANCES_JSON" | jq -r \
        --arg a "$account" '.[] | select(.account == $a) | .region' )

    while IFS= read -r region; do
        log_info "  Account ${account} / ${region}: capturing buckets..."
        local bucket_alb="" bucket_ct="" bucket_elb=""

        if [[ -n "$AKI" ]]; then
            local r_stack_id
            r_stack_id=$( aws_cmd cloudformation describe-stack-instance \
                --stack-set-name "$STACKSET_NAME" \
                --stack-instance-account "$account" \
                --stack-instance-region  "$region" \
                --region "$HOME_REGION" \
                --output json 2>/dev/null \
                | jq -r '.StackInstance.StackId // ""' )

            if [[ -n "$r_stack_id" && "$r_stack_id" != "null" ]]; then
                # Try explicit stack parameters first
                local r_params
                r_params=$( AWS_ACCESS_KEY_ID="$AKI" AWS_SECRET_ACCESS_KEY="$SAK" AWS_SESSION_TOKEN="$ST" \
                    aws cloudformation describe-stacks \
                    --stack-name "$r_stack_id" --region "$region" --output json 2>/dev/null \
                    | jq -c '.Stacks[0].Parameters // []' )

                bucket_alb=$( echo "$r_params" | jq -r '[.[] | select(.ParameterKey == "Section5dALBS3LogsBucketName")] | .[0].ParameterValue // ""' )
                bucket_ct=$(  echo "$r_params" | jq -r '[.[] | select(.ParameterKey == "Section6cCloudTrailLogsBucketName")] | .[0].ParameterValue // ""' )
                bucket_elb=$( echo "$r_params" | jq -r '[.[] | select(.ParameterKey == "Section9dELBS3LogsBucketName")] | .[0].ParameterValue // ""' )

                # If bucket params are empty, read CommonS3Bucket from CreateCommonResources
                if [[ -z "$bucket_alb" || -z "$bucket_ct" || -z "$bucket_elb" ]]; then
                    local r_nested
                    r_nested=$( AWS_ACCESS_KEY_ID="$AKI" AWS_SECRET_ACCESS_KEY="$SAK" AWS_SESSION_TOKEN="$ST" \
                        aws cloudformation list-stack-resources \
                        --stack-name "$r_stack_id" --region "$region" --output json 2>/dev/null \
                        | jq -r '.StackResourceSummaries[] | select(.LogicalResourceId == "CreateCommonResources") | .PhysicalResourceId // ""' )

                    if [[ -n "$r_nested" && "$r_nested" != "null" ]]; then
                        local common_bucket
                        common_bucket=$( AWS_ACCESS_KEY_ID="$AKI" AWS_SECRET_ACCESS_KEY="$SAK" AWS_SESSION_TOKEN="$ST" \
                            aws cloudformation list-stack-resources \
                            --stack-name "$r_nested" --region "$region" --output json 2>/dev/null \
                            | jq -r '.StackResourceSummaries[] | select(.LogicalResourceId == "CommonS3Bucket") | .PhysicalResourceId // ""' )
                        [[ "$common_bucket" == "null" ]] && common_bucket=""
                        [[ -z "$bucket_alb" ]] && bucket_alb="$common_bucket"
                        [[ -z "$bucket_ct"  ]] && bucket_ct="$common_bucket"
                        [[ -z "$bucket_elb" ]] && bucket_elb="$common_bucket"
                    fi
                fi
            fi
        fi

        # Fall back to Sumo source matching by region suffix if CF lookup gave nothing
        if [[ -z "$bucket_alb" && -n "$sources_json" ]]; then
            bucket_alb=$( echo "$sources_json" | jq -r --arg r "$region" \
                '[.sources[] | select(.name | (startswith("alb-logs") and (contains($r) or (endswith("alb-logs")))))
                | .thirdPartyRef.resources[0].path.bucketName // ""][0] // ""' )
            bucket_ct=$( echo "$sources_json" | jq -r --arg r "$region" \
                '[.sources[] | select(.name | (startswith("cloudtrail-logs") and (contains($r) or (endswith("cloudtrail-logs")))))
                | .thirdPartyRef.resources[0].path.bucketName // ""][0] // ""' )
            bucket_elb=$( echo "$sources_json" | jq -r --arg r "$region" \
                '[.sources[] | select(.name | (startswith("classic-lb-logs") and (contains($r) or (endswith("classic-lb-logs")))))
                | .thirdPartyRef.resources[0].path.bucketName // ""][0] // ""' )
        fi

        log_info "    ALB bucket:        ${bucket_alb:-<empty>}"
        log_info "    CloudTrail bucket: ${bucket_ct:-<empty>}"
        log_info "    ELB bucket:        ${bucket_elb:-<empty>}"

        local key="${account}/${region}"
        ACCOUNT_BUCKET_MAP=$( echo "$ACCOUNT_BUCKET_MAP" | jq \
            --arg k   "$key" \
            --arg alb "$bucket_alb" \
            --arg ct  "$bucket_ct" \
            --arg elb "$bucket_elb" \
            '.[$k] = {"alb": $alb, "cloudtrail": $ct, "elb": $elb}' )
    done <<< "$regions_for_account"
}

# Poll a StackSet operation until SUCCEEDED/FAILED/STOPPED/TIMEOUT.
# Prints final status to stdout. Returns 0 on SUCCEEDED, 1 otherwise.
wait_for_stackset_operation() {
    local stackset_name="$1" operation_id="$2" timeout_secs="$3"
    local elapsed=0
    log_info "Waiting for StackSet operation ${operation_id} (timeout ${timeout_secs}s)..." >&2
    while [[ $elapsed -lt $timeout_secs ]]; do
        local status
        status=$( aws_cmd cloudformation describe-stack-set-operation \
            --stack-set-name "$stackset_name" \
            --operation-id "$operation_id" \
            --region "$HOME_REGION" \
            --output json \
            | jq -r '.StackSetOperation.Status' )
        case "$status" in
            SUCCEEDED) log_info "  Operation ${operation_id}: SUCCEEDED" >&2; echo "$status"; return 0 ;;
            FAILED|STOPPED)
                log_error "  Operation ${operation_id}: ${status}" >&2
                # Print per-instance results for diagnostics
                aws_cmd cloudformation list-stack-set-operation-results \
                    --stack-set-name "$stackset_name" \
                    --operation-id "$operation_id" \
                    --region "$HOME_REGION" \
                    --output json 2>/dev/null \
                | jq -r '.Summaries[] | select(.Status != "SUCCEEDED") | "  \(.Account)/\(.Region): \(.Status) \(.StatusReason // "")"' \
                | while IFS= read -r line; do log_warn "$line" >&2; done || true
                echo "$status"; return 1 ;;
        esac
        sleep $POLL_INTERVAL
        elapsed=$(( elapsed + POLL_INTERVAL ))
        log_info "  ... ${elapsed}s elapsed, status: ${status}" >&2
    done
    log_error "  Operation ${operation_id} timed out after ${timeout_secs}s" >&2
    echo "TIMEOUT"; return 1
}

# ============================================================
# State File (JSON) — for --resume support
# ============================================================

_phase_done() {
    local phase="$1"
    for p in "${PHASES_COMPLETED[@]:-}"; do
        [[ "$p" == "$phase" ]] && return 0
    done
    return 1
}

# Ordered list of all phases — used by --from-phase to know what to clear
PHASE_ORDER=(
    validate
    enumerate
    map_params
    confirm
    update_rod
    delete_instances
    fer_cleanup
    metric_rules
    create_stackset
    create_instances
    verify
    patch_role_arns
)

_mark_phase_done() {
    local phase="$1"
    _phase_done "$phase" && return 0
    PHASES_COMPLETED+=("$phase")
    _save_state
}

# Remove FROM_PHASE and all subsequent phases from PHASES_COMPLETED.
# This lets the user force a re-run from any point without editing the state file.
_reset_from_phase() {
    local target="$1"
    local found=false
    local new_completed=()
    for phase in "${PHASE_ORDER[@]}"; do
        [[ "$phase" == "$target" ]] && found=true
        if [[ "$found" == false ]]; then
            _phase_done "$phase" && new_completed+=("$phase")
        fi
    done
    if [[ "$found" == false ]]; then
        log_error "Unknown phase name '${target}'. Valid phases: ${PHASE_ORDER[*]}"
        exit 1
    fi
    PHASES_COMPLETED=("${new_completed[@]}")
    log_info "Reset: will re-run from '${target}' onwards. Completed so far: ${PHASES_COMPLETED[*]:-<none>}"
    _save_state
}

_save_state() {
    [[ -z "$STATE_FILE" ]] && return 0
    local phases_json instances_json
    phases_json=$( printf '%s\n' "${PHASES_COMPLETED[@]:-}" | jq -R . | jq -s . )
    local failed_json
    failed_json=$( printf '%s\n' "${FAILED_INSTANCES[@]:-}" | jq -R . | jq -s . )
    jq -n \
        --arg     stackset_name    "$STACKSET_NAME" \
        --arg     new_stackset     "${NEW_STACKSET_NAME:-$STACKSET_NAME}" \
        --arg     home_region      "$HOME_REGION" \
        --argjson instances        "$INSTANCES_JSON" \
        --argjson v300_base_params "$V300_BASE_PARAMS" \
        --argjson account_alias    "$ACCOUNT_ALIAS_MAP" \
        --argjson account_buckets  "$ACCOUNT_BUCKET_MAP" \
        --argjson phases_done      "$phases_json" \
        --argjson failed           "$failed_json" \
        --arg     admin_role_arn   "$ADMIN_ROLE_ARN" \
        --arg     exec_role        "$EXECUTION_ROLE_NAME" \
        '{
            stackset_name: $stackset_name,
            new_stackset_name: $new_stackset,
            home_region: $home_region,
            instances: $instances,
            v300_base_params: $v300_base_params,
            account_alias_map: $account_alias,
            account_bucket_map: $account_buckets,
            phases_completed: $phases_done,
            failed_instances: $failed,
            admin_role_arn: $admin_role_arn,
            execution_role_name: $exec_role
        }' > "$STATE_FILE"
    log_info "State saved to ${STATE_FILE}"
}

_load_state() {
    [[ -z "$STATE_FILE" || ! -f "$STATE_FILE" ]] && return 0
    log_info "Loading state from ${STATE_FILE}"

    local s
    s=$( cat "$STATE_FILE" ) || { log_error "Cannot read state file: ${STATE_FILE}"; exit 1; }

    # Validate JSON before parsing
    if ! echo "$s" | jq . > /dev/null 2>&1; then
        log_error "State file is not valid JSON: ${STATE_FILE}"
        log_error "It may have been corrupted. Check it with: jq . ${STATE_FILE}"
        exit 1
    fi

    local _field
    _field="stackset_name";     STACKSET_NAME=$(      echo "$s" | jq -r ".$_field // empty" ) \
        || { log_error "Failed to parse .$_field from state file"; exit 1; }
    _field="new_stackset_name"; NEW_STACKSET_NAME=$(  echo "$s" | jq -r ".$_field // empty" ) \
        || { log_error "Failed to parse .$_field from state file"; exit 1; }
    _field="instances";         INSTANCES_JSON=$(     echo "$s" | jq -c ".$_field // []" ) \
        || { log_error "Failed to parse .$_field from state file"; exit 1; }
    _field="v300_base_params";  V300_BASE_PARAMS=$(   echo "$s" | jq -c ".$_field // []" ) \
        || { log_error "Failed to parse .$_field from state file"; exit 1; }
    _field="account_alias_map"; ACCOUNT_ALIAS_MAP=$(  echo "$s" | jq -c ".$_field // {}" ) \
        || { log_error "Failed to parse .$_field from state file"; exit 1; }
    _field="account_bucket_map"; ACCOUNT_BUCKET_MAP=$( echo "$s" | jq -c ".$_field // {}" ) \
        || { log_error "Failed to parse .$_field from state file"; exit 1; }

    # Command-line flags (-r, --admin-role-arn, --execution-role) take precedence;
    # only load from state when the flag was not explicitly provided.
    [[ -z "$HOME_REGION"         ]] && HOME_REGION=$(         echo "$s" | jq -r '.home_region // ""' )
    [[ -z "$ADMIN_ROLE_ARN"      ]] && ADMIN_ROLE_ARN=$(      echo "$s" | jq -r '.admin_role_arn // ""' )
    [[ -z "$EXECUTION_ROLE_NAME" ]] && EXECUTION_ROLE_NAME=$( echo "$s" | jq -r '.execution_role_name // ""' )

    local _p _f
    _p=$( echo "$s" | jq -r 'if .phases_completed then .phases_completed | join(" ") else "" end' ) \
        || { log_error "Failed to parse .phases_completed from state file"; exit 1; }
    _f=$( echo "$s" | jq -r 'if .failed_instances  then .failed_instances  | join(" ") else "" end' ) \
        || { log_error "Failed to parse .failed_instances from state file"; exit 1; }
    PHASES_COMPLETED=(); [[ -n "$_p" ]] && read -ra PHASES_COMPLETED <<< "$_p"
    FAILED_INSTANCES=(); [[ -n "$_f" ]] && read -ra FAILED_INSTANCES <<< "$_f"

    log_info "Resumed at phases: ${PHASES_COMPLETED[*]:-<none>}"
}

# ============================================================
# Parameter Mapping (v2.x StackSet base params → v3.0.0)
# ============================================================
map_params_v215() {
    local v2_params="$1"
    echo "$v2_params" | jq \
        --arg install_apps "$INSTALL_APPS" \
        --arg access_id    "$ACCESS_ID" \
        --arg access_key   "$ACCESS_KEY" \
        '
        # Remove Section10 (not in v3.0.0)
        [ .[] | select(
            .ParameterKey != "Section10aAppInstallLocation" and
            .ParameterKey != "Section10bShare"
        )] |

        # Rename keys
        [ .[] | .ParameterKey = (
            if   .ParameterKey == "Section7aLambdaCreateCloudWatchLogsSourceOptions" then "Section7aCreateCloudWatchLogsSourceOptions"
            elif .ParameterKey == "Section7bLambdaCloudWatchLogsSourceUrl"           then "Section7bCloudWatchLogsSourceUrl"
            elif .ParameterKey == "Section9aAutoEnableS3LogsELBResourcesOptions"     then "Section8aAutoEnableS3LogsELBResourcesOptions"
            elif .ParameterKey == "Section9bELBCreateLogSource"                      then "Section8bELBCreateLogSource"
            elif .ParameterKey == "Section9cELBLogsSourceUrl"                        then "Section8cELBLogsSourceUrl"
            elif .ParameterKey == "Section9dELBS3LogsBucketName"                     then "Section8dELBS3LogsBucketName"
            elif .ParameterKey == "Section9eELBS3BucketPathExpression"               then "Section8eELBS3BucketPathExpression"
            else .ParameterKey
            end
        )] |

        # Override values
        [ .[] | .ParameterValue = (
            if   .ParameterKey == "Section1eSumoLogicResourceRemoveOnDeleteStack" then "false"
            elif .ParameterKey == "Section1bSumoLogicAccessID"                    then $access_id
            elif .ParameterKey == "Section1cSumoLogicAccessKey"                   then $access_key
            elif .ParameterKey == "Section3aInstallObservabilityApps"             then $install_apps
            elif .ParameterKey == "Section4cCloudWatchExistingSourceAPIUrl"       then ""
            elif .ParameterKey == "Section5cALBLogsSourceUrl"                     then ""
            elif .ParameterKey == "Section5dALBS3LogsBucketName"                  then ""
            elif .ParameterKey == "Section6bCloudTrailLogsSourceUrl"              then ""
            elif .ParameterKey == "Section6cCloudTrailLogsBucketName"             then ""
            elif .ParameterKey == "Section7bCloudWatchLogsSourceUrl"              then ""
            elif .ParameterKey == "Section8cELBLogsSourceUrl"                     then ""
            elif .ParameterKey == "Section8dELBS3LogsBucketName"                  then ""
            else .ParameterValue
            end
        )]
        '
}

# ============================================================
# Phase 1 — Validate
# ============================================================
phase_validate() {
    log_phase "Phase 1: Validate"

    # Sumo Logic credentials — /api/v1/account/status returns account info (no .id field);
    # treat any response with .accountActivated present as a successful auth check.
    local identity
    identity=$( sumo_get "/api/v1/account/status" )
    if echo "$identity" | jq -e '.accountActivated' > /dev/null 2>&1; then
        log_info "Sumo Logic credentials valid. Plan: $( echo "$identity" | jq -r '.planType // "unknown"' ), Activated: $( echo "$identity" | jq -r '.accountActivated' )"
    else
        log_error "Sumo Logic credential check failed: $identity"
        exit 1
    fi

    # AWS caller identity
    local aws_id
    aws_id=$( aws_cmd sts get-caller-identity --output json )
    MGMT_ACCOUNT_ID=$( echo "$aws_id" | jq -r '.Account' )
    log_info "AWS management account: ${MGMT_ACCOUNT_ID} ($( echo "$aws_id" | jq -r '.Arn' ))"

    # StackSet must exist for all phases — we update it rather than delete+recreate.
    if true; then
        local ss_detail
        ss_detail=$( aws_cmd cloudformation describe-stack-set \
            --stack-set-name "$STACKSET_NAME" \
            --region "$HOME_REGION" \
            --output json 2>&1 ) || {
            log_error "StackSet '${STACKSET_NAME}' not found or not accessible."
            exit 1
        }
        log_info "StackSet '${STACKSET_NAME}' found."

        # Auto-detect admin/execution roles if not provided
        if [[ -z "$ADMIN_ROLE_ARN" ]]; then
            ADMIN_ROLE_ARN=$( echo "$ss_detail" | jq -r '.StackSet.AdministrationRoleARN // ""' )
            log_info "Admin role ARN (auto-detected): ${ADMIN_ROLE_ARN:-<none>}"
        fi
        if [[ -z "$EXECUTION_ROLE_NAME" ]]; then
            EXECUTION_ROLE_NAME=$( echo "$ss_detail" | jq -r '.StackSet.ExecutionRoleName // "AWSControlTowerExecution"' )
            log_info "Execution role name (auto-detected): ${EXECUTION_ROLE_NAME}"
        fi

        # No running operations
        local running
        running=$( aws_cmd cloudformation list-stack-set-operations \
            --stack-set-name "$STACKSET_NAME" \
            --region "$HOME_REGION" \
            --output json \
            | jq -r '.Summaries[] | select(.Status == "RUNNING") | .OperationId' )
        if [[ -n "$running" ]]; then
            log_error "StackSet has a running operation: ${running}"
            log_error "Wait for it to complete before migrating."
            exit 1
        fi
        log_info "No running StackSet operations."
    else
        log_info "Old StackSet already deleted — skipping StackSet existence checks."
        # Ensure execution role still has a value (needed by phase 13)
        [[ -z "$EXECUTION_ROLE_NAME" ]] && EXECUTION_ROLE_NAME="AWSControlTowerExecution"
    fi

    _mark_phase_done "validate"
}

# ============================================================
# Phase 2 — Enumerate Instances
# ============================================================
phase_enumerate() {
    log_phase "Phase 2: Enumerate Stack Instances"

    if _phase_done "enumerate"; then
        log_info "Already completed — skipping."
        return 0
    fi

    local raw_instances="[]"
    local next_token=""
    while true; do
        local args=( cloudformation list-stack-instances
            --stack-set-name "$STACKSET_NAME"
            --region "$HOME_REGION"
            --output json )
        [[ -n "$next_token" ]] && args+=( --next-token "$next_token" )
        local page
        page=$( aws_cmd "${args[@]}" )
        raw_instances=$( echo "$raw_instances $( echo "$page" | jq '.Summaries' )" | jq -s 'add' )
        next_token=$( echo "$page" | jq -r '.NextToken // ""' )
        [[ -z "$next_token" ]] && break
    done

    local count
    count=$( echo "$raw_instances" | jq 'length' )
    log_info "Found ${count} stack instance(s)."
    if [[ "$count" -eq 0 ]]; then
        log_error "No instances found in StackSet '${STACKSET_NAME}'. Nothing to migrate."
        exit 1
    fi

    # Build INSTANCES_JSON and ACCOUNT_ALIAS_MAP
    # For each instance, try to get Section2aAccountAlias from its override params
    INSTANCES_JSON="[]"
    ACCOUNT_ALIAS_MAP="{}"

    while IFS= read -r inst; do
        local account region alias
        account=$( echo "$inst" | jq -r '.Account' )
        region=$(  echo "$inst" | jq -r '.Region' )

        # Alias placeholder — will be resolved authoritatively from describe-stacks
        # in _capture_buckets_for_account (ParameterOverrides is unreliable when
        # Section2aAccountAlias is a StackSet base parameter, not an instance override).
        alias="$account"

        INSTANCES_JSON=$( echo "$INSTANCES_JSON" | jq \
            --arg a "$account" --arg r "$region" --arg al "$alias" \
            '. + [{"account": $a, "region": $r, "alias": $al}]' )

        # Last alias per account wins (consistent across regions)
        ACCOUNT_ALIAS_MAP=$( echo "$ACCOUNT_ALIAS_MAP" | jq \
            --arg a "$account" --arg al "$alias" \
            '.[$a] = $al' )
    done < <( echo "$raw_instances" | jq -c '.[]' )

    local unique_accounts unique_regions
    unique_accounts=$( echo "$INSTANCES_JSON" | jq -r '[.[].account] | unique | length' )
    unique_regions=$(  echo "$INSTANCES_JSON" | jq -r '[.[].region]  | unique | length' )
    log_info "Accounts: ${unique_accounts}, Regions: ${unique_regions}"

    # Prompt user to migrate all instances or select a subset
    _select_instances

    # Recalculate counts after potential selection filter
    unique_accounts=$( echo "$INSTANCES_JSON" | jq -r '[.[].account] | unique | length' )
    unique_regions=$(  echo "$INSTANCES_JSON" | jq -r '[.[].region]  | unique | length' )

    # Capture bucket names per account from Sumo sources
    log_info "Capturing S3 bucket names from Sumo sources (one collector per account)..."
    local unique_acct_list
    unique_acct_list=$( echo "$INSTANCES_JSON" | jq -r '[.[].account] | unique | .[]' )
    while IFS= read -r acct; do
        _capture_buckets_for_account "$acct"
    done <<< "$unique_acct_list"

    _mark_phase_done "enumerate"
}

# ============================================================
# Phase 3 — Map Parameters
# ============================================================
phase_map_params() {
    log_phase "Phase 3: Map Parameters"

    if _phase_done "map_params"; then
        log_info "Already completed — skipping."
        return 0
    fi

    # Get StackSet base parameters
    local raw_params
    raw_params=$( aws_cmd cloudformation describe-stack-set \
        --stack-set-name "$STACKSET_NAME" \
        --region "$HOME_REGION" \
        --output json \
        | jq '.StackSet.Parameters' )

    V300_BASE_PARAMS=$( map_params_v215 "$raw_params" )

    log_info "Mapped parameters:"
    echo "$V300_BASE_PARAMS" | jq -r '.[] | "  \(.ParameterKey) = \(.ParameterValue)"' \
        | while IFS= read -r line; do log_info "$line"; done

    _mark_phase_done "map_params"
}

# Print a per-account table: account | alias | ALB bucket | CloudTrail bucket | ELB bucket
_print_per_account_overrides() {
    printf "    %-14s  %-12s  %-20s  %-40s  %-40s  %-30s\n" \
        "Account" "Region" "Alias" "Section5d (ALB bucket)" "Section6c (CloudTrail bucket)" "Section8d (ELB bucket)"
    printf "    %-14s  %-12s  %-20s  %-40s  %-40s  %-30s\n" \
        "--------------" "------------" "--------------------" \
        "----------------------------------------" \
        "----------------------------------------" \
        "------------------------------"
    while IFS= read -r inst; do
        local account region alias bucket_alb bucket_ct bucket_elb key
        account=$( echo "$inst" | jq -r '.account' )
        region=$(  echo "$inst" | jq -r '.region' )
        key="${account}/${region}"
        alias=$(      echo "$ACCOUNT_ALIAS_MAP"  | jq -r --arg a "$account" '.[$a] // "<none>"' )
        bucket_alb=$( echo "$ACCOUNT_BUCKET_MAP" | jq -r --arg k "$key" '.[$k].alb        // "<empty>"' )
        bucket_ct=$(  echo "$ACCOUNT_BUCKET_MAP" | jq -r --arg k "$key" '.[$k].cloudtrail // "<empty>"' )
        bucket_elb=$( echo "$ACCOUNT_BUCKET_MAP" | jq -r --arg k "$key" '.[$k].elb        // "<empty>"' )
        printf "    %-14s  %-12s  %-20s  %-40s  %-40s  %-30s\n" \
            "$account" "$region" "$alias" "$bucket_alb" "$bucket_ct" "$bucket_elb"
    done < <( echo "$INSTANCES_JSON" | jq -c '.[]' )
}

# ============================================================
# Phase 4 — Confirm
# ============================================================
phase_confirm() {
    log_phase "Phase 4: Confirm"

    if _phase_done "confirm"; then
        log_info "Already confirmed — skipping."
        return 0
    fi

    # Shared base params — exclude per-account fields (bucket names + alias) which are shown per-account below
    local _per_account_keys='["Section2aAccountAlias","Section5dALBS3LogsBucketName","Section6cCloudTrailLogsBucketName","Section8dELBS3LogsBucketName"]'
    local _shared_params
    _shared_params=$( echo "$V300_BASE_PARAMS" | jq --argjson skip "$_per_account_keys" \
        '[.[] | select(.ParameterKey as $k | $skip | index($k) == null)]' )

    if [[ "$DRY_RUN" == true ]]; then
        log_warn "DRY RUN — the following would be migrated:"
        echo ""
        echo "$INSTANCES_JSON" | jq -r '.[] | "  \(.account) / \(.region)  (alias: \(.alias))"'
        echo ""
        log_warn "Shared base parameters (all accounts):"
        echo "$_shared_params" | jq -r '.[] | "  \(.ParameterKey) = \(.ParameterValue)"'
        echo ""
        log_warn "Per-account parameter overrides:"
        _print_per_account_overrides
        echo ""
        log_warn "Dry run complete. No changes made."
        exit 0
    fi

    echo ""
    echo -e "${YELLOW}════ MIGRATION SUMMARY ════${NC}"
    echo ""
    echo "  StackSet (old) : ${STACKSET_NAME}"
    echo "  StackSet (new) : ${NEW_STACKSET_NAME:-$STACKSET_NAME}"
    echo "  Template       : ${V300_TEMPLATE_URL}"
    echo ""
    echo "  Instances to migrate:"
    echo "$INSTANCES_JSON" | jq -r '.[] | "    \(.account) / \(.region)  (alias: \(.alias))"'
    echo ""
    echo "  Shared base parameters (same for all accounts):"
    echo "$_shared_params" | jq -r '.[] | "    \(.ParameterKey) = \(.ParameterValue)"'
    echo ""
    echo "  Per-account parameter overrides (alias + S3 buckets captured from Sumo sources):"
    _print_per_account_overrides
    echo ""
    echo -e "${RED}WARNING: This will DELETE all stack instances and the StackSet, then recreate.${NC}"
    echo ""
    read -r -p "Type 'yes' to proceed: " confirm
    if [[ "$confirm" != "yes" ]]; then
        log_warn "Aborted by user."
        exit 0
    fi

    _mark_phase_done "confirm"
}

# ============================================================
# Phase 5 — Update RemoveOnDeleteStack=false
# ============================================================
phase_update_rod() {
    log_phase "Phase 5: Set RemoveOnDeleteStack=false on all instances"

    if _phase_done "update_rod"; then
        log_info "Already completed — skipping."
        return 0
    fi

    # One update-stack-instances call per account with only its actual regions.
    # A single call with all accounts × all regions creates a cross-product that
    # includes non-existent (account, region) pairs — StackSet skips those silently
    # and may SUCCEED before all real instances have been updated.
    local unique_accounts failed_any=0
    unique_accounts=$( echo "$INSTANCES_JSON" | jq -r '[.[].account] | unique | .[]' )

    while IFS= read -r account; do
        local regs_arr=()
        read -ra regs_arr <<< "$( echo "$INSTANCES_JSON" | jq -r \
            --arg a "$account" '[.[] | select(.account == $a) | .region] | .[]' \
            | tr '\n' ' ' )"

        log_info "  Updating RemoveOnDeleteStack=false: account ${account}, regions ${regs_arr[*]}"
        local op_id
        op_id=$( aws_cmd cloudformation update-stack-instances \
            --stack-set-name "$STACKSET_NAME" \
            --accounts "$account" \
            --regions  "${regs_arr[@]}" \
            --parameter-overrides \
                "ParameterKey=Section1eSumoLogicResourceRemoveOnDeleteStack,ParameterValue=false" \
            --operation-preferences \
                "MaxConcurrentCount=${CONCURRENCY},FailureToleranceCount=${FAILURE_TOLERANCE}" \
            --region "$HOME_REGION" \
            --output json \
            | jq -r '.OperationId' )

        log_info "  update-stack-instances operation: ${op_id}"
        local result
        result=$( wait_for_stackset_operation "$STACKSET_NAME" "$op_id" 1800 ) || true
        if [[ "$result" != "SUCCEEDED" ]]; then
            log_error "  update-stack-instances failed for account ${account}: ${result}"
            failed_any=1
        fi
    done <<< "$unique_accounts"

    if [[ "$failed_any" -eq 1 ]]; then
        log_error "RemoveOnDeleteStack update failed for one or more accounts. Fix and re-run."
        exit 1
    fi

    _mark_phase_done "update_rod"
}

# ============================================================
# Phase 6 helpers — cross-account delete-with-retain for stuck instances
# ============================================================

# Poll a stack in a member account until it reaches a terminal state.
# Uses caller-provided cross-account credentials (AKI/SAK/ST env vars).
_wait_for_stack_in_account() {
    local stack_name="$1" region="$2" timeout_secs="$3"
    local AKI="$4" SAK="$5" ST="$6"
    local elapsed=0
    while [[ $elapsed -lt $timeout_secs ]]; do
        local status
        status=$( AWS_ACCESS_KEY_ID="$AKI" AWS_SECRET_ACCESS_KEY="$SAK" AWS_SESSION_TOKEN="$ST" \
            aws cloudformation describe-stacks \
            --stack-name "$stack_name" \
            --region "$region" \
            --output json 2>/dev/null \
            | jq -r '.Stacks[0].StackStatus // "DELETE_COMPLETE"' )
        case "$status" in
            DELETE_COMPLETE|"") return 0 ;;
            DELETE_FAILED)      return 1 ;;
        esac
        sleep "$POLL_INTERVAL"
        elapsed=$(( elapsed + POLL_INTERVAL ))
    done
    log_warn "    Timed out waiting for ${stack_name} in ${region}" >&2
    return 1
}

# Delete a CloudFormation stack (and any DELETE_FAILED nested stacks) in a
# member account, retaining only the resources that block deletion (e.g.
# non-empty S3 buckets). Mirrors MigrateToV300.sh phase_delete_retain_only().
_delete_stack_with_retain() {
    local stack_name="$1" region="$2" AKI="$3" SAK="$4" ST="$5"

    local events_json
    events_json=$( AWS_ACCESS_KEY_ID="$AKI" AWS_SECRET_ACCESS_KEY="$SAK" AWS_SESSION_TOKEN="$ST" \
        aws cloudformation describe-stack-events \
        --stack-name "$stack_name" \
        --region "$region" \
        --output json 2>/dev/null ) || {
        log_warn "    Could not get events for ${stack_name} — skipping." >&2
        return 0
    }

    # Find DELETE_FAILED logical IDs in the parent stack
    local retain_ids=()
    while IFS= read -r rid; do
        [[ -n "$rid" ]] && retain_ids+=("$rid")
    done <<EOF
$( echo "$events_json" | jq -r --arg s "$stack_name" \
    '[.StackEvents[] | select(.ResourceStatus == "DELETE_FAILED") | select(.LogicalResourceId != $s) | .LogicalResourceId] | unique | .[]' )
EOF

    # Handle DELETE_FAILED nested stacks first (recurse one level)
    local nested_arns=()
    while IFS= read -r arn; do
        [[ -n "$arn" ]] && nested_arns+=("$arn")
    done <<EOF
$( echo "$events_json" | jq -r --arg s "$stack_name" \
    '[.StackEvents[] | select(.ResourceStatus == "DELETE_FAILED") | select(.ResourceType == "AWS::CloudFormation::Stack") | select(.LogicalResourceId != $s) | .PhysicalResourceId] | unique | .[]' )
EOF

    for nested_arn in "${nested_arns[@]}"; do
        local nested_name
        nested_name=$( echo "$nested_arn" | cut -d'/' -f2 )
        log_info "    Cleaning up nested stack: ${nested_name}"

        local nested_events
        nested_events=$( AWS_ACCESS_KEY_ID="$AKI" AWS_SECRET_ACCESS_KEY="$SAK" AWS_SESSION_TOKEN="$ST" \
            aws cloudformation describe-stack-events \
            --stack-name "$nested_name" --region "$region" --output json 2>/dev/null ) || {
            log_warn "    Could not get events for ${nested_name} — skipping." >&2
            continue
        }

        local nested_retain=()
        while IFS= read -r rid; do
            [[ -n "$rid" ]] && nested_retain+=("$rid")
        done <<EOF
$( echo "$nested_events" | jq -r --arg s "$nested_name" \
    '[.StackEvents[] | select(.ResourceStatus == "DELETE_FAILED") | select(.LogicalResourceId != $s) | .LogicalResourceId] | unique | .[]' )
EOF

        if [[ ${#nested_retain[@]} -gt 0 ]]; then
            log_info "    Retaining in ${nested_name}: ${nested_retain[*]}"
            AWS_ACCESS_KEY_ID="$AKI" AWS_SECRET_ACCESS_KEY="$SAK" AWS_SESSION_TOKEN="$ST" \
                aws cloudformation delete-stack \
                --stack-name "$nested_name" \
                --retain-resources "${nested_retain[@]}" \
                --region "$region" >/dev/null || true
        else
            AWS_ACCESS_KEY_ID="$AKI" AWS_SECRET_ACCESS_KEY="$SAK" AWS_SESSION_TOKEN="$ST" \
                aws cloudformation delete-stack \
                --stack-name "$nested_name" --region "$region" >/dev/null || true
        fi
        _wait_for_stack_in_account "$nested_name" "$region" 600 "$AKI" "$SAK" "$ST" || \
            log_warn "    ${nested_name} did not reach DELETE_COMPLETE — manual cleanup may be needed."
    done

    # Delete the parent stack, retaining the blocked logical IDs
    if [[ ${#retain_ids[@]} -gt 0 ]]; then
        log_info "    Deleting ${stack_name} with --retain-resources: ${retain_ids[*]}"
        AWS_ACCESS_KEY_ID="$AKI" AWS_SECRET_ACCESS_KEY="$SAK" AWS_SESSION_TOKEN="$ST" \
            aws cloudformation delete-stack \
            --stack-name "$stack_name" \
            --retain-resources "${retain_ids[@]}" \
            --region "$region" >/dev/null || true
    else
        log_info "    Deleting ${stack_name}"
        AWS_ACCESS_KEY_ID="$AKI" AWS_SECRET_ACCESS_KEY="$SAK" AWS_SESSION_TOKEN="$ST" \
            aws cloudformation delete-stack \
            --stack-name "$stack_name" --region "$region" >/dev/null || true
    fi
    _wait_for_stack_in_account "$stack_name" "$region" 600 "$AKI" "$SAK" "$ST" || \
        log_warn "    ${stack_name} did not reach DELETE_COMPLETE — manual cleanup may be needed."
}

# Called when delete-stack-instances FAILED or had partial failures.
# FAILED instances: stack is in DELETE_FAILED state — needs cross-account
#   retain-resource cleanup, then removed from StackSet with --retain-stacks.
# CANCELLED instances: stack is untouched — retried directly with --no-retain-stacks.
_cleanup_failed_delete_instances() {
    local op_id="$1"

    local op_results_json
    op_results_json=$( aws_cmd cloudformation list-stack-set-operation-results \
        --stack-set-name "$STACKSET_NAME" \
        --operation-id "$op_id" \
        --region "$HOME_REGION" \
        --output json )

    local failed_raw cancelled_raw
    failed_raw=$(    echo "$op_results_json" | jq -r '.Summaries[] | select(.Status == "FAILED")    | "\(.Account)/\(.Region)"' )
    cancelled_raw=$( echo "$op_results_json" | jq -r '.Summaries[] | select(.Status == "CANCELLED") | "\(.Account)/\(.Region)"' )

    if [[ -z "$failed_raw" && -z "$cancelled_raw" ]]; then
        log_info "No failed or cancelled instances — nothing to clean up."
        return 0
    fi

    # ── Step 1: Clean up FAILED instances (DELETE_FAILED stacks) ──────────────
    if [[ -n "$failed_raw" ]]; then
        log_warn "Attempting cross-account retain-resource cleanup for FAILED instances..."

        local failed_accts=() failed_regs=()
        while IFS='/' read -r acct reg; do
            [[ -n "$acct" ]] && { failed_accts+=("$acct"); failed_regs+=("$reg"); }
        done <<< "$failed_raw"

        for i in "${!failed_accts[@]}"; do
            local acct="${failed_accts[$i]}" reg="${failed_regs[$i]}"
            log_info "  Cleaning up ${acct}/${reg}..."

            local exec_role_arn="arn:aws:iam::${acct}:role/${EXECUTION_ROLE_NAME}"
            local creds
            creds=$( aws_cmd sts assume-role \
                --role-arn "$exec_role_arn" \
                --role-session-name "awso-cleanup-delete" \
                --output json 2>/dev/null ) || {
                log_warn "  Cannot assume ${exec_role_arn} — skipping ${acct}/${reg}."
                continue
            }

            local AKI SAK ST
            AKI=$( echo "$creds" | jq -r '.Credentials.AccessKeyId' )
            SAK=$( echo "$creds" | jq -r '.Credentials.SecretAccessKey' )
            ST=$(  echo "$creds" | jq -r '.Credentials.SessionToken' )

            # Get the actual stack name from the StackSet instance record
            local stack_id
            stack_id=$( aws_cmd cloudformation describe-stack-instance \
                --stack-set-name "$STACKSET_NAME" \
                --stack-instance-account "$acct" \
                --stack-instance-region  "$reg" \
                --region "$HOME_REGION" \
                --output json 2>/dev/null \
                | jq -r '.StackInstance.StackId // ""' )

            if [[ -z "$stack_id" || "$stack_id" == "null" ]]; then
                log_warn "  Could not get stack ID for ${acct}/${reg} — skipping."
                continue
            fi

            local stack_name
            stack_name=$( echo "$stack_id" | cut -d'/' -f2 )
            log_info "  Stack: ${stack_name}"
            _delete_stack_with_retain "$stack_name" "$reg" "$AKI" "$SAK" "$ST"
        done

        # Remove the now-deleted stacks from the StackSet with --retain-stacks
        log_info "Removing cleaned-up FAILED instances from StackSet (--retain-stacks)..."
        local retain_op_id
        retain_op_id=$( aws_cmd cloudformation delete-stack-instances \
            --stack-set-name "$STACKSET_NAME" \
            --accounts "${failed_accts[@]}" \
            --regions  "${failed_regs[@]}" \
            --retain-stacks \
            --operation-preferences \
                "MaxConcurrentCount=${CONCURRENCY},FailureToleranceCount=${FAILURE_TOLERANCE}" \
            --region "$HOME_REGION" \
            --output json \
            | jq -r '.OperationId' )

        log_info "Retain-stacks operation: ${retain_op_id}"
        local retain_result
        retain_result=$( wait_for_stackset_operation "$STACKSET_NAME" "$retain_op_id" "$DELETE_INSTANCES_TIMEOUT" ) || true
        if [[ "$retain_result" != "SUCCEEDED" ]]; then
            log_error "Remove FAILED instances with --retain-stacks failed: ${retain_result}"
            log_error "Resolve manually and re-run with --resume."
            exit 1
        fi
        log_info "FAILED instances removed from StackSet."
    fi

    # ── Step 2: Retry CANCELLED instances (stack is untouched) ────────────────
    # One call per account with only that account's regions to avoid duplicate
    # region entries and cross-product issues (same fix as Phase 5).
    if [[ -n "$cancelled_raw" ]]; then
        log_info "Retrying CANCELLED instances with --no-retain-stacks..."

        local cancelled_accounts
        cancelled_accounts=$( echo "$cancelled_raw" | cut -d'/' -f1 | sort -u )

        while IFS= read -r acct; do
            [[ -z "$acct" ]] && continue
            local regs_arr=()
            read -ra regs_arr <<< "$( echo "$cancelled_raw" | grep "^${acct}/" | cut -d'/' -f2 | tr '\n' ' ' )"

            log_info "  Retrying: account ${acct}, regions ${regs_arr[*]}"
            local retry_op_id
            retry_op_id=$( aws_cmd cloudformation delete-stack-instances \
                --stack-set-name "$STACKSET_NAME" \
                --accounts "$acct" \
                --regions  "${regs_arr[@]}" \
                --no-retain-stacks \
                --operation-preferences \
                    "MaxConcurrentCount=${CONCURRENCY},FailureToleranceCount=${FAILURE_TOLERANCE}" \
                --region "$HOME_REGION" \
                --output json \
                | jq -r '.OperationId' )

            log_info "  Retry operation: ${retry_op_id}"
            local retry_result
            retry_result=$( wait_for_stackset_operation "$STACKSET_NAME" "$retry_op_id" "$DELETE_INSTANCES_TIMEOUT" ) || true
            if [[ "$retry_result" != "SUCCEEDED" ]]; then
                log_warn "  Retry for account ${acct} ended with status: ${retry_result}"
                _cleanup_failed_delete_instances "$retry_op_id"
            else
                log_info "  Account ${acct} CANCELLED instances deleted successfully."
            fi
        done <<< "$cancelled_accounts"
    fi
}

# ============================================================
# Phase 6 — Delete Stack Instances
# ============================================================
phase_delete_instances() {
    log_phase "Phase 6: Delete Stack Instances"

    if _phase_done "delete_instances"; then
        log_info "Already completed — skipping."
        return 0
    fi

    local accounts regions
    accounts=$( echo "$INSTANCES_JSON" | jq -r '[.[].account] | unique | .[]' )
    regions=$(  echo "$INSTANCES_JSON" | jq -r '[.[].region]  | unique | .[]' )
    local accts_arr=() regs_arr=()
    read -ra accts_arr <<< "$( echo "$accounts" | tr '\n' ' ' )"
    read -ra regs_arr  <<< "$( echo "$regions"  | tr '\n' ' ' )"

    local op_id
    op_id=$( aws_cmd cloudformation delete-stack-instances \
        --stack-set-name "$STACKSET_NAME" \
        --accounts "${accts_arr[@]}" \
        --regions  "${regs_arr[@]}" \
        --no-retain-stacks \
        --operation-preferences \
            "MaxConcurrentCount=${CONCURRENCY},FailureToleranceCount=${FAILURE_TOLERANCE}" \
        --region "$HOME_REGION" \
        --output json \
        | jq -r '.OperationId' )

    log_info "delete-stack-instances operation: ${op_id}"
    local result
    result=$( wait_for_stackset_operation "$STACKSET_NAME" "$op_id" "$DELETE_INSTANCES_TIMEOUT" ) || true
    if [[ "$result" != "SUCCEEDED" ]]; then
        log_warn "delete-stack-instances ended with status: ${result}"
        log_info "Attempting automatic cleanup of stuck stacks (e.g. non-empty S3 buckets)..."
        _cleanup_failed_delete_instances "$op_id"
    fi

    _mark_phase_done "delete_instances"
}

# ============================================================
# Phase 7 — Delete StackSet

# ============================================================
# Phase 8 — FER Cleanup (org-level, once)
# ============================================================
_fetch_all_fers() {
    local all_fers="[]"
    local token=""
    while true; do
        local url="/api/v1/extractionRules?limit=1000"
        [[ -n "$token" ]] && url="${url}&token=${token}"
        local response
        response=$( sumo_get "$url" )
        local page_data
        page_data=$( echo "$response" | jq '.data' )
        all_fers=$( echo "$all_fers $page_data" | jq -s 'add' )
        token=$( echo "$response" | jq -r '.next.token // ""' )
        [[ -z "$token" ]] && break
    done
    echo "$all_fers"
}

phase_fer_cleanup() {
    log_phase "Phase 8: FER Cleanup"

    if _phase_done "fer_cleanup"; then
        log_info "Already completed — skipping."
        return 0
    fi

    local quota_response quota remaining
    quota_response=$( sumo_get "/api/v1/extractionRules/quota" )
    quota=$(     echo "$quota_response" | jq -r '.quota' )
    remaining=$( echo "$quota_response" | jq -r '.remaining' )
    log_info "FER quota: ${quota} total, ${remaining} remaining"

    local all_fers
    all_fers=$( _fetch_all_fers )
    local fer_names_json
    fer_names_json=$( printf '%s\n' "${AWSO_FER_NAMES[@]}" | jq -R . | jq -s . )
    local matched_fers
    matched_fers=$( echo "$all_fers" | jq --argjson names "$fer_names_json" \
        '[ .[] | select(.name as $n | $names | index($n) != null) ]' )
    local matched_count
    matched_count=$( echo "$matched_fers" | jq 'length' )
    log_info "Found ${matched_count} AWSO FER(s) to handle."

    if [[ "$matched_count" -eq 0 ]]; then
        log_info "No AWSO FERs found — nothing to clean up."
        _mark_phase_done "fer_cleanup"
        return 0
    fi

    if [[ "$remaining" -ge "$AWSO_FER_COUNT" ]]; then
        local all_fer_names
        all_fer_names=$( echo "$all_fers" | jq -r '.[].name' )

        while IFS= read -r fer_json; do
            local fer_id fer_name fer_scope fer_parse
            fer_id=$(    echo "$fer_json" | jq -r '.id' )
            fer_name=$(  echo "$fer_json" | jq -r '.name' )
            fer_scope=$( echo "$fer_json" | jq -r '.scope' )
            fer_parse=$( echo "$fer_json" | jq -r '.parseExpression' )
            local new_name="v215_backup_${fer_name}"

            if echo "$all_fer_names" | grep -qx "$new_name"; then
                log_info "  Already renamed: ${fer_name} (skipping)"
                FER_RENAMED_COUNT=$(( FER_RENAMED_COUNT + 1 ))
                continue
            fi

            local body
            body=$( jq -n \
                --arg name  "$new_name" \
                --arg scope "$fer_scope" \
                --arg parse "$fer_parse" \
                '{"name": $name, "scope": $scope, "parseExpression": $parse, "enabled": false}' )

            local put_response http_status
            put_response=$( sumo_put "/api/v1/extractionRules/${fer_id}" "$body" )
            http_status=$( echo "$put_response" | tail -1 )
            if [[ "$http_status" != "200" ]]; then
                log_error "  Failed to rename FER '${fer_name}' (HTTP ${http_status})."
                exit 1
            fi
            log_info "  Renamed: ${fer_name} → ${new_name} (disabled)"
            FER_RENAMED_COUNT=$(( FER_RENAMED_COUNT + 1 ))
        done < <( echo "$matched_fers" | jq -c '.[]' )

        log_info "FER cleanup complete. ${FER_RENAMED_COUNT} FER(s) renamed."
    else
        log_warn "FER quota too low. Remaining: ${remaining}, need: ${AWSO_FER_COUNT}."
        log_warn "Manually delete or rename these FERs, then resume with --resume --state-file ${STATE_FILE:-<state-file>}"
        echo "$matched_fers" | jq -r '.[] | "  \(.id)  \(.name)"'
        exit 2
    fi

    _mark_phase_done "fer_cleanup"
}

# ============================================================
# Phase 9 — Metric Rules Cleanup (org-level, once)
# ============================================================
phase_metric_rules_cleanup() {
    log_phase "Phase 9: Metric Rules Cleanup"

    if _phase_done "metric_rules"; then
        log_info "Already completed — skipping."
        return 0
    fi

    local deleted=0 skipped=0
    for rule_name in "${AWSO_METRIC_RULES[@]}"; do
        local http_code
        http_code=$( curl -s -o /dev/null -w "%{http_code}" --max-redirs 0 \
            -u "${ACCESS_ID}:${ACCESS_KEY}" \
            -X DELETE \
            "${SUMO_API_URL}/api/v1/metricsRules/${rule_name}" )
        case "$http_code" in
            204) log_info "  Deleted: ${rule_name}"; deleted=$(( deleted + 1 )) ;;
            404) log_info "  Not found (already removed): ${rule_name}"; skipped=$(( skipped + 1 )) ;;
            403) log_warn "  Cannot delete (403): ${rule_name}"; skipped=$(( skipped + 1 )) ;;
            *)   log_warn "  Unexpected (HTTP ${http_code}): ${rule_name}"; skipped=$(( skipped + 1 )) ;;
        esac
    done
    log_info "Metric rules: ${deleted} deleted, ${skipped} skipped."

    _mark_phase_done "metric_rules"
}

# ============================================================
# Phase 10 — Update StackSet with v3.0.0 template
# The StackSet is kept (not deleted); we update its template and base parameters
# in-place while it has 0 instances (after Phase 6 deleted them all).
# ============================================================
phase_create_stackset() {
    log_phase "Phase 10: Update StackSet to v3.0.0 Template"

    if _phase_done "create_stackset"; then
        log_info "Already completed — skipping."
        return 0
    fi

    local update_args=(
        cloudformation update-stack-set
        --stack-set-name "$STACKSET_NAME"
        --template-url  "$V300_TEMPLATE_URL"
        --parameters    "$( echo "$V300_BASE_PARAMS" | jq -c '.' )"
        --capabilities  CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND
        --region "$HOME_REGION"
        --output json
    )
    if [[ -n "$ADMIN_ROLE_ARN" ]]; then
        update_args+=( --administration-role-arn "$ADMIN_ROLE_ARN" )
    fi
    if [[ -n "$EXECUTION_ROLE_NAME" ]]; then
        update_args+=( --execution-role-name "$EXECUTION_ROLE_NAME" )
    fi

    local op_id
    op_id=$( aws_cmd "${update_args[@]}" | jq -r '.OperationId' )
    log_info "update-stack-set operation: ${op_id}"

    local result
    result=$( wait_for_stackset_operation "$STACKSET_NAME" "$op_id" 600 ) || true
    if [[ "$result" != "SUCCEEDED" ]]; then
        log_error "update-stack-set failed with status: ${result}"
        exit 1
    fi

    log_info "StackSet '${STACKSET_NAME}' updated to v3.0.0 template."
    _mark_phase_done "create_stackset"
}

# ============================================================
# Phase 11 — Create Stack Instances (one per account)
# ============================================================
phase_create_instances() {
    log_phase "Phase 11: Create Stack Instances"

    local target_name="${NEW_STACKSET_NAME:-$STACKSET_NAME}"

    if _phase_done "create_instances"; then
        log_info "Already completed — skipping."
        return 0
    fi

    # One create-stack-instances call per (account, region) — each region may have
    # different bucket names so parameter overrides cannot be shared across regions.
    while IFS= read -r inst; do
        local account region alias key
        account=$( echo "$inst" | jq -r '.account' )
        region=$(  echo "$inst" | jq -r '.region' )
        key="${account}/${region}"
        alias=$( echo "$ACCOUNT_ALIAS_MAP" | jq -r --arg a "$account" '.[$a]' )

        local bucket_alb bucket_ct bucket_elb
        bucket_alb=$( echo "$ACCOUNT_BUCKET_MAP" | jq -r --arg k "$key" '.[$k].alb        // ""' )
        bucket_ct=$(  echo "$ACCOUNT_BUCKET_MAP" | jq -r --arg k "$key" '.[$k].cloudtrail // ""' )
        bucket_elb=$( echo "$ACCOUNT_BUCKET_MAP" | jq -r --arg k "$key" '.[$k].elb        // ""' )

        local param_overrides=(
            "ParameterKey=Section2aAccountAlias,ParameterValue=${alias}"
        )
        [[ -n "$bucket_alb" ]] && \
            param_overrides+=( "ParameterKey=Section5dALBS3LogsBucketName,ParameterValue=${bucket_alb}" )
        [[ -n "$bucket_ct"  ]] && \
            param_overrides+=( "ParameterKey=Section6cCloudTrailLogsBucketName,ParameterValue=${bucket_ct}" )
        [[ -n "$bucket_elb" ]] && \
            param_overrides+=( "ParameterKey=Section8dELBS3LogsBucketName,ParameterValue=${bucket_elb}" )

        log_info "Creating instance: account ${account}, region ${region} (alias: ${alias})"
        log_info "  Bucket overrides — ALB: ${bucket_alb:-<empty>}, CloudTrail: ${bucket_ct:-<empty>}, ELB: ${bucket_elb:-<empty>}"

        local op_id
        op_id=$( aws_cmd cloudformation create-stack-instances \
            --stack-set-name "$target_name" \
            --accounts "$account" \
            --regions  "$region" \
            --parameter-overrides "${param_overrides[@]}" \
            --operation-preferences \
                "MaxConcurrentCount=1,FailureToleranceCount=${FAILURE_TOLERANCE}" \
            --region "$HOME_REGION" \
            --output json \
            | jq -r '.OperationId' )

        log_info "  create-stack-instances operation: ${op_id}"
        local result
        result=$( wait_for_stackset_operation "$target_name" "$op_id" "$CREATE_INSTANCES_TIMEOUT" ) || true
        if [[ "$result" != "SUCCEEDED" ]]; then
            log_error "create-stack-instances failed for ${account}/${region}: ${result}"
            FAILED_INSTANCES+=("${account}/${region}")
            _save_state
        fi
    done < <( echo "$INSTANCES_JSON" | jq -c '.[]' )

    if [[ ${#FAILED_INSTANCES[@]} -gt 0 ]]; then
        log_error "The following accounts failed to create instances: ${FAILED_INSTANCES[*]}"
        log_error "Fix the issues and resume with --resume --state-file ${STATE_FILE}"
        exit 1
    fi

    _mark_phase_done "create_instances"
}

# ============================================================
# Phase 12 — Verify
# ============================================================
phase_verify() {
    log_phase "Phase 12: Verify All Instances"

    if _phase_done "verify"; then
        log_info "Already completed — skipping."
        return 0
    fi

    local target_name="${NEW_STACKSET_NAME:-$STACKSET_NAME}"

    local raw_instances="[]"
    local next_token=""
    while true; do
        local args=( cloudformation list-stack-instances
            --stack-set-name "$target_name"
            --region "$HOME_REGION"
            --output json )
        [[ -n "$next_token" ]] && args+=( --next-token "$next_token" )
        local page
        page=$( aws_cmd "${args[@]}" )
        raw_instances=$( echo "$raw_instances $( echo "$page" | jq '.Summaries' )" | jq -s 'add' )
        next_token=$( echo "$page" | jq -r '.NextToken // ""' )
        [[ -z "$next_token" ]] && break
    done

    local total failed
    total=$( echo "$raw_instances" | jq 'length' )
    failed=$( echo "$raw_instances" | jq '[.[] | select(.Status != "CURRENT" and .Status != "SUCCEEDED")] | length' )

    log_info "Instances: ${total} total, $((total - failed)) healthy, ${failed} not CURRENT."

    if [[ "$failed" -gt 0 ]]; then
        log_warn "Some instances are not CURRENT:"
        echo "$raw_instances" | jq -r '.[] | select(.Status != "CURRENT" and .Status != "SUCCEEDED") | "  \(.Account)/\(.Region): \(.Status) \(.StatusReason // "")"'
    else
        log_info "All instances are CURRENT."
    fi

    _mark_phase_done "verify"
}

# ============================================================
# Phase 13 — Patch Source Role ARNs (per account/region)
# ============================================================
phase_patch_role_arns() {
    log_phase "Phase 13: Patch Sumo Source Role ARNs"

    if _phase_done "patch_role_arns"; then
        log_info "Already completed — skipping."
        return 0
    fi

    local target_name="${NEW_STACKSET_NAME:-$STACKSET_NAME}"

    # Process each unique account
    local accounts
    accounts=$( echo "$INSTANCES_JSON" | jq -r '[.[].account] | unique | .[]' )

    while IFS= read -r account; do
        local regions_for_account=()
        read -ra regions_for_account <<< "$( echo "$INSTANCES_JSON" | jq -r \
            --arg a "$account" '.[] | select(.account == $a) | .region' | tr '\n' ' ' )"

        log_info "Patching sources in account ${account}..."

        # Assume execution role in member account
        local exec_role_arn="arn:aws:iam::${account}:role/${EXECUTION_ROLE_NAME}"
        local creds
        creds=$( aws_cmd sts assume-role \
            --role-arn "$exec_role_arn" \
            --role-session-name "awso-patch-roles" \
            --output json 2>/dev/null ) || {
            log_warn "  Cannot assume ${exec_role_arn} — skipping account ${account}."
            continue
        }

        local AKI SAK ST
        AKI=$( echo "$creds" | jq -r '.Credentials.AccessKeyId' )
        SAK=$( echo "$creds" | jq -r '.Credentials.SecretAccessKey' )
        ST=$(  echo "$creds" | jq -r '.Credentials.SessionToken' )

        for region in "${regions_for_account[@]}"; do
            log_info "  Region: ${region}"

            # Find the stack in this account/region.
            # list-stack-instances is a management-account StackSet API — use aws_cmd
            # (management credentials), not the member account's cross-account creds.
            local stack_name
            stack_name=$( aws_cmd cloudformation list-stack-instances \
                --stack-set-name "$target_name" \
                --stack-instance-account "$account" \
                --stack-instance-region  "$region" \
                --region "$HOME_REGION" \
                --output json 2>/dev/null \
                | jq -r '.Summaries[0].StackId // ""' )

            [[ -z "$stack_name" ]] && { log_warn "    No stack found for ${account}/${region} — skipping."; continue; }

            # Find CreateCommonResources nested stack
            local nested_stack_id
            nested_stack_id=$( AWS_ACCESS_KEY_ID="$AKI" AWS_SECRET_ACCESS_KEY="$SAK" AWS_SESSION_TOKEN="$ST" \
                aws cloudformation list-stack-resources \
                --stack-name "$stack_name" \
                --region "$region" \
                --output json 2>/dev/null \
                | jq -r '
                    .StackResourceSummaries[]
                    | select(.LogicalResourceId == "CreateCommonResources")
                    | .PhysicalResourceId' )

            [[ -z "$nested_stack_id" || "$nested_stack_id" == "null" ]] && {
                log_warn "    CreateCommonResources not found in ${account}/${region} — skipping."
                continue
            }

            # Get new IAM role ARN from nested stack
            local role_name
            role_name=$( AWS_ACCESS_KEY_ID="$AKI" AWS_SECRET_ACCESS_KEY="$SAK" AWS_SESSION_TOKEN="$ST" \
                aws cloudformation describe-stack-resource \
                --stack-name "$nested_stack_id" \
                --logical-resource-id SumoLogicSourceRole \
                --region "$region" \
                --output json 2>/dev/null \
                | jq -r '.StackResourceDetail.PhysicalResourceId // ""' )

            [[ -z "$role_name" || "$role_name" == "null" ]] && {
                log_warn "    SumoLogicSourceRole not found in ${account}/${region} — skipping."
                continue
            }

            local new_role_arn="arn:aws:iam::${account}:role/${role_name}"
            log_info "    New role ARN: ${new_role_arn}"

            # Find the Sumo collector for this account
            local alias
            alias=$( echo "$ACCOUNT_ALIAS_MAP" | jq -r --arg a "$account" '.[$a]' )
            local expected_collector="aws-observability-${alias}-${account}"
            local collector_id
            collector_id=$( sumo_get "/api/v1/collectors?name=${expected_collector}" \
                | jq -r '.collectors[] | select(.name == "'"$expected_collector"'") | .id' 2>/dev/null | head -1 )

            if [[ -z "$collector_id" ]]; then
                # Fallback: must match BOTH startswith("aws-observability") AND endswith("-{account}")
                local _offset=0
                while true; do
                    local _page
                    _page=$( sumo_get "/api/v1/collectors?limit=1000&offset=${_offset}" )
                    collector_id=$( echo "$_page" | jq -r --arg acct "$account" \
                        '[.collectors[] | select(
                            (.name | startswith("aws-observability")) and
                            (.name | endswith("-" + $acct))
                        )] | .[0].id // ""' )
                    [[ -n "$collector_id" ]] && break
                    local _returned
                    _returned=$( echo "$_page" | jq '.collectors | length' )
                    [[ "$_returned" -lt 1000 ]] && break
                    _offset=$(( _offset + 1000 ))
                done
            fi

            if [[ -z "$collector_id" ]]; then
                log_warn "    aws-observability collector not found for account ${account} — skipping."
                continue
            fi
            log_info "    Collector ID: ${collector_id}"

            # List sources and patch stale roleARNs
            local sources_json
            sources_json=$( sumo_get "/api/v1/collectors/${collector_id}/sources" )

            local stale_ids
            stale_ids=$( echo "$sources_json" | jq -r --arg new_arn "$new_role_arn" --arg region "$region" '
                .sources[]
                | select(
                    (.name | contains($region)) and
                    .thirdPartyRef.resources != null and
                    (.thirdPartyRef.resources[].authentication.roleARN? // "" | . != "" and . != $new_arn)
                  )
                | .id' )

            if [[ -z "$stale_ids" ]]; then
                log_info "    All sources already have the correct role ARN."
                continue
            fi

            local header_file
            header_file=$( mktemp /tmp/awso_ss_headers_XXXXXX )
            TEMP_FILES+=("$header_file")

            while IFS= read -r source_id; do
                local source_name
                source_name=$( echo "$sources_json" | jq -r --argjson id "$source_id" \
                    '.sources[] | select(.id == $id) | .name' )

                local body etag
                body=$( sumo_get_with_etag "/api/v1/collectors/${collector_id}/sources/${source_id}" "$header_file" )
                etag=$( grep -i '^etag:' "$header_file" | tr -d '\r' | awk '{print $2}' )

                if [[ -z "$etag" ]]; then
                    log_warn "    No ETag for source '${source_name}' — skipping."
                    continue
                fi

                local patched_body
                patched_body=$( echo "$body" | jq --arg new_arn "$new_role_arn" \
                    '.source.thirdPartyRef.resources[].authentication.roleARN = $new_arn' )

                local put_response http_status
                put_response=$( sumo_put_if_match \
                    "/api/v1/collectors/${collector_id}/sources/${source_id}" \
                    "$patched_body" "$etag" )
                http_status=$( echo "$put_response" | tail -1 )

                if [[ "$http_status" == "200" ]]; then
                    log_info "    Patched: ${source_name} (${source_id})"
                    SOURCES_PATCHED=$(( SOURCES_PATCHED + 1 ))
                else
                    log_warn "    Failed to patch '${source_name}' — HTTP ${http_status}"
                fi
            done <<< "$stale_ids"
        done
    done <<< "$accounts"

    log_info "Role ARN patch complete. ${SOURCES_PATCHED} source(s) updated."
    _mark_phase_done "patch_role_arns"
}

# ============================================================
# Phase 14 — Report
# ============================================================
phase_report() {
    log_phase "Phase 14: Migration Summary"
    local target_name="${NEW_STACKSET_NAME:-$STACKSET_NAME}"
    local total_instances
    total_instances=$( echo "$INSTANCES_JSON" | jq 'length' )
    local unique_accounts unique_regions
    unique_accounts=$( echo "$INSTANCES_JSON" | jq -r '[.[].account] | unique | length' )
    unique_regions=$(  echo "$INSTANCES_JSON" | jq -r '[.[].region]  | unique | length' )
    echo ""
    echo -e "${GREEN}  StackSet (old)  : ${STACKSET_NAME}${NC}"
    echo -e "${GREEN}  StackSet (new)  : ${target_name}${NC}"
    echo -e "${GREEN}  Home region     : ${HOME_REGION}${NC}"
    echo -e "${GREEN}  Template        : v3.0.0${NC}"
    echo -e "${GREEN}  Accounts        : ${unique_accounts}${NC}"
    echo -e "${GREEN}  Regions         : ${unique_regions}${NC}"
    echo -e "${GREEN}  Instances       : ${total_instances}${NC}"
    echo -e "${GREEN}  FERs renamed    : ${FER_RENAMED_COUNT}${NC}"
    echo -e "${GREEN}  Sources patched : ${SOURCES_PATCHED}${NC}"
    echo -e "${GREEN}  Log file        : ${LOG_FILE}${NC}"
    echo ""
}

# ============================================================
# Help
# ============================================================
help_text() {
    cat <<EOF

Usage: $0 -d DEPLOYMENT -i ACCESS_ID -k ACCESS_KEY -o ORG_ID -r REGION [OPTIONS]

Required:
  -d DEPLOYMENT          Sumo Logic deployment (us1, us2, kr, eu, de, au, jp, ca, ch, fed, esc)
  -i ACCESS_ID           Sumo Logic access ID
  -k ACCESS_KEY          Sumo Logic access key
  -o ORG_ID              Sumo Logic org ID
  -r REGION              AWS home region where the StackSet is registered (e.g. us-east-1)

Optional:
  --stackset-name NAME       Existing StackSet name (default: SUMO-LOGIC-AWS-OBSERVABILITY)
  --new-stackset-name NAME   New StackSet name after migration (default: same as old)
  --admin-role-arn ARN       StackSet admin role ARN (auto-detected from existing StackSet)
  --execution-role NAME      StackSet execution role name (auto-detected, default: AWSControlTowerExecution)
  -p AWS_PROFILE             AWS CLI profile (default: default)
  --install-apps YES|NO      Install Sumo Logic apps in v3.0.0 (default: No)
  --concurrency N            MaxConcurrentCount for StackSet operations (default: 1)
  --failure-tolerance N      FailureToleranceCount for StackSet operations (default: 0)
  --dry-run                  Enumerate instances and map params without making changes
  --resume                   Resume from a previous partial run
  --state-file PATH          Path to state JSON file (auto-generated if not specified)
  --from-phase PHASE         With --resume: restart from this phase (clears it and all subsequent phases)
                             Phases: validate enumerate map_params confirm update_rod delete_instances
                                     fer_cleanup metric_rules create_stackset
                                     create_instances verify patch_role_arns
  --patch-roles-only         Skip to phase 13 (patch Sumo source role ARNs only)
  -h, --help                 Show this help

Examples:
  # Full migration
  $0 -d us2 -i suXXX -k XXXXX -o 0000000000000004 -r us-east-1

  # Dry run
  $0 -d us2 -i suXXX -k XXXXX -o 0000000000000004 -r us-east-1 --dry-run

  # Resume from where it stopped
  $0 -d us2 -i suXXX -k XXXXX -o 0000000000000004 -r us-east-1 --resume \\
     --state-file ./awso_stackset_migration_20260825_120000.json

  # Force restart from a specific phase (e.g. re-run FER cleanup and everything after)
  $0 -d us2 -i suXXX -k XXXXX -o 0000000000000004 -r us-east-1 --resume \\
     --state-file ./awso_stackset_migration_20260825_120000.json --from-phase fer_cleanup

EOF
}

# ============================================================
# Argument Parsing
# ============================================================
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d)                  DEPLOYMENT="$2";         shift 2 ;;
            -i)                  ACCESS_ID="$2";           shift 2 ;;
            -k)                  ACCESS_KEY="$2";          shift 2 ;;
            -o)                  ORG_ID="$2";              shift 2 ;;
            -r)                  HOME_REGION="$2";         shift 2 ;;
            --stackset-name)     STACKSET_NAME="$2";       shift 2 ;;
            --new-stackset-name) NEW_STACKSET_NAME="$2";   shift 2 ;;
            --admin-role-arn)    ADMIN_ROLE_ARN="$2";      shift 2 ;;
            --execution-role)    EXECUTION_ROLE_NAME="$2"; shift 2 ;;
            -p)                  AWS_PROFILE="$2";         shift 2 ;;
            --install-apps)      INSTALL_APPS="$2";        shift 2 ;;
            --concurrency)       CONCURRENCY="$2";         shift 2 ;;
            --failure-tolerance) FAILURE_TOLERANCE="$2";   shift 2 ;;
            --dry-run)           DRY_RUN=true;             shift ;;
            --resume)            RESUME=true;              shift ;;
            --state-file)        STATE_FILE="$2";          shift 2 ;;
            --from-phase)        FROM_PHASE="$2"; RESUME=true; shift 2 ;;
            --patch-roles-only)  PATCH_ROLES_ONLY=true; RESUME=true; shift ;;
            -h|--help)           help_text; exit 0 ;;
            *) echo "Unknown option: $1"; help_text; exit 1 ;;
        esac
    done

    local missing=""
    [[ -z "$DEPLOYMENT" ]]  && missing="$missing -d DEPLOYMENT"
    [[ -z "$ACCESS_ID" ]]   && missing="$missing -i ACCESS_ID"
    [[ -z "$ACCESS_KEY" ]]  && missing="$missing -k ACCESS_KEY"
    [[ -z "$ORG_ID" ]]      && missing="$missing -o ORG_ID"
    [[ -z "$HOME_REGION" ]] && missing="$missing -r REGION"
    if [[ -n "$missing" ]]; then
        echo -e "${RED}Missing required arguments:${missing}${NC}"
        help_text
        exit 1
    fi
}

# ============================================================
# Main
# ============================================================
main() {
    parse_args "$@"

    SUMO_API_URL=$( get_sumo_api_url "$DEPLOYMENT" )

    # Default state file
    if [[ -z "$STATE_FILE" ]]; then
        STATE_FILE="./awso_stackset_migration_$( date +%Y%m%d_%H%M%S ).json"
    fi

    # If the specified state file already exists and --resume was not explicitly
    # passed, auto-enable resume so we don't overwrite it with empty values.
    if [[ -f "$STATE_FILE" && "$RESUME" == false ]]; then
        log_warn "State file '${STATE_FILE}' already exists — automatically enabling --resume."
        RESUME=true
    fi

    # Log file
    LOG_FILE="./migration_stackset_$( date +%Y%m%d_%H%M%S ).log"

    echo -e "${BLUE}AWSO StackSet Migration v${SCRIPT_VERSION}${NC}"
    echo -e "${BLUE}Log file: ${LOG_FILE}${NC}"
    echo ""

    # Load state if resuming
    if [[ "$RESUME" == true ]]; then
        _load_state
        # --from-phase resets progress to force re-run from a specific phase
        [[ -n "$FROM_PHASE" ]] && _reset_from_phase "$FROM_PHASE"
    fi

    # Set new stackset name default
    [[ -z "$NEW_STACKSET_NAME" ]] && NEW_STACKSET_NAME="$STACKSET_NAME"

    if [[ "$PATCH_ROLES_ONLY" == true ]]; then
        phase_patch_role_arns
        phase_report
        return 0
    fi

    phase_validate
    phase_enumerate
    phase_map_params
    phase_confirm
    phase_update_rod
    phase_delete_instances
    phase_fer_cleanup
    phase_metric_rules_cleanup
    phase_create_stackset
    phase_create_instances
    phase_verify
    phase_patch_role_arns
    phase_report

    log_info "Migration complete."
}

main "$@"
