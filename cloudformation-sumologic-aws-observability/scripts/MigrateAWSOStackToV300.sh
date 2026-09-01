#!/bin/bash
set -euo pipefail

# ============================================================
# AWSO Migration Script: v2.x → v3.0.0
# ============================================================
# Automates the validated migration path:
#   Phase 1:  Validate prerequisites and stack state
#   Phase 2:  Capture collector, sources, and S3 bucket names from Sumo
#   Phase 3:  Map v2.x parameters to v3.0.0 format
#   Phase 4:  Confirm all details + v3.0.0 params + destructive actions (user approval gate)
#   Phase 5:  Ensure RemoveOnDeleteStack=false (stack update)
#   Phase 6:  Delete v2.x stack (normal → force on bucket failure)
#   Phase 7:  FER cleanup (rename+disable 17 AWSO FERs)
#   Phase 8:  Metric rules cleanup (delete 4 AWSO metric rules)
#   Phase 9:  Deploy v3.0.0 stack with mapped parameters
#   Phase 10: Verify deployment and Sumo Logic sources
#   Phase 11: Patch Sumo source roleARNs to the new v3.0.0 IAM role
#   Phase 12: Report summary
#
# Dependencies: bash, aws cli, jq, curl

SCRIPT_VERSION="1.0.0"
V300_TEMPLATE_URL="https://sumologic-appdev-aws-sam-apps.s3.us-east-1.amazonaws.com/aws-observability-versions/v3.0.0/templates/sumologic_observability.master.template.yaml"
UPDATE_TIMEOUT=1800   # 30 minutes (large stacks with many nested stacks take time)
DELETE_TIMEOUT=1800   # 30 minutes
CREATE_TIMEOUT=2700   # 45 minutes
POLL_INTERVAL=30
AWSO_FER_COUNT=17     # number of FERs v3.0.0 will try to create

# Exact AWSO FER names — only these are touched, never user-created FERs
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

# Exact AWSO Metric Rule names — deleted during migration
AWSO_METRIC_RULES=(
    "AwsObservabilityRDSClusterMetricsEntityRule"
    "AwsObservabilityRDSInstanceMetricsEntityRule"
    "AwsObservabilityNLBMetricsEntityRule"
    "AwsObservabilityApiGatewayApiNameMetricsEntityRule"
)

# ---- Colours ----
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

_log_to_file() { sed 's/\x1b\[[0-9;]*m//g' >> "$LOG_FILE"; }
_ts() { date '+%Y-%m-%d %H:%M:%S'; }
log_info()  { echo -e "${GREEN}[INFO]${NC}  [$( _ts )] $*" | tee >( _log_to_file ); }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  [$( _ts )] $*" | tee >( _log_to_file ); }
log_error() { echo -e "${RED}[ERROR]${NC} [$( _ts )] $*" | tee >( _log_to_file ); }
log_phase() {
    echo -e "\n${BLUE}════════════════════════════════════════${NC}" | tee >( _log_to_file )
    echo -e "${BLUE}  [$( _ts )] $*${NC}" | tee >( _log_to_file )
    echo -e "${BLUE}════════════════════════════════════════${NC}" | tee >( _log_to_file )
}

# ---- Input globals ----
DEPLOYMENT=""
ACCESS_ID=""
ACCESS_KEY=""
ORG_ID=""
STACK_NAME=""
REGION=""
SOURCE_VERSION=""
NEW_STACK_NAME=""
AWS_PROFILE="default"
INSTALL_APPS="Yes"
DRY_RUN=false
RESUME=false
RESUME_PARAMS_FILE=""
PATCH_ROLES_ONLY=false

# ---- Runtime globals ----
LOG_FILE="/dev/null"   # overwritten in main() once STACK_NAME is known
TEMP_PARAM_FILE=""
PERSIST_PARAM_FILE=""
SUMO_API_URL=""
STACK_JSON=""
CAPTURED_BUCKET_ALB=""
CAPTURED_BUCKET_CLOUDTRAIL=""
CAPTURED_BUCKET_ELB=""
CAPTURED_SOURCES_JSON=""
FER_RENAMED_COUNT=0
ACCOUNT_ID=""
COLLECTOR_ID=""
COLLECTOR_NAME=""
SOURCES_PATCHED=0

# ---- Cleanup ----
cleanup() {
    if [[ -n "$TEMP_PARAM_FILE" && -f "$TEMP_PARAM_FILE" ]]; then
        rm -f "$TEMP_PARAM_FILE"
    fi
}
trap cleanup EXIT

# ============================================================
# Helpers
# ============================================================

help_text() {
    cat <<EOF

Usage: $0 -d DEPLOYMENT -i ACCESS_ID -k ACCESS_KEY -o ORG_ID -s STACK_NAME -r REGION [OPTIONS]

Required (normal run):
  -d DEPLOYMENT        Sumo Logic deployment (us1, us2, kr, eu, de, au, jp, ca, ch, fed, esc)
  -i ACCESS_ID         Sumo Logic access ID
  -k ACCESS_KEY        Sumo Logic access key
  -o ORG_ID            Sumo Logic org ID
  -s STACK_NAME        Existing AWSO v2.x stack name to migrate
  -r REGION            AWS region (e.g. us-east-1, us-west-2)

Required (resume run):
  --resume             Resume from Phase 7 (cleanup + deploy), skipping phases 1-6
  --params-file PATH   Path to the saved params JSON (printed when FER limit is exceeded)
  -d -i -k -o -r       Still required for credential validation

Optional:
  -v SOURCE_VERSION    Source version: 2.15, 2.14, 2.13, 2.12 (auto-detected if omitted)
  -n NEW_STACK_NAME    v3.0.0 stack name (defaults to STACK_NAME)
  -p AWS_PROFILE       AWS CLI profile (default: default)
  --install-apps YES|NO  Install Sumo Logic apps (default: Yes)
  --dry-run            Show mapped parameters without making any changes
  -h, --help           Show this help

Examples:
  # Full migration
  $0 -d kr -i suXXXXX -k XXXXX -o 0000000000000004 -s my-awso-stack -r us-west-2

  # Dry run to preview mapped parameters
  $0 -d kr -i suXXXXX -k XXXXX -o 0000000000000004 -s my-awso-stack -r us-west-2 --dry-run

  # Resume after manual FER cleanup
  $0 --resume -d kr -i suXXXXX -k XXXXX -o 0000000000000004 -r us-west-2 \\
    -n my-awso-stack --params-file ./migration_params_my-awso-stack_20260703_120000.json

EOF
}

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
    # On macOS, aws is often only in the login shell PATH (installed via brew/pip).
    # On Linux, aws is typically in PATH already so we call it directly.
    if [[ "$(uname)" == "Darwin" ]]; then
        /bin/zsh -l -c 'aws --profile "$1" "${@:2}"' _ "${AWS_PROFILE}" "$@"
    else
        aws --profile "${AWS_PROFILE}" "$@"
    fi
}

sumo_get() {
    # Usage: sumo_get /api/v1/path
    local path="$1"
    curl -s --max-redirs 0 \
        -u "${ACCESS_ID}:${ACCESS_KEY}" \
        -H "Accept: application/json" \
        "${SUMO_API_URL}${path}"
}

sumo_put() {
    # Usage: sumo_put /api/v1/path '{"json":"body"}'
    # Returns the HTTP status code on the last line, response body on preceding lines.
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
    # Usage: sumo_get_with_etag /api/v1/path /tmp/headers_file
    # Writes response headers to header_file; returns body on stdout.
    local path="$1" header_file="$2"
    curl -s --max-redirs 0 \
        -D "$header_file" \
        -u "${ACCESS_ID}:${ACCESS_KEY}" \
        -H "Accept: application/json" \
        "${SUMO_API_URL}${path}"
}

sumo_put_if_match() {
    # Usage: sumo_put_if_match /api/v1/path '{"json":"body"}' '"etag-value"'
    # Returns the HTTP status code on the last line, response body on preceding lines.
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

# Sets COLLECTOR_ID and COLLECTOR_NAME globals to the aws-observability collector for this stack.
# If Section2aAccountAlias is available in STACK_JSON, matches exactly: aws-observability-{alias}-{AccountId}
# Otherwise falls back to: startswith("aws-observability") and endswith("-{AccountId}")
# Returns 0 if found, 1 if not found after paginating all pages.
find_awso_collector() {
    COLLECTOR_ID="" COLLECTOR_NAME=""

    local alias
    alias=$( echo "$STACK_JSON" | jq -r '
        [.Stacks[0].Parameters[] | select(.ParameterKey == "Section2aAccountAlias")]
        | .[0].ParameterValue // ""' 2>/dev/null || echo "" )

    local offset=0
    while true; do
        local page
        page=$( sumo_get "/api/v1/collectors?limit=1000&offset=${offset}" )

        if [[ -n "$alias" && "$alias" != "null" ]]; then
            local expected_name="aws-observability-${alias}-${ACCOUNT_ID}"
            COLLECTOR_ID=$( echo "$page" | jq -r --arg name "$expected_name" '
                [.collectors[] | select(.name == $name)] | .[0].id // ""' )
            if [[ -n "$COLLECTOR_ID" && "$COLLECTOR_ID" != "null" ]]; then
                COLLECTOR_NAME="$expected_name"
                return 0
            fi
        else
            COLLECTOR_ID=$( echo "$page" | jq -r --arg acct "$ACCOUNT_ID" '
                [.collectors[] | select(
                    (.name | startswith("aws-observability")) and
                    (.name | endswith("-" + $acct))
                )] | .[0].id // ""' )
            if [[ -n "$COLLECTOR_ID" && "$COLLECTOR_ID" != "null" ]]; then
                COLLECTOR_NAME=$( echo "$page" | jq -r --arg acct "$ACCOUNT_ID" '
                    [.collectors[] | select(
                        (.name | startswith("aws-observability")) and
                        (.name | endswith("-" + $acct))
                    )] | .[0].name // ""' )
                return 0
            fi
        fi

        local count
        count=$( echo "$page" | jq '.collectors | length' )
        [[ "$count" -lt 1000 ]] && break
        offset=$(( offset + 1000 ))
    done
    return 1
}

# Poll a CF stack until terminal state or timeout.
# Echoes the final status string to stdout; all progress messages go to stderr.
# Returns 0 on success terminal states, 1 on failure/timeout.
wait_for_stack() {
    local stack="$1" timeout="$2"
    local elapsed=0
    while [[ $elapsed -lt $timeout ]]; do
        local out
        out=$( aws_cmd cloudformation describe-stacks --stack-name "${stack}" --region "${REGION}" --output json 2>&1 ) || true

        if echo "$out" | grep -q "does not exist"; then
            echo "DELETE_COMPLETE"; return 0
        fi

        local status
        status=$( echo "$out" | jq -r '.Stacks[0].StackStatus' 2>/dev/null || echo "UNKNOWN" )

        case "$status" in
            CREATE_COMPLETE|UPDATE_COMPLETE|DELETE_COMPLETE)
                echo "$status"; return 0 ;;
            CREATE_FAILED|ROLLBACK_COMPLETE|ROLLBACK_FAILED|\
            UPDATE_ROLLBACK_COMPLETE|UPDATE_ROLLBACK_FAILED|DELETE_FAILED)
                echo "$status"; return 1 ;;
        esac

        # Send progress to stderr so command-substitution callers only capture the final status
        log_info "  Stack status: ${status} (${elapsed}s / ${timeout}s elapsed)" >&2
        sleep $POLL_INTERVAL
        elapsed=$(( elapsed + POLL_INTERVAL ))
    done
    echo "TIMEOUT"; return 1
}

# ============================================================
# Phase 0 — Assumption: v2.x stack is already deployed
# ============================================================
# This script assumes a v2.x (v2.12–v2.15) AWSO stack is already
# deployed and in CREATE_COMPLETE or UPDATE_COMPLETE state.
# The stack must have:
#   - A working Sumo Logic collector with 5 sources
#   - S3 bucket(s) for log storage
#   - Valid Sumo API credentials (access ID/key) with admin access

# ============================================================
# Phase 1 — Validate
# ============================================================
phase_validate() {
    log_phase "Phase 1: Validate Prerequisites"

    # Check dependencies
    for cmd in jq curl; do
        command -v "$cmd" >/dev/null 2>&1 || { log_error "'$cmd' is required but not installed."; exit 1; }
    done
    aws_cmd --version >/dev/null 2>&1 || { log_error "aws CLI not found in PATH."; exit 1; }
    log_info "Dependencies: OK"

    # Validate deployment value
    case "$DEPLOYMENT" in
        us1|us2|eu|de|au|jp|ca|kr|fed|ch|esc) ;;
        stag) log_error "'stag' is not supported by v3.0.0 (removed; use 'esc' or another deployment)."; exit 1 ;;
        *)    log_error "Unknown deployment: ${DEPLOYMENT}"; exit 1 ;;
    esac
    SUMO_API_URL=$( get_sumo_api_url "$DEPLOYMENT" )

    # Validate AWS credentials and capture account ID
    local identity_json
    identity_json=$( aws_cmd sts get-caller-identity --region "${REGION}" --output json 2>&1 ) \
        || { log_error "AWS credentials invalid or profile '${AWS_PROFILE}' not found."; exit 1; }
    ACCOUNT_ID=$( echo "$identity_json" | jq -r '.Account' )
    log_info "AWS credentials: OK (account: ${ACCOUNT_ID})"

    # Validate Sumo Logic credentials
    local http_code
    http_code=$( curl -s -o /dev/null -w "%{http_code}" \
        -u "${ACCESS_ID}:${ACCESS_KEY}" "${SUMO_API_URL}/api/v1/collectors?limit=1" )
    case "$http_code" in
        200) log_info "Sumo Logic credentials: OK" ;;
        401) log_error "Sumo Logic credentials invalid (HTTP 401). Check -i/-k values."; exit 1 ;;
        *)   log_error "Sumo Logic API returned HTTP ${http_code}. Check -d deployment value."; exit 1 ;;
    esac

    # In resume mode we skip the stack checks
    if [[ "$RESUME" == true ]]; then
        log_info "Resume mode — skipping stack validation."
        [[ -z "$SOURCE_VERSION" ]] && SOURCE_VERSION="unknown"
        return 0
    fi

    # Fetch and validate the stack
    local out
    out=$( aws_cmd cloudformation describe-stacks --stack-name "${STACK_NAME}" --region "${REGION}" --output json 2>&1 ) || {
        # Stack not found — could be DELETE_COMPLETE after a Phase 6 timeout.
        # If a params file from a previous Phase 3 run exists, auto-resume from Phase 7.
        local -a param_files=()
        while IFS= read -r f; do param_files+=("$f"); done \
            < <( ls -t ./migration_params_${NEW_STACK_NAME}_*.json 2>/dev/null )
        if [[ ${#param_files[@]} -eq 0 ]]; then
            log_error "Stack '${STACK_NAME}' not found in region '${REGION}'."; exit 1
        fi

        log_warn "Stack '${STACK_NAME}' not found — it was deleted while the script was not running."
        local found_params
        if [[ ${#param_files[@]} -eq 1 ]]; then
            found_params="${param_files[0]}"
            log_warn "Found saved params file: ${found_params}"
        else
            log_warn "Multiple saved params files found for stack '${NEW_STACK_NAME}':"
            local i
            for i in "${!param_files[@]}"; do
                log_warn "  [$((i+1))] ${param_files[$i]}"
            done
            local choice
            read -r -p "Which params file to use? (1-${#param_files[@]}): " choice
            if ! [[ "$choice" =~ ^[0-9]+$ ]] || \
               [[ "$choice" -lt 1 ]] || \
               [[ "$choice" -gt ${#param_files[@]} ]]; then
                log_error "Invalid selection. Aborting."; exit 1
            fi
            found_params="${param_files[$((choice-1))]}"
            log_info "Using: ${found_params}"
        fi

        log_warn "Auto-resuming from Phase 7 (FER cleanup + deploy)..."
        RESUME=true
        RESUME_PARAMS_FILE="$found_params"
        PERSIST_PARAM_FILE="$found_params"
        return 0
    }
    STACK_JSON="$out"

    local stack_status
    stack_status=$( echo "$STACK_JSON" | jq -r '.Stacks[0].StackStatus' )
    case "$stack_status" in
        CREATE_COMPLETE|UPDATE_COMPLETE|UPDATE_ROLLBACK_COMPLETE)
            log_info "Stack status: ${stack_status}" ;;
        DELETE_IN_PROGRESS)
            log_warn "Stack '${STACK_NAME}' is already deleting (DELETE_IN_PROGRESS)."
            log_warn "The script exited mid-Phase 6 (timeout or Ctrl+C). Waiting for deletion..."
            local delete_status
            delete_status=$( wait_for_stack "$STACK_NAME" "$DELETE_TIMEOUT" ) || true
            if [[ "$delete_status" != "DELETE_COMPLETE" ]]; then
                log_error "Stack deletion ended with status: ${delete_status}"
                log_error "Resolve the issue manually, then use --resume to continue."
                exit 1
            fi
            log_info "Stack deletion completed — auto-continuing to Phase 7 (FER cleanup + deploy)."

            # Find the params file saved by a previous Phase 3 run for this stack
            local -a di_param_files=()
            while IFS= read -r f; do di_param_files+=("$f"); done \
                < <( ls -t ./migration_params_${NEW_STACK_NAME}_*.json 2>/dev/null )
            if [[ ${#di_param_files[@]} -eq 0 ]]; then
                log_error "Could not find a saved params file for stack '${NEW_STACK_NAME}'."
                log_error "Re-run the full migration from the start (stack is already deleted,"
                log_error "so you will need to re-deploy v3.0.0 manually or use --resume with"
                log_error "a params file if you have one from a previous run)."
                exit 1
            fi
            local found_params
            if [[ ${#di_param_files[@]} -eq 1 ]]; then
                found_params="${di_param_files[0]}"
                log_info "Using saved params file: ${found_params}"
            else
                log_warn "Multiple saved params files found for stack '${NEW_STACK_NAME}':"
                local i
                for i in "${!di_param_files[@]}"; do
                    log_warn "  [$((i+1))] ${di_param_files[$i]}"
                done
                local choice
                read -r -p "Which params file to use? (1-${#di_param_files[@]}): " choice
                if ! [[ "$choice" =~ ^[0-9]+$ ]] || \
                   [[ "$choice" -lt 1 ]] || \
                   [[ "$choice" -gt ${#di_param_files[@]} ]]; then
                    log_error "Invalid selection. Aborting."; exit 1
                fi
                found_params="${di_param_files[$((choice-1))]}"
                log_info "Using: ${found_params}"
            fi
            RESUME=true
            RESUME_PARAMS_FILE="$found_params"
            PERSIST_PARAM_FILE="$found_params"
            # Fall through — main() will detect RESUME=true and run phases 7-12
            return 0 ;;
        DELETE_FAILED)
            log_warn "Stack '${STACK_NAME}' is in DELETE_FAILED state — retrying delete with retain resources..."
            STACK_JSON="$out"
            phase_delete_retain_only
            log_info "Stack deleted — auto-continuing to Phase 7 (FER cleanup + deploy)."

            local -a df_param_files=()
            while IFS= read -r f; do df_param_files+=("$f"); done \
                < <( ls -t ./migration_params_${NEW_STACK_NAME}_*.json 2>/dev/null )
            if [[ ${#df_param_files[@]} -eq 0 ]]; then
                log_error "Could not find a saved params file for stack '${NEW_STACK_NAME}'."
                log_error "Re-run the full migration from the start or use --resume with a params file."
                exit 1
            fi
            local df_found_params="${df_param_files[0]}"
            log_info "Using saved params file: ${df_found_params}"
            RESUME=true
            RESUME_PARAMS_FILE="$df_found_params"
            PERSIST_PARAM_FILE="$df_found_params"
            return 0 ;;
        *)
            log_error "Stack '${STACK_NAME}' is in status '${stack_status}'. Expected CREATE_COMPLETE or UPDATE_COMPLETE."
            exit 1 ;;
    esac

    # Auto-detect source version if not provided
    if [[ -z "$SOURCE_VERSION" ]]; then
        # Primary: parse "Version - vX.Y.Z" from the stack Description field
        local description detected_version
        description=$( echo "$STACK_JSON" | jq -r '.Stacks[0].Description // ""' )
        detected_version=$( echo "$description" | grep -oE 'v2\.[0-9]+\.[0-9]+' | head -1 | sed 's/^v//' | cut -d. -f1-2 )

        if [[ -n "$detected_version" ]]; then
            SOURCE_VERSION="$detected_version"
        else
            # Fallback: parameter fingerprint — all v2.12–v2.15 share the same keys,
            # so this only confirms it's a supported v2.x stack, not which minor version.
            local has_section10 has_lambda_section7 has_section9
            has_section10=$( echo "$STACK_JSON" | jq -r '
                [.Stacks[0].Parameters[].ParameterKey]
                | if index("Section10aAppInstallLocation") then "yes" else "no" end' )
            has_lambda_section7=$( echo "$STACK_JSON" | jq -r '
                [.Stacks[0].Parameters[].ParameterKey]
                | if index("Section7aLambdaCreateCloudWatchLogsSourceOptions") then "yes" else "no" end' )
            has_section9=$( echo "$STACK_JSON" | jq -r '
                [.Stacks[0].Parameters[].ParameterKey]
                | if index("Section9aAutoEnableS3LogsELBResourcesOptions") then "yes" else "no" end' )

            if [[ "$has_section10" == "yes" && "$has_lambda_section7" == "yes" && "$has_section9" == "yes" ]]; then
                SOURCE_VERSION="2.15"
                log_warn "Could not detect exact version from stack description — assuming v2.15 (parameter names are identical for v2.12–v2.15). Use -v to override."
            else
                log_error "Could not auto-detect source version. Please specify with -v (e.g. -v 2.14)."
                exit 1
            fi
        fi
        log_info "Auto-detected source version: v${SOURCE_VERSION}"
    else
        log_info "Source version: v${SOURCE_VERSION} (user-specified)"
    fi

    log_info "Validation complete."
}

# ============================================================
# Phase 2 — Capture Sumo Source Details
# ============================================================
phase_capture() {
    log_phase "Phase 2: Capture Sumo Source Details"

    # Find the AWSO collector
    if ! find_awso_collector; then
        log_error "Could not find aws-observability collector in Sumo Logic."
        exit 1
    fi
    log_info "Collector: ${COLLECTOR_NAME} (ID: ${COLLECTOR_ID})"

    # Cross-check the collector ID against the CF stack's custom resource.
    # The SumoLogicHostedCollector custom resource in the CreateCommonResources
    # nested stack stores the actual Sumo collector ID as its PhysicalResourceId.
    local cf_nested_stack_id
    cf_nested_stack_id=$( aws_cmd cloudformation list-stack-resources \
        --stack-name "${STACK_NAME}" --region "${REGION}" --output json 2>/dev/null \
        | jq -r '
            .StackResourceSummaries[]
            | select(.LogicalResourceId == "CreateCommonResources")
            | .PhysicalResourceId // ""' )

    if [[ -n "$cf_nested_stack_id" && "$cf_nested_stack_id" != "null" ]]; then
        local cf_collector_id
        # PhysicalResourceId is "SumoLogicHostedCollector/<id>" — strip the prefix
        cf_collector_id=$( aws_cmd cloudformation list-stack-resources \
            --stack-name "${cf_nested_stack_id}" --region "${REGION}" --output json 2>/dev/null \
            | jq -r '
                .StackResourceSummaries[]
                | select(.LogicalResourceId == "SumoLogicHostedCollector")
                | .PhysicalResourceId // ""
                | split("/")[-1]' )

        if [[ -n "$cf_collector_id" && "$cf_collector_id" != "null" ]]; then
            if [[ "$COLLECTOR_ID" == "$cf_collector_id" ]]; then
                log_info "Collector ID cross-check: Sumo API and CF stack agree (${COLLECTOR_ID}) ✓"
            else
                log_warn "Collector ID mismatch!"
                log_warn "  Found via Sumo API: ${COLLECTOR_ID} (${COLLECTOR_NAME})"
                log_warn "  Recorded in CF stack: ${cf_collector_id}"
                log_warn "  The collector found in Sumo Logic does not match the one created by this CF stack."
                log_warn "  This may mean the wrong Sumo credentials were provided, or the collector"
                log_warn "  was recreated outside of CloudFormation."
                while true; do
                    read -r -p "Options: (1) Use Sumo API collector (${COLLECTOR_ID}), (2) Enter correct collector ID, (3) Abort: " _coll_choice
                    case "$_coll_choice" in
                        1)
                            log_info "Using Sumo API collector: ${COLLECTOR_ID}"; break ;;
                        2)
                            read -r -p "Enter correct collector ID: " _manual_id
                            if [[ "$_manual_id" =~ ^[0-9]+$ ]]; then
                                COLLECTOR_ID="$_manual_id"
                                log_info "Using manually provided collector ID: ${COLLECTOR_ID}"; break
                            else
                                log_warn "Invalid collector ID — must be numeric. Try again."
                            fi ;;
                        3)
                            log_error "Migration aborted by user."; exit 1 ;;
                        *)
                            log_warn "Invalid choice. Enter 1, 2, or 3." ;;
                    esac
                done
            fi
        else
            log_warn "Could not read SumoLogicHostedCollector from nested stack — skipping collector cross-check."
        fi
    else
        log_warn "Could not find CreateCommonResources nested stack — skipping collector cross-check."
    fi

    # Fetch all sources on the collector
    CAPTURED_SOURCES_JSON=$( sumo_get "/api/v1/collectors/${COLLECTOR_ID}/sources" )

    # Log all source details
    local source_count
    source_count=$( echo "$CAPTURED_SOURCES_JSON" | jq '.sources | length' )
    log_info "Sources found: ${source_count}"
    log_info "Source details:"

    local src_id src_name src_type
    while IFS= read -r src_line; do
        src_id=$(   echo "$src_line" | jq -r '.id' )
        src_name=$( echo "$src_line" | jq -r '.name' )
        src_type=$( echo "$src_line" | jq -r '.sourceType' )
        log_info "  [${src_id}] ${src_name} (${src_type})"
    done < <( echo "$CAPTURED_SOURCES_JSON" | jq -c '.sources[]' )

    # Extract bucket names from S3 sources
    CAPTURED_BUCKET_ALB=$( echo "$CAPTURED_SOURCES_JSON" | jq -r '
        [.sources[] | select(.name | startswith("alb-logs"))
        | .thirdPartyRef.resources[0].path.bucketName // ""][0] // ""' )
    CAPTURED_BUCKET_CLOUDTRAIL=$( echo "$CAPTURED_SOURCES_JSON" | jq -r '
        [.sources[] | select(.name | startswith("cloudtrail-logs"))
        | .thirdPartyRef.resources[0].path.bucketName // ""][0] // ""' )
    CAPTURED_BUCKET_ELB=$( echo "$CAPTURED_SOURCES_JSON" | jq -r '
        [.sources[] | select(.name | startswith("classic-lb-logs"))
        | .thirdPartyRef.resources[0].path.bucketName // ""][0] // ""' )

    # Verify each bucket exists and is accessible
    for bucket in "$CAPTURED_BUCKET_ALB" "$CAPTURED_BUCKET_CLOUDTRAIL" "$CAPTURED_BUCKET_ELB"; do
        if [[ -n "$bucket" ]]; then
            aws_cmd s3api head-bucket --bucket "${bucket}" --region "${REGION}" >/dev/null 2>&1 \
                || log_warn "Bucket '${bucket}' not accessible — proceeding anyway."
        fi
    done

    log_info "ALB bucket:        ${CAPTURED_BUCKET_ALB:-<empty>}"
    log_info "CloudTrail bucket: ${CAPTURED_BUCKET_CLOUDTRAIL:-<empty>}"
    log_info "ELB bucket:        ${CAPTURED_BUCKET_ELB:-<empty>}"

    # Cross-check Sumo bucket names against the CF stack parameters.
    # Sumo is the source of truth — mismatches are warnings only, not errors.
    local cf_bucket_alb cf_bucket_cloudtrail cf_bucket_elb
    cf_bucket_alb=$(        echo "$STACK_JSON" | jq -r '
        [.Stacks[0].Parameters[] | select(.ParameterKey == "Section5dALBS3LogsBucketName")]
        | .[0].ParameterValue // ""' )
    cf_bucket_cloudtrail=$( echo "$STACK_JSON" | jq -r '
        [.Stacks[0].Parameters[] | select(.ParameterKey == "Section6cCloudTrailLogsBucketName")]
        | .[0].ParameterValue // ""' )
    cf_bucket_elb=$(        echo "$STACK_JSON" | jq -r '
        [.Stacks[0].Parameters[] | select(.ParameterKey == "Section9dELBS3LogsBucketName")]
        | .[0].ParameterValue // ""' )

    local mismatch=false
    _check_bucket_mismatch() {
        local label="$1" sumo_val="$2" cf_val="$3"
        if [[ -n "$sumo_val" && -n "$cf_val" && "$sumo_val" != "$cf_val" ]]; then
            log_warn "  ${label}: Sumo='${sumo_val}'  CF='${cf_val}'"
            mismatch=true
        elif [[ -z "$sumo_val" && -n "$cf_val" ]]; then
            log_warn "  ${label}: Sumo source has no bucket configured, but CF stack has '${cf_val}'"
            mismatch=true
        fi
    }
    _check_bucket_mismatch "ALB bucket      " "$CAPTURED_BUCKET_ALB"        "$cf_bucket_alb"
    _check_bucket_mismatch "CloudTrail bkt  " "$CAPTURED_BUCKET_CLOUDTRAIL" "$cf_bucket_cloudtrail"
    _check_bucket_mismatch "ELB bucket      " "$CAPTURED_BUCKET_ELB"        "$cf_bucket_elb"

    if [[ "$mismatch" == true ]]; then
        log_warn "Bucket name mismatch detected between Sumo sources and CF stack parameters."
        log_warn "The Sumo source values above will be used for migration (source of truth)."
        log_warn "Verify the Sumo source configs are correct before proceeding."
    else
        log_info "Bucket cross-check: Sumo sources and CF stack parameters agree."
    fi
}

# ============================================================
# Phase 3 — Map Parameters
# ============================================================

map_params_v215() {
    local v2_params="$1"
    echo "$v2_params" | jq \
        --arg bucket_alb        "$CAPTURED_BUCKET_ALB" \
        --arg bucket_cloudtrail "$CAPTURED_BUCKET_CLOUDTRAIL" \
        --arg bucket_elb        "$CAPTURED_BUCKET_ELB" \
        --arg install_apps      "$INSTALL_APPS" \
        --arg access_id         "$ACCESS_ID" \
        --arg access_key        "$ACCESS_KEY" \
        '
        # Step 1: Remove Section10 params (not in v3.0.0)
        [ .[] | select(
            .ParameterKey != "Section10aAppInstallLocation" and
            .ParameterKey != "Section10bShare"
        )] |

        # Step 2: Rename parameters
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

        # Step 3: Override values
        # For bucket params: only populate if the corresponding create flag is "Yes" —
        # if the source was not installed in v2.x, keep the bucket empty so v3.0.0 also skips it.
        (map(select(.ParameterKey == "Section5bALBCreateLogSource")          | .ParameterValue) | first // "No") as $alb_enabled |
        (map(select(.ParameterKey == "Section6aCreateCloudTrailLogSource")   | .ParameterValue) | first // "No") as $ct_enabled  |
        (map(select(.ParameterKey == "Section8bELBCreateLogSource")          | .ParameterValue) | first // "No") as $elb_enabled |

        [ .[] | .ParameterValue = (
            if   .ParameterKey == "Section5dALBS3LogsBucketName"                    then (if $alb_enabled == "Yes" then $bucket_alb        else "" end)
            elif .ParameterKey == "Section6cCloudTrailLogsBucketName"               then (if $ct_enabled  == "Yes" then $bucket_cloudtrail  else "" end)
            elif .ParameterKey == "Section8dELBS3LogsBucketName"                    then (if $elb_enabled == "Yes" then $bucket_elb         else "" end)
            elif .ParameterKey == "Section1eSumoLogicResourceRemoveOnDeleteStack"   then "false"
            elif .ParameterKey == "Section1bSumoLogicAccessID"                      then $access_id
            elif .ParameterKey == "Section1cSumoLogicAccessKey"                     then $access_key
            elif .ParameterKey == "Section3aInstallObservabilityApps"               then $install_apps
            # Clear source URL params — using "create new" mode, not "existing"
            elif .ParameterKey == "Section4cCloudWatchExistingSourceAPIUrl"         then ""
            elif .ParameterKey == "Section5cALBLogsSourceUrl"                       then ""
            elif .ParameterKey == "Section6bCloudTrailLogsSourceUrl"                then ""
            elif .ParameterKey == "Section7bCloudWatchLogsSourceUrl"                then ""
            elif .ParameterKey == "Section8cELBLogsSourceUrl"                       then ""
            else .ParameterValue
            end
        )]
        '
}

map_params_v214() { map_params_v215 "$1"; }
map_params_v213() { map_params_v215 "$1"; }
map_params_v212() { map_params_v215 "$1"; }

phase_map_parameters() {
    log_phase "Phase 3: Map Parameters v${SOURCE_VERSION} → v3.0.0"

    local v2_params
    v2_params=$( echo "$STACK_JSON" | jq '.Stacks[0].Parameters' )

    local v300_params
    case "$SOURCE_VERSION" in
        2.15) v300_params=$( map_params_v215 "$v2_params" ) ;;
        2.14) v300_params=$( map_params_v214 "$v2_params" ) ;;
        2.13) v300_params=$( map_params_v213 "$v2_params" ) ;;
        2.12) v300_params=$( map_params_v212 "$v2_params" ) ;;
        *)    log_error "Unsupported source version: ${SOURCE_VERSION}"; exit 1 ;;
    esac

    local param_count
    param_count=$( echo "$v300_params" | jq 'length' )
    if [[ "$param_count" -eq 0 ]]; then
        log_error "Parameter mapping produced an empty array — check source stack parameters."
        exit 1
    fi
    log_info "Mapped ${param_count} parameters."

    if [[ "$DRY_RUN" == true ]]; then
        log_info "──── DRY RUN: Mapped Parameters ────"
        echo "$v300_params" | jq -r '.[] | "  \(.ParameterKey): \(.ParameterValue)"'
        log_info "──── DRY RUN complete. No changes made. ────"
        exit 0
    fi

    # Save params to a temp file (cleaned up on exit)
    TEMP_PARAM_FILE=$( mktemp /tmp/awso_migration_params_XXXXXX )
    echo "$v300_params" > "$TEMP_PARAM_FILE"

    # Also save to a persistent file so --resume works if we exit early
    PERSIST_PARAM_FILE="./migration_params_${NEW_STACK_NAME}_$( date +%Y%m%d_%H%M%S ).json"
    echo "$v300_params" > "$PERSIST_PARAM_FILE"
    chmod 600 "$PERSIST_PARAM_FILE"
    log_info "Params saved to: ${PERSIST_PARAM_FILE}"
}

# ============================================================
# Phase 4 — Confirm Migration Details
# ============================================================
phase_confirm() {
    log_phase "Phase 4: Confirm Migration Details"

    echo ""
    log_info "═══════════════════════════════════════════════════════════════"
    log_info "  MIGRATION SUMMARY — Please verify before proceeding"
    log_info "═══════════════════════════════════════════════════════════════"

    # --- Stack details ---
    echo ""
    log_info "  Stack to migrate:"
    log_info "    Name:    ${STACK_NAME}"
    log_info "    Region:  ${REGION}"
    log_info "    Account: ${ACCOUNT_ID}"
    log_info "    Version: v${SOURCE_VERSION}"

    # --- Collector & sources ---
    echo ""
    log_info "  Sumo Logic Collector:"
    log_info "    Name: ${COLLECTOR_NAME}"
    log_info "    ID:   ${COLLECTOR_ID}"
    echo ""
    log_info "  Sources on collector:"
    local src_id src_name src_type
    while IFS= read -r src_line; do
        src_id=$(   echo "$src_line" | jq -r '.id' )
        src_name=$( echo "$src_line" | jq -r '.name' )
        src_type=$( echo "$src_line" | jq -r '.sourceType' )
        log_info "    [${src_id}] ${src_name} (${src_type})"
    done < <( echo "$CAPTURED_SOURCES_JSON" | jq -c '.sources[]' )

    # --- Bucket names ---
    echo ""
    log_info "  S3 Buckets (read from Sumo Logic source configs — verify these match your actual AWS buckets):"
    log_info "    ALB bucket:        ${CAPTURED_BUCKET_ALB:-<not found>}"
    log_info "    CloudTrail bucket: ${CAPTURED_BUCKET_CLOUDTRAIL:-<not found>}"
    log_info "    ELB bucket:        ${CAPTURED_BUCKET_ELB:-<not found>}"
    log_warn "  ⚠  Bucket names are read from Sumo source configs and cross-checked"
    log_warn "     against the CF stack parameters (Phase 2). Any mismatch was flagged"
    log_warn "     above. If all clear, confirm the buckets exist in AWS:"
    [[ -n "$CAPTURED_BUCKET_CLOUDTRAIL" ]] && \
        log_warn "     aws s3 ls s3://${CAPTURED_BUCKET_CLOUDTRAIL} --region ${REGION}"
    [[ -n "$CAPTURED_BUCKET_ALB" ]] && \
        log_warn "     aws s3 ls s3://${CAPTURED_BUCKET_ALB} --region ${REGION}"
    [[ -n "$CAPTURED_BUCKET_ELB" ]] && \
        log_warn "     aws s3 ls s3://${CAPTURED_BUCKET_ELB} --region ${REGION}"

    # --- v3.0.0 deployment params ---
    echo ""
    log_info "  v3.0.0 Deployment Parameters:"
    log_info "    New stack name:    ${NEW_STACK_NAME}"
    log_info "    Template:          ${V300_TEMPLATE_URL}"
    log_info "    Deployment:        ${DEPLOYMENT}"
    log_info "    Install apps:      ${INSTALL_APPS}"
    log_info "    Source mode:       Create New (reuses existing sources by name)"
    log_info "    ALB bucket:        ${CAPTURED_BUCKET_ALB:-<auto>}  ← confirm this bucket exists in AWS"
    log_info "    CloudTrail bucket: ${CAPTURED_BUCKET_CLOUDTRAIL:-<auto>}  ← confirm this bucket exists in AWS"
    log_info "    ELB bucket:        ${CAPTURED_BUCKET_ELB:-<auto>}  ← confirm this bucket exists in AWS"
    log_info "    Params file:       ${PERSIST_PARAM_FILE}"

    # --- Destructive actions ---
    echo ""
    log_warn "═══════════════════════════════════════════════════════════════"
    log_warn "  The following PERMANENT changes will be made:"
    log_warn "═══════════════════════════════════════════════════════════════"
    echo ""
    log_warn "  1. UPDATE stack '${STACK_NAME}' to set RemoveOnDeleteStack=false"
    log_warn "     (ensures Sumo collector/sources survive stack deletion)"
    echo ""
    log_warn "  2. DELETE CloudFormation stack '${STACK_NAME}' in region '${REGION}'"
    log_warn "     (after RemoveOnDeleteStack=false — Sumo resources will be preserved)"
    echo ""
    log_warn "  3. RENAME and DISABLE ${#AWSO_FER_NAMES[@]} AWSO Field Extraction Rules:"
    local fer_name
    for fer_name in "${AWSO_FER_NAMES[@]}"; do
        log_warn "       ${fer_name} → v215_backup_${fer_name}"
    done
    echo ""
    log_warn "  4. DELETE ${#AWSO_METRIC_RULES[@]} AWSO Metric Rules:"
    local rule_name
    for rule_name in "${AWSO_METRIC_RULES[@]}"; do
        log_warn "       ${rule_name}"
    done
    echo ""
    log_warn "═══════════════════════════════════════════════════════════════"
    log_warn "  Please verify the above and take a backup if needed."
    log_warn "  FERs can be exported from: Manage Data > Logs > Field Extraction Rules"
    log_warn "  Metric rules can be viewed at: Manage Data > Metrics > Metrics Rules"
    log_warn "═══════════════════════════════════════════════════════════════"
    echo ""
    read -r -p "Proceed with migration? Type 'yes' to continue: " confirm
    if [[ "$confirm" != "yes" ]]; then
        log_info "Migration aborted by user."; exit 0
    fi
    echo ""
}

# ============================================================
# Phase 5 — Ensure RemoveOnDeleteStack is false
# ============================================================
phase_ensure_remove_on_delete() {
    log_phase "Phase 5: Ensure RemoveOnDeleteStack=false"

    local remove_on_delete
    remove_on_delete=$( echo "$STACK_JSON" | jq -r '
        .Stacks[0].Parameters[]
        | select(.ParameterKey == "Section1eSumoLogicResourceRemoveOnDeleteStack")
        | .ParameterValue' )

    if [[ "$remove_on_delete" == "false" ]]; then
        log_info "RemoveOnDeleteStack: false — Sumo resources will be preserved on delete"
        return 0
    fi

    log_info "RemoveOnDeleteStack is '${remove_on_delete}' — updating to 'false'..."
    local update_params_file
    update_params_file=$( mktemp /tmp/awso_update_params_XXXXXX )
    echo "$STACK_JSON" | jq \
        --arg access_id  "$ACCESS_ID" \
        --arg access_key "$ACCESS_KEY" \
        '[.Stacks[0].Parameters[]
        | if   .ParameterKey == "Section1eSumoLogicResourceRemoveOnDeleteStack"
          then {"ParameterKey": .ParameterKey, "ParameterValue": "false"}
          elif .ParameterKey == "Section1bSumoLogicAccessID"
          then {"ParameterKey": .ParameterKey, "ParameterValue": $access_id}
          elif .ParameterKey == "Section1cSumoLogicAccessKey"
          then {"ParameterKey": .ParameterKey, "ParameterValue": $access_key}
          else {"ParameterKey": .ParameterKey, "UsePreviousValue": true}
          end]' > "$update_params_file"

    aws_cmd cloudformation update-stack \
        --stack-name "${STACK_NAME}" \
        --region "${REGION}" \
        --use-previous-template \
        --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
        --parameters "file://${update_params_file}" \
        >/dev/null || { rm -f "$update_params_file"; log_error "Stack update failed. Check your IAM permissions and stack state."; exit 1; }
    rm -f "$update_params_file"

    log_info "Waiting for stack update to complete (timeout: ${UPDATE_TIMEOUT}s)..."
    local update_status
    update_status=$( wait_for_stack "$STACK_NAME" "$UPDATE_TIMEOUT" ) || true
    if [[ "$update_status" != "UPDATE_COMPLETE" ]]; then
        log_error "Stack update ended with status: ${update_status}"; exit 1
    fi
    log_info "Stack updated. RemoveOnDeleteStack is now false."

    # Re-fetch updated stack JSON
    STACK_JSON=$( aws_cmd cloudformation describe-stacks --stack-name "${STACK_NAME}" --region "${REGION}" --output json )
}

# Delete orphaned nested stacks (DELETE_FAILED) whose names start with "<parent_stack>-".
# These are left behind when the parent was deleted with --retain-resources.
cleanup_orphaned_nested_stacks() {
    local parent="$1"
    local orphans=()
    while IFS= read -r name; do
        [[ -n "$name" ]] && orphans+=( "$name" )
    done <<EOF
$( aws_cmd cloudformation list-stacks \
    --region "${REGION}" \
    --stack-status-filter DELETE_FAILED \
    --output json 2>/dev/null \
  | jq -r --arg prefix "${parent}-" \
    '[.StackSummaries[] | select(.StackName | startswith($prefix)) | .StackName] | .[]' )
EOF

    if [[ ${#orphans[@]} -eq 0 ]]; then
        log_info "No orphaned nested stacks found for '${parent}'."
        return 0
    fi

    local orphan
    for orphan in "${orphans[@]}"; do
        log_warn "Found orphaned nested stack: ${orphan} — cleaning up..."

        local orphan_events
        orphan_events=$( aws_cmd cloudformation describe-stack-events \
            --stack-name "$orphan" --region "${REGION}" --output json 2>/dev/null ) || {
            log_warn "  Could not describe events for ${orphan} — skipping."
            continue
        }

        local orphan_retain_ids=()
        while IFS= read -r rid; do
            [[ -n "$rid" ]] && orphan_retain_ids+=( "$rid" )
        done <<EOF
$( echo "$orphan_events" | jq -r --arg stack "$orphan" '
    [.StackEvents[] | select(.ResourceStatus == "DELETE_FAILED") | select(.LogicalResourceId != $stack) | .LogicalResourceId]
    | unique | .[]' )
EOF

        if [[ ${#orphan_retain_ids[@]} -gt 0 ]]; then
            log_info "  Retaining in ${orphan}: ${orphan_retain_ids[*]}"
            aws_cmd cloudformation delete-stack \
                --stack-name "$orphan" \
                --retain-resources "${orphan_retain_ids[@]}" \
                --region "${REGION}" >/dev/null || true
        else
            aws_cmd cloudformation delete-stack \
                --stack-name "$orphan" \
                --region "${REGION}" >/dev/null || true
        fi

        local orphan_status
        orphan_status=$( wait_for_stack "$orphan" "$DELETE_TIMEOUT" ) || true
        if [[ "$orphan_status" == "DELETE_COMPLETE" ]]; then
            log_info "  ${orphan}: deleted."
        else
            log_warn "  ${orphan}: ended with status ${orphan_status} — manual cleanup required."
        fi
    done
}

# Shared helper: delete a DELETE_FAILED stack using --retain-resources for blocked logical IDs.
# Caller must ensure the stack is in DELETE_FAILED state before calling.
phase_delete_retain_only() {
    local events_json
    events_json=$( aws_cmd cloudformation describe-stack-events \
        --stack-name "${STACK_NAME}" --region "${REGION}" --output json )

    local failed_display
    failed_display=$( echo "$events_json" | jq -r '
        [.StackEvents[] | select(.ResourceStatus == "DELETE_FAILED")]
        | sort_by(.Timestamp)
        | .[]
        | "  \(.LogicalResourceId): \(.ResourceStatusReason // "")"' )

    log_warn "Stack DELETE_FAILED. Retaining blocked resources and deleting the rest:"
    echo "$failed_display" | tee -a "$LOG_FILE"

    local retain_ids=()
    while IFS= read -r rid; do
        [[ -n "$rid" ]] && retain_ids+=( "$rid" )
    done <<EOF
$( echo "$events_json" | jq -r --arg stack "$STACK_NAME" '[.StackEvents[] | select(.ResourceStatus == "DELETE_FAILED") | select(.LogicalResourceId != $stack) | .LogicalResourceId] | unique | .[]' )
EOF

    log_info "Initiating delete with retain resources: ${retain_ids[*]}"
    aws_cmd cloudformation delete-stack \
        --stack-name "${STACK_NAME}" \
        --retain-resources "${retain_ids[@]}" \
        --region "${REGION}" >/dev/null

    log_info "Waiting for delete with retain resources (timeout: ${DELETE_TIMEOUT}s)..."
    local retain_status
    retain_status=$( wait_for_stack "$STACK_NAME" "$DELETE_TIMEOUT" ) || true

    if [[ "$retain_status" != "DELETE_COMPLETE" ]]; then
        log_error "Delete with retain resources ended with status: ${retain_status}"
        log_error "Resolve the issue manually and use --resume to continue."
        exit 1
    fi

    log_info "Main stack deleted. Cleaning up retained nested stacks..."

    # For each retained resource that is a nested stack, delete it too
    local nested_arns=()
    while IFS= read -r arn; do
        [[ -n "$arn" ]] && nested_arns+=( "$arn" )
    done <<EOF
$( echo "$events_json" | jq -r --arg stack "$STACK_NAME" '
    [.StackEvents[]
    | select(.ResourceStatus == "DELETE_FAILED")
    | select(.ResourceType == "AWS::CloudFormation::Stack")
    | select(.LogicalResourceId != $stack)
    | .PhysicalResourceId] | unique | .[]' )
EOF

    local nested_arn
    for nested_arn in "${nested_arns[@]}"; do
        local nested_name
        nested_name=$( echo "$nested_arn" | cut -d'/' -f2 )
        log_info "Deleting retained nested stack: ${nested_name}"

        local nested_events_json
        nested_events_json=$( aws_cmd cloudformation describe-stack-events \
            --stack-name "$nested_name" --region "${REGION}" --output json 2>/dev/null ) || {
            log_warn "Could not describe events for ${nested_name} — skipping."
            continue
        }

        local nested_retain_ids=()
        while IFS= read -r rid; do
            [[ -n "$rid" ]] && nested_retain_ids+=( "$rid" )
        done <<EOF
$( echo "$nested_events_json" | jq -r --arg stack "$nested_name" '
    [.StackEvents[] | select(.ResourceStatus == "DELETE_FAILED") | select(.LogicalResourceId != $stack) | .LogicalResourceId]
    | unique | .[]' )
EOF

        if [[ ${#nested_retain_ids[@]} -gt 0 ]]; then
            log_info "  Retaining in nested stack: ${nested_retain_ids[*]}"
            aws_cmd cloudformation delete-stack \
                --stack-name "$nested_name" \
                --retain-resources "${nested_retain_ids[@]}" \
                --region "${REGION}" >/dev/null || true
        else
            aws_cmd cloudformation delete-stack \
                --stack-name "$nested_name" \
                --region "${REGION}" >/dev/null || true
        fi

        local nested_status
        nested_status=$( wait_for_stack "$nested_name" "$DELETE_TIMEOUT" ) || true
        if [[ "$nested_status" == "DELETE_COMPLETE" ]]; then
            log_info "  ${nested_name}: deleted."
        else
            log_warn "  ${nested_name}: ended with status ${nested_status} — manual cleanup required."
        fi
    done
}

# ============================================================
# Phase 6 — Delete v2.x Stack
# ============================================================
phase_delete() {
    log_phase "Phase 6: Delete v${SOURCE_VERSION} Stack"

    log_info "Initiating stack deletion..."
    aws_cmd cloudformation delete-stack \
        --stack-name "${STACK_NAME}" \
        --region "${REGION}" >/dev/null

    log_info "Waiting for deletion (timeout: ${DELETE_TIMEOUT}s)..."
    local final_status
    final_status=$( wait_for_stack "$STACK_NAME" "$DELETE_TIMEOUT" ) || true

    if [[ "$final_status" == "DELETE_COMPLETE" ]]; then
        log_info "Stack deleted successfully."; return 0
    fi

    if [[ "$final_status" == "DELETE_FAILED" ]]; then
        phase_delete_retain_only; return $?
    fi

    if [[ "$final_status" == "TIMEOUT" ]]; then
        log_warn "Stack deletion timed out — it is still in progress in AWS."
        log_warn "Once deletion completes, re-run the same command and the script will"
        log_warn "automatically detect the completed deletion and continue from Phase 7."
    else
        log_error "Stack deletion ended with unexpected status: ${final_status}"
    fi
    exit 1
}

# ============================================================
# Phase 7 — FER Cleanup
# ============================================================

# Fetch all FERs with pagination, return JSON array
fetch_all_fers() {
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
    log_phase "Phase 7: FER Cleanup"

    # In resume mode, check if FERs were already renamed in a previous run
    if [[ "$RESUME" == true ]]; then
        log_info "Resume mode — checking if FER cleanup was already done..."
        local all_fers_check
        all_fers_check=$( fetch_all_fers )
        local fer_names_check
        fer_names_check=$( printf '%s\n' "${AWSO_FER_NAMES[@]}" | jq -R . | jq -s . )
        local active_count
        active_count=$( echo "$all_fers_check" | jq --argjson names "$fer_names_check" \
            '[ .[] | select(.name as $n | $names | index($n) != null) ] | length' )
        if [[ "$active_count" -eq 0 ]]; then
            log_info "No active AWSO FERs found — cleanup already done in previous run. Skipping."
            return 0
        fi
        log_info "Found ${active_count} active AWSO FER(s) — proceeding with cleanup."
    fi

    # Check FER quota
    local quota_response
    quota_response=$( sumo_get "/api/v1/extractionRules/quota" )
    local quota remaining
    quota=$( echo "$quota_response" | jq -r '.quota' )
    remaining=$( echo "$quota_response" | jq -r '.remaining' )
    log_info "FER quota: ${quota} total, ${remaining} remaining"

    # Fetch all FERs and find exact AWSO matches
    log_info "Fetching existing FERs..."
    local all_fers
    all_fers=$( fetch_all_fers )

    # Build jq-compatible array of known AWSO FER names for exact matching
    local fer_names_json
    fer_names_json=$( printf '%s\n' "${AWSO_FER_NAMES[@]}" | jq -R . | jq -s . )

    local matched_fers
    matched_fers=$( echo "$all_fers" | jq --argjson names "$fer_names_json" \
        '[ .[] | select(.name as $n | $names | index($n) != null) ]' )

    local matched_count
    matched_count=$( echo "$matched_fers" | jq 'length' )
    log_info "Found ${matched_count} AWSO FER(s) to handle."

    if [[ "$matched_count" -eq 0 ]]; then
        log_info "No AWSO FERs found — nothing to clean up."; return 0
    fi

    # Decision: can we rename+keep without exceeding quota?
    # After rename, v3.0.0 needs to create AWSO_FER_COUNT new FERs.
    # Current state: old FERs still count toward quota (remaining reflects available slots).
    # After rename: old FERs still exist (same count), v3.0.0 needs AWSO_FER_COUNT more slots.
    # So we need: remaining >= AWSO_FER_COUNT (slots for v3.0.0's new FERs)
    if [[ "$remaining" -ge "$AWSO_FER_COUNT" ]]; then
        log_info "Quota allows rename — auto-renaming ${matched_count} AWSO FER(s) to v215_backup_* and disabling..."

        # Build set of all existing FER names to detect already-renamed ones (partial resume)
        local all_fer_names
        all_fer_names=$( echo "$all_fers" | jq -r '.[].name' )

        local fer_id fer_name fer_scope fer_parse
        while IFS= read -r fer_json; do
            fer_id=$(    echo "$fer_json" | jq -r '.id' )
            fer_name=$(  echo "$fer_json" | jq -r '.name' )
            fer_scope=$( echo "$fer_json" | jq -r '.scope' )
            fer_parse=$( echo "$fer_json" | jq -r '.parseExpression' )

            local new_name="v215_backup_${fer_name}"

            # Skip if backup name already exists — this FER was renamed in a previous partial run
            if echo "$all_fer_names" | grep -qx "$new_name"; then
                log_info "  Already renamed: ${fer_name} → ${new_name} (skipping)"
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
                log_error "  Response: $( echo "$put_response" | sed '$d' )"
                exit 1
            fi
            log_info "  Renamed: ${fer_name} → ${new_name} (disabled)"
            FER_RENAMED_COUNT=$(( FER_RENAMED_COUNT + 1 ))
        done < <( echo "$matched_fers" | jq -c '.[]' )

        log_info "FER cleanup complete. ${FER_RENAMED_COUNT} FER(s) renamed and disabled."
    else
        # Not enough quota — prompt for manual cleanup
        log_warn "FER quota too low to rename and keep old FERs."
        log_warn "Remaining slots: ${remaining}. v3.0.0 needs: ${AWSO_FER_COUNT}."
        log_warn ""
        log_warn "The following AWSO FERs must be manually deleted or renamed before deploying v3.0.0:"
        echo ""
        echo "$matched_fers" | jq -r '.[] | "  \(.id)  \(.name)"' | tee -a "$LOG_FILE"
        echo ""
        log_warn "Mapped parameters have been saved to: ${PERSIST_PARAM_FILE}"
        log_warn ""
        log_warn "After cleaning up the FERs, resume the migration with:"
        echo ""
        echo -e "${GREEN}  $0 --resume \\
      -d ${DEPLOYMENT} -i ${ACCESS_ID} -k '***' -o ${ORG_ID} \\
      -n ${NEW_STACK_NAME} -r ${REGION} -p ${AWS_PROFILE} \\
      --params-file ${PERSIST_PARAM_FILE}${NC}"
        echo ""
        exit 2
    fi
}

# ============================================================
# Phase 8 — Metric Rules Cleanup
# ============================================================
phase_metric_rules_cleanup() {
    log_phase "Phase 8: Metric Rules Cleanup"

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
            *)   log_warn "  Unexpected response (HTTP ${http_code}): ${rule_name}"; skipped=$(( skipped + 1 )) ;;
        esac
    done

    log_info "Metric rules cleanup complete. ${deleted} deleted, ${skipped} skipped."
}

# ============================================================
# Phase 9 — Deploy v3.0.0
# ============================================================
phase_deploy() {
    log_phase "Phase 9: Deploy v3.0.0 Stack"

    # In resume mode, load params from the provided file
    if [[ "$RESUME" == true ]]; then
        if [[ -z "$RESUME_PARAMS_FILE" || ! -f "$RESUME_PARAMS_FILE" ]]; then
            log_error "--resume requires --params-file pointing to a valid params JSON file."
            exit 1
        fi
        TEMP_PARAM_FILE=$( mktemp /tmp/awso_migration_params_XXXXXX )
        cp "$RESUME_PARAMS_FILE" "$TEMP_PARAM_FILE"
        log_info "Loaded params from: ${RESUME_PARAMS_FILE}"
    fi

    # Show full parameter list and confirm before deploying
    echo ""
    log_info "  v3.0.0 parameters to be deployed:"
    jq -r '.[] | "    \(.ParameterKey) = \(if .ParameterKey | test("AccessKey|AccessID") then "***" elif .ParameterValue == "" then "<empty — v3.0.0 will create new>" else .ParameterValue end)"' \
        "$TEMP_PARAM_FILE" | tee -a "$LOG_FILE"
    echo ""
    read -r -p "Deploy v3.0.0 stack '${NEW_STACK_NAME}'? Type 'yes' to continue: " confirm
    if [[ "$confirm" != "yes" ]]; then
        log_info "Deployment aborted by user."; exit 0
    fi

    log_info "Creating stack '${NEW_STACK_NAME}' in region '${REGION}'..."
    log_info "Template: ${V300_TEMPLATE_URL}"

    aws_cmd cloudformation create-stack \
        --stack-name "${NEW_STACK_NAME}" \
        --template-url "${V300_TEMPLATE_URL}" \
        --parameters "file://${TEMP_PARAM_FILE}" \
        --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
        --region "${REGION}" >/dev/null

    log_info "Stack creation initiated. Waiting for completion (timeout: ${CREATE_TIMEOUT}s)..."
    local final_status
    final_status=$( wait_for_stack "$NEW_STACK_NAME" "$CREATE_TIMEOUT" ) || true

    if [[ "$final_status" == "CREATE_COMPLETE" ]]; then
        log_info "Stack '${NEW_STACK_NAME}' created successfully."; return 0
    fi

    log_error "Stack creation ended with status: ${final_status}"
    log_error "Failed resources:"
    aws_cmd cloudformation describe-stack-events \
        --stack-name "${NEW_STACK_NAME}" --region "${REGION}" --output json \
        | jq -r '
            .StackEvents[]
            | select(.ResourceStatus == "CREATE_FAILED")
            | "  \(.LogicalResourceId): \(.ResourceStatusReason // "")"' \
        | tee -a "$LOG_FILE"
    log_error "Use --resume with the saved params file to retry after resolving the issue:"
    log_error "  --params-file ${PERSIST_PARAM_FILE:-$RESUME_PARAMS_FILE}"
    exit 1
}

# ============================================================
# Phase 10 — Verify
# ============================================================
phase_verify() {
    log_phase "Phase 10: Verify Deployment"

    # Check nested stack resources for partial failures
    local not_complete
    not_complete=$( aws_cmd cloudformation list-stack-resources \
        --stack-name "${NEW_STACK_NAME}" --region "${REGION}" --output json \
        | jq -r '
            .StackResourceSummaries[]
            | select(.ResourceStatus != "CREATE_COMPLETE" and .ResourceStatus != "UPDATE_COMPLETE")
            | "  \(.LogicalResourceId): \(.ResourceStatus)"' )

    if [[ -n "$not_complete" ]]; then
        log_warn "Some resources did not reach CREATE_COMPLETE:"
        echo "$not_complete" | tee -a "$LOG_FILE"
    else
        log_info "All stack resources: CREATE_COMPLETE"
    fi

    # Verify Sumo Logic collector — use shared helper
    log_info "Checking Sumo Logic collector and sources..."
    if ! find_awso_collector; then
        log_warn "Could not find aws-observability collector. It may take a few minutes to appear."
        return 0
    fi
    log_info "Collector: ${COLLECTOR_NAME} (ID: ${COLLECTOR_ID})"

    local sources_json total alive
    sources_json=$( sumo_get "/api/v1/collectors/${COLLECTOR_ID}/sources" )
    total=$( echo "$sources_json" | jq '.sources | length' )
    alive=$( echo "$sources_json" | jq '[ .sources[] | select(.alive == true) ] | length' )

    if [[ "$total" -gt 0 && "$alive" -eq "$total" ]]; then
        log_info "Sources: ${alive}/${total} alive ✓"
    else
        log_warn "Sources: ${alive}/${total} alive — some may still be initialising."
    fi

    # Bucket policy check — verify each configured bucket grants the required AWS service
    # principals write access. Migration reuses existing buckets so v3.0.0 never creates a
    # new bucket policy; a missing or incomplete policy will silently stop log delivery.
    log_info "Checking S3 bucket policies..."
    _check_bucket_policy() {
        local label="$1" bucket="$2"
        [[ -z "$bucket" ]] && return

        local policy
        policy=$( aws_cmd s3api get-bucket-policy --bucket "$bucket" --region "$REGION" \
            --output text --query Policy 2>&1 ) || {
            log_warn "  ${label} (${bucket}): no bucket policy found — log delivery may be blocked."
            log_warn "    Expected policy with cloudtrail.amazonaws.com and delivery.logs.amazonaws.com."
            return
        }

        local missing=""
        echo "$policy" | jq -e '
            [.Statement[]? | .Principal.Service? | arrays, strings] | flatten
            | any(. == "cloudtrail.amazonaws.com")
        ' >/dev/null 2>&1 || missing="${missing} cloudtrail.amazonaws.com"

        echo "$policy" | jq -e '
            [.Statement[]? | .Principal.Service? | arrays, strings] | flatten
            | any(. == "delivery.logs.amazonaws.com")
        ' >/dev/null 2>&1 || missing="${missing} delivery.logs.amazonaws.com"

        if [[ -z "$missing" ]]; then
            log_info "  ${label} (${bucket}): policy OK ✓"
        else
            log_warn "  ${label} (${bucket}): policy missing principals:${missing}"
            log_warn "    Check: aws s3api get-bucket-policy --bucket ${bucket} --region ${REGION}"
        fi
    }

    _check_bucket_policy "CloudTrail bucket" "$CAPTURED_BUCKET_CLOUDTRAIL"
    _check_bucket_policy "ALB bucket"        "$CAPTURED_BUCKET_ALB"
    _check_bucket_policy "ELB bucket"        "$CAPTURED_BUCKET_ELB"

    # S3 notification check — each source bucket must have an SNS TopicConfiguration for
    # s3:ObjectCreated events so new log files trigger Sumo ingestion. v3.0.0 only wires this
    # when it creates the bucket; existing buckets may have no notification or a stale topic
    # ARN pointing at the deleted v2.x SNS topic.
    log_info "Checking S3 bucket notification configurations..."
    _check_bucket_notification() {
        local label="$1" bucket="$2"
        [[ -z "$bucket" ]] && return

        local notif_json
        notif_json=$( aws_cmd s3api get-bucket-notification-configuration \
            --bucket "$bucket" --region "$REGION" --output json 2>&1 ) || {
            log_warn "  ${label} (${bucket}): could not retrieve notification config."
            return
        }

        # Find SNS TopicConfigurations that include an s3:ObjectCreated event
        local topic_arns
        topic_arns=$( echo "$notif_json" | jq -r '
            .TopicConfigurations[]?
            | select(.Events[]? | startswith("s3:ObjectCreated"))
            | .TopicArn' )

        if [[ -z "$topic_arns" ]]; then
            log_warn "  ${label} (${bucket}): no s3:ObjectCreated SNS notification found."
            log_warn "    New log files will not trigger Sumo ingestion — configure an SNS"
            log_warn "    notification on this bucket pointing at the v3.0.0 Sumo SNS topic."
            return
        fi

        # Verify each topic ARN still exists and is not a leftover from the deleted v2.x stack
        local topic_arn
        while IFS= read -r topic_arn; do
            local sns_check
            sns_check=$( aws_cmd sns get-topic-attributes \
                --topic-arn "$topic_arn" --region "$REGION" --output json 2>&1 )
            if echo "$sns_check" | grep -q "NotFound\|does not exist\|InvalidParameter\|AuthorizationError"; then
                log_warn "  ${label} (${bucket}): SNS topic '${topic_arn}' does not exist."
                log_warn "    This is likely the deleted v2.x topic — update the bucket notification"
                log_warn "    to point at the new v3.0.0 SNS topic."
            else
                log_info "  ${label} (${bucket}): SNS notification OK → ${topic_arn} ✓"
            fi
        done <<< "$topic_arns"
    }

    _check_bucket_notification "CloudTrail bucket" "$CAPTURED_BUCKET_CLOUDTRAIL"
    _check_bucket_notification "ALB bucket"        "$CAPTURED_BUCKET_ALB"
    _check_bucket_notification "ELB bucket"        "$CAPTURED_BUCKET_ELB"

    # CloudTrail check — the v2.x trail (Aws-Observability-*) was deleted with the old stack.
    # v3.0.0 only creates a new trail when it also creates a new bucket (not the migration case).
    # Verify that at least one active trail is writing to the CloudTrail bucket; if none exists
    # the Sumo CloudTrail source will receive no new data.
    if [[ -n "$CAPTURED_BUCKET_CLOUDTRAIL" ]]; then
        log_info "Checking CloudTrail trails writing to '${CAPTURED_BUCKET_CLOUDTRAIL}'..."
        local trails_json
        # Default includes shadow trails (read-only copies of multi-region trails created in
        # other regions). We need them because a multi-region trail homed elsewhere can
        # legitimately be writing to this bucket.
        trails_json=$( aws_cmd cloudtrail describe-trails \
            --region "${REGION}" --output json 2>&1 ) || {
            log_warn "  Could not list CloudTrail trails — verify manually."
            trails_json='{"trailList":[]}'
        }

        # Find trails whose S3BucketName matches the captured bucket
        local matching_trails
        matching_trails=$( echo "$trails_json" | jq -r --arg b "$CAPTURED_BUCKET_CLOUDTRAIL" \
            '[.trailList[] | select(.S3BucketName == $b)]' )
        local match_count
        match_count=$( echo "$matching_trails" | jq 'length' )

        if [[ "$match_count" -eq 0 ]]; then
            log_warn "  No CloudTrail trail found writing to bucket '${CAPTURED_BUCKET_CLOUDTRAIL}'."
            log_warn "  The v2.x Aws-Observability-* trail was deleted with the old stack."
            log_warn "  Create a new trail pointing at this bucket, or v3.0.0 CloudTrail source"
            log_warn "  will receive no data."
            log_warn "    aws cloudtrail create-trail --name <name> --s3-bucket-name ${CAPTURED_BUCKET_CLOUDTRAIL} --region ${REGION}"
        else
            local trail_name trail_home_region trail_logging
            while IFS= read -r trail_json; do
                trail_name=$(        echo "$trail_json" | jq -r '.Name' )
                trail_home_region=$( echo "$trail_json" | jq -r '.HomeRegion' )
                # get-trail-status must be called against the trail's home region
                trail_logging=$( aws_cmd cloudtrail get-trail-status \
                    --name "$trail_name" --region "${trail_home_region}" --output json 2>&1 \
                    | jq -r '.IsLogging // false' )
                if [[ "$trail_logging" == "true" ]]; then
                    log_info "  Trail '${trail_name}' (home: ${trail_home_region}): IsLogging=true ✓"
                else
                    log_warn "  Trail '${trail_name}' (home: ${trail_home_region}): IsLogging=false — trail exists but is not logging."
                    log_warn "    aws cloudtrail start-logging --name ${trail_name} --region ${trail_home_region}"
                fi
            done < <( echo "$matching_trails" | jq -c '.[]' )
        fi
    fi
}

# ============================================================
# Phase 11 — Patch Source Role ARNs
# ============================================================
phase_patch_role_arns() {
    log_phase "Phase 11: Patch Source Role ARNs"

    # Find CreateCommonResources nested stack
    local nested_stack_id
    nested_stack_id=$( aws_cmd cloudformation list-stack-resources \
        --stack-name "${NEW_STACK_NAME}" --region "${REGION}" --output json \
        | jq -r '
            .StackResourceSummaries[]
            | select(.LogicalResourceId == "CreateCommonResources")
            | .PhysicalResourceId' )

    if [[ -z "$nested_stack_id" || "$nested_stack_id" == "null" ]]; then
        log_warn "CreateCommonResources nested stack not found — skipping role ARN patch."
        return 0
    fi

    # Get the new SumoLogicSourceRole name from the nested stack
    local role_name
    role_name=$( aws_cmd cloudformation describe-stack-resource \
        --stack-name "${nested_stack_id}" \
        --logical-resource-id SumoLogicSourceRole \
        --region "${REGION}" \
        --output json \
        | jq -r '.StackResourceDetail.PhysicalResourceId' )

    if [[ -z "$role_name" || "$role_name" == "null" ]]; then
        log_warn "SumoLogicSourceRole not found in nested stack — skipping role ARN patch."
        return 0
    fi

    local new_role_arn="arn:aws:iam::${ACCOUNT_ID}:role/${role_name}"
    log_info "New role ARN: ${new_role_arn}"

    # Get collector ID directly from the new stack's SumoLogicHostedCollector resource
    local cf_collector_id
    cf_collector_id=$( aws_cmd cloudformation describe-stack-resource \
        --stack-name "${nested_stack_id}" \
        --logical-resource-id SumoLogicHostedCollector \
        --region "${REGION}" \
        --output json 2>/dev/null \
        | jq -r '.StackResourceDetail.PhysicalResourceId // "" | split("/")[-1]' )

    if [[ -n "$cf_collector_id" && "$cf_collector_id" != "null" ]]; then
        COLLECTOR_ID="$cf_collector_id"
        log_info "Collector ID from new stack: ${COLLECTOR_ID}"
    else
        log_warn "Could not read SumoLogicHostedCollector from new stack — falling back to name search."
        STACK_JSON=$( aws_cmd cloudformation describe-stacks \
            --stack-name "${NEW_STACK_NAME}" --region "${REGION}" --output json 2>/dev/null ) || true
        if ! find_awso_collector; then
            log_warn "aws-observability collector not found — skipping role ARN patch."
            return 0
        fi
        log_info "Collector: ${COLLECTOR_NAME} (ID: ${COLLECTOR_ID})"
    fi

    # List all sources
    local sources_json
    sources_json=$( sumo_get "/api/v1/collectors/${COLLECTOR_ID}/sources" )

    # Identify sources that have a roleARN that doesn't match the new one
    local stale_ids
    stale_ids=$( echo "$sources_json" | jq -r --arg new_arn "$new_role_arn" '
        .sources[]
        | select(
            .thirdPartyRef.resources != null and
            (.thirdPartyRef.resources[].authentication.roleARN? // "" | . != "" and . != $new_arn)
          )
        | .id' )

    if [[ -z "$stale_ids" ]]; then
        log_info "All sources already have the correct role ARN — nothing to patch."
        return 0
    fi

    local header_file
    header_file=$( mktemp /tmp/awso_source_headers_XXXXXX )

    local source_id
    while IFS= read -r source_id; do
        local source_name
        source_name=$( echo "$sources_json" | jq -r --argjson id "$source_id" \
            '.sources[] | select(.id == $id) | .name' )

        # GET source with ETag
        local body
        body=$( sumo_get_with_etag "/api/v1/collectors/${COLLECTOR_ID}/sources/${source_id}" "$header_file" )
        local etag
        etag=$( grep -i '^etag:' "$header_file" | tr -d '\r' | awk '{print $2}' )

        if [[ -z "$etag" ]]; then
            log_warn "  Could not get ETag for source '${source_name}' (${source_id}) — skipping."
            continue
        fi

        # Patch all roleARN fields in the source body
        local patched_body
        patched_body=$( echo "$body" | jq --arg new_arn "$new_role_arn" '
            .source.thirdPartyRef.resources[].authentication.roleARN = $new_arn' )

        # PUT with If-Match
        local put_response http_status
        put_response=$( sumo_put_if_match \
            "/api/v1/collectors/${COLLECTOR_ID}/sources/${source_id}" \
            "$patched_body" \
            "$etag" )
        http_status=$( echo "$put_response" | tail -1 )

        if [[ "$http_status" == "200" ]]; then
            log_info "  Patched: ${source_name} (${source_id})"
            SOURCES_PATCHED=$(( SOURCES_PATCHED + 1 ))
        else
            log_warn "  Failed to patch '${source_name}' (${source_id}) — HTTP ${http_status}"
            log_warn "  Response: $( echo "$put_response" | sed '$d' )"
        fi
    done <<< "$stale_ids"

    rm -f "$header_file"
    log_info "Role ARN patch complete. ${SOURCES_PATCHED} source(s) updated."
}

# ============================================================
# Phase 12 — Report
# ============================================================
phase_report() {
    log_phase "Phase 12: Migration Summary"
    echo "" | tee >( _log_to_file )
    echo -e "${GREEN}  Source version   : v${SOURCE_VERSION:-unknown}${NC}"            | tee >( _log_to_file )
    echo -e "${GREEN}  Target version   : v3.0.0${NC}"                                 | tee >( _log_to_file )
    echo -e "${GREEN}  Stack name       : ${NEW_STACK_NAME}${NC}"                      | tee >( _log_to_file )
    echo -e "${GREEN}  Region           : ${REGION}${NC}"                              | tee >( _log_to_file )
    echo -e "${GREEN}  Deployment       : ${DEPLOYMENT}${NC}"                          | tee >( _log_to_file )
    echo -e "${GREEN}  ALB bucket       : ${CAPTURED_BUCKET_ALB:-<empty>}${NC}"        | tee >( _log_to_file )
    echo -e "${GREEN}  CloudTrail bkt   : ${CAPTURED_BUCKET_CLOUDTRAIL:-<empty>}${NC}" | tee >( _log_to_file )
    echo -e "${GREEN}  ELB bucket       : ${CAPTURED_BUCKET_ELB:-<empty>}${NC}"        | tee >( _log_to_file )
    echo -e "${GREEN}  FERs renamed     : ${FER_RENAMED_COUNT}${NC}"                   | tee >( _log_to_file )
    echo -e "${GREEN}  Sources patched  : ${SOURCES_PATCHED}${NC}"                     | tee >( _log_to_file )
    echo -e "${GREEN}  Log file         : ${LOG_FILE}${NC}"                            | tee >( _log_to_file )
    echo "" | tee >( _log_to_file )
}

# ============================================================
# Argument Parsing
# ============================================================
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d)            DEPLOYMENT="$2";         shift 2 ;;
            -i)            ACCESS_ID="$2";           shift 2 ;;
            -k)            ACCESS_KEY="$2";          shift 2 ;;
            -o)            ORG_ID="$2";              shift 2 ;;
            -s)            STACK_NAME="$2";          shift 2 ;;
            -r)            REGION="$2";              shift 2 ;;
            -v)            SOURCE_VERSION="$2";      shift 2 ;;
            -n)            NEW_STACK_NAME="$2";      shift 2 ;;
            -p)            AWS_PROFILE="$2";         shift 2 ;;
            --install-apps) INSTALL_APPS="$2";       shift 2 ;;
            --dry-run)          DRY_RUN=true;             shift ;;
            --resume)           RESUME=true;              shift ;;
            --params-file)      RESUME_PARAMS_FILE="$2";  shift 2 ;;
            --patch-roles-only) PATCH_ROLES_ONLY=true; RESUME=true; shift ;;
            -h|--help)     help_text; exit 0 ;;
            *) echo "Unknown option: $1"; help_text; exit 1 ;;
        esac
    done

    # Validate required args
    local missing=""
    [[ -z "$DEPLOYMENT" ]] && missing="$missing -d DEPLOYMENT"
    [[ -z "$ACCESS_ID" ]]  && missing="$missing -i ACCESS_ID"
    [[ -z "$ORG_ID" ]]     && missing="$missing -o ORG_ID"
    [[ -z "$REGION" ]]     && missing="$missing -r REGION"

    if [[ "$PATCH_ROLES_ONLY" == true ]]; then
        [[ -z "$NEW_STACK_NAME" ]] && missing="$missing -n NEW_STACK_NAME"
    elif [[ "$RESUME" == false ]]; then
        [[ -z "$STACK_NAME" ]] && missing="$missing -s STACK_NAME"
    else
        [[ -z "$RESUME_PARAMS_FILE" ]] && missing="$missing --params-file PATH"
        [[ -z "$NEW_STACK_NAME" ]]     && missing="$missing -n NEW_STACK_NAME"
    fi

    if [[ -n "$missing" ]]; then
        echo -e "${RED}Missing required arguments:${NC}${missing}"
        help_text; exit 1
    fi

    # Prompt for access key interactively if not supplied via -k
    if [[ -z "$ACCESS_KEY" ]]; then
        read -r -s -p "Enter Sumo Logic Access Key: " ACCESS_KEY < /dev/tty
        echo ""
        if [[ -z "$ACCESS_KEY" ]]; then
            echo -e "${RED}Access key is required.${NC}"
            exit 1
        fi
    fi

    # Defaults
    [[ -z "$NEW_STACK_NAME" ]] && NEW_STACK_NAME="$STACK_NAME"

    # Normalize --install-apps to exact Yes/No (case-insensitive)
    local install_apps_lc
    install_apps_lc=$( echo "$INSTALL_APPS" | tr '[:upper:]' '[:lower:]' )
    case "$install_apps_lc" in
        yes) INSTALL_APPS="Yes" ;;
        no)  INSTALL_APPS="No" ;;
        *)   echo -e "${RED}--install-apps must be Yes or No (got: ${INSTALL_APPS})${NC}"; exit 1 ;;
    esac
}

# ============================================================
# Main
# ============================================================
main() {
    parse_args "$@"

    local log_target="${NEW_STACK_NAME:-${STACK_NAME}}"
    LOG_FILE="./migration_${log_target}_$( date +%Y%m%d_%H%M%S ).log"
    echo "AWSO Migration Script v${SCRIPT_VERSION} — $( date )" > "$LOG_FILE"
    echo "Log: ${LOG_FILE}"

    if [[ "$PATCH_ROLES_ONLY" == true ]]; then
        phase_validate   # RESUME=true set in parse_args — skips stack checks
        phase_patch_role_arns
        phase_report
    elif [[ "$RESUME" == true ]]; then
        PERSIST_PARAM_FILE="$RESUME_PARAMS_FILE"
        phase_validate   # validates creds only in resume mode

        # If old stack name provided, check whether Phase 6 still needs to run
        if [[ -n "$STACK_NAME" ]]; then
            local old_out
            old_out=$( aws_cmd cloudformation describe-stacks \
                --stack-name "${STACK_NAME}" --region "${REGION}" --output json 2>&1 ) || true
            if echo "$old_out" | grep -q "does not exist"; then
                log_info "Old stack '${STACK_NAME}' already deleted — skipping Phase 6."
            else
                local old_status
                old_status=$( echo "$old_out" | jq -r '.Stacks[0].StackStatus' 2>/dev/null || echo "UNKNOWN" )
                case "$old_status" in
                    DELETE_COMPLETE)
                        log_info "Old stack '${STACK_NAME}' already deleted — skipping Phase 6." ;;
                    DELETE_FAILED)
                        log_warn "Old stack '${STACK_NAME}' is DELETE_FAILED — running Phase 6..."
                        STACK_JSON="$old_out"
                        phase_delete_retain_only ;;
                    DELETE_IN_PROGRESS)
                        log_warn "Old stack '${STACK_NAME}' is still deleting — waiting..."
                        local del_status
                        del_status=$( wait_for_stack "$STACK_NAME" "$DELETE_TIMEOUT" ) || true
                        if [[ "$del_status" != "DELETE_COMPLETE" ]]; then
                            log_error "Stack deletion ended with: ${del_status}. Resolve manually then re-run."
                            exit 1
                        fi ;;
                    UPDATE_COMPLETE|CREATE_COMPLETE|UPDATE_ROLLBACK_COMPLETE)
                        log_warn "Old stack '${STACK_NAME}' still exists (${old_status}) — running Phase 6..."
                        STACK_JSON="$old_out"
                        phase_delete ;;
                    *)
                        log_warn "Old stack '${STACK_NAME}' has unexpected status '${old_status}' — skipping Phase 6." ;;
                esac
            fi

            # Clean up any orphaned nested stacks left from a previous --retain-resources run
            cleanup_orphaned_nested_stacks "$STACK_NAME"
        fi

        # Populate summary globals from the saved params file so report is accurate
        if [[ -f "$RESUME_PARAMS_FILE" ]]; then
            CAPTURED_BUCKET_ALB=$(       jq -r '.[] | select(.ParameterKey=="Section5dALBS3LogsBucketName")        | .ParameterValue' "$RESUME_PARAMS_FILE" )
            CAPTURED_BUCKET_CLOUDTRAIL=$(jq -r '.[] | select(.ParameterKey=="Section6cCloudTrailLogsBucketName")   | .ParameterValue' "$RESUME_PARAMS_FILE" )
            CAPTURED_BUCKET_ELB=$(       jq -r '.[] | select(.ParameterKey=="Section8dELBS3LogsBucketName")        | .ParameterValue' "$RESUME_PARAMS_FILE" )
            [[ -z "$SOURCE_VERSION" ]] && SOURCE_VERSION="(from params file)"
        fi

        echo ""
        log_warn "Resume will run phases 7-12 using:"
        log_warn "  New stack name:    ${NEW_STACK_NAME}"
        log_warn "  Region:            ${REGION}"
        log_warn "  Params file:       ${RESUME_PARAMS_FILE}"
        log_warn "  ALB bucket:        ${CAPTURED_BUCKET_ALB:-<empty>}"
        log_warn "  CloudTrail bucket: ${CAPTURED_BUCKET_CLOUDTRAIL:-<empty>}"
        log_warn "  ELB bucket:        ${CAPTURED_BUCKET_ELB:-<empty>}"
        echo ""
        log_warn "Key v3.0.0 parameters from saved file:"
        jq -r '.[] | select(.ParameterKey | test("^Section[1-9]")) | "  \(.ParameterKey) = \(.ParameterValue)"' \
            "$RESUME_PARAMS_FILE" | grep -v "AccessKey\|AccessID" | tee -a "$LOG_FILE"
        echo ""
        read -r -p "Proceed with resume? (yes/no): " confirm
        if [[ "$confirm" != "yes" ]]; then
            log_info "Resume aborted by user."; exit 0
        fi
        echo ""
        phase_fer_cleanup
        phase_metric_rules_cleanup
        phase_deploy
        phase_verify
        phase_patch_role_arns
        phase_report
    else
        phase_validate
        # phase_validate may flip RESUME=true in two cases:
        #   1. DELETE_IN_PROGRESS — waited for deletion to finish
        #   2. Stack not found (DELETE_COMPLETE) — detected a saved params file
        # Both cases skip straight to cleanup + deploy.
        if [[ "$RESUME" == true ]]; then
            log_info "Stack already deleted — auto-resuming from Phase 7."
            CAPTURED_BUCKET_ALB=$(       jq -r '.[] | select(.ParameterKey=="Section5dALBS3LogsBucketName")        | .ParameterValue' "$RESUME_PARAMS_FILE" )
            CAPTURED_BUCKET_CLOUDTRAIL=$(jq -r '.[] | select(.ParameterKey=="Section6cCloudTrailLogsBucketName")   | .ParameterValue' "$RESUME_PARAMS_FILE" )
            CAPTURED_BUCKET_ELB=$(       jq -r '.[] | select(.ParameterKey=="Section8dELBS3LogsBucketName")        | .ParameterValue' "$RESUME_PARAMS_FILE" )
            [[ -z "$SOURCE_VERSION" ]] && SOURCE_VERSION="(from params file)"
            phase_fer_cleanup
            phase_metric_rules_cleanup
            phase_deploy
            phase_verify
            phase_patch_role_arns
            phase_report
            return 0
        fi
        phase_capture
        phase_map_parameters
        phase_confirm
        phase_ensure_remove_on_delete
        phase_delete
        phase_fer_cleanup
        phase_metric_rules_cleanup
        phase_deploy
        phase_verify
        phase_patch_role_arns
        phase_report
    fi
}

main "$@"
