#!/bin/bash

# AWS CLI Configuration. Provide the Region and Profile where the CloudFormation Template needs to be deployed.
export AWS_REGION=$1
export AWS_PROFILE=$2

# Env Name. Provide Input parameter for env name.
export ENV_NAME=$3
if [ ! "${ENV_NAME}" ]; then
    export ENV_NAME="default"
fi

# Read Sumo Logic Access Key interactively (hidden input).
printf "Enter Sumo Logic Access Key: "
read -rsp "" SUMO_ACCESS_KEY
printf "\n"
if [ -z "$SUMO_ACCESS_KEY" ]; then
    echo "Access key cannot be empty."
    exit 1
fi

# Provide a Stack Name which will be shown in AWS. Change the Default name if required.
export CF_STACK_NAME="SumoLogic-Aws-Observability-${AWS_REGION}"

# For parameters, please update the parameters-{environment}.json file placed in the same folder.
# Visit - https://help.sumologic.com/docs/observability/aws/deploy-use-aws-observability/deploy-with-aws-cloudformation/
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export parameters_path="${SCRIPT_DIR}/parameters-${ENV_NAME}.json"

# Downloading the template to local for use. Remove the template with same name if already present.
rm -f sumologic_observability_template.yaml
aws s3 cp s3://sumologic-appdev-aws-sam-apps/aws-observability-versions/v3.0.0/templates/sumologic_observability.master.template.yaml sumologic_observability_template.yaml

# Build parameter overrides array from JSON file.
# aws cloudformation deploy does not support file:// for --parameter-overrides in AWS CLI v2,
# so each Key=Value entry is read from the JSON array and passed as a separate argument.
# The Access Key is appended inline so it is never stored in the parameters file.
if [ ! -f "${parameters_path}" ]; then
    echo "Parameters file not found: ${parameters_path}"
    exit 1
fi

PARAM_OVERRIDES=()
while IFS= read -r param; do
    [[ -n "$param" ]] && PARAM_OVERRIDES+=("$param")
done <<< "$(jq -r '.[]' "${parameters_path}")"
PARAM_OVERRIDES+=("Section1cSumoLogicAccessKey=${SUMO_ACCESS_KEY}")

# Deploy the template. If the Stack name already exists, the stack will be updated else created.
aws cloudformation deploy --profile ${AWS_PROFILE} --region ${AWS_REGION} \
  --template-file sumologic_observability_template.yaml \
  --stack-name ${CF_STACK_NAME} \
  --parameter-overrides "${PARAM_OVERRIDES[@]}" \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND
