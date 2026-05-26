#! /bin/bash

# ----------------------------------------------------------------------------------------------------------------------------------------------------------
# This script imports the existing app installations (required by aws observability solution) if app(s) are already installed in the user's Sumo Logic account.
# For SUMOLOGIC_ENV, provide one from the list : au, ca, ch, de, eu, esc, jp, us2, kr, fed or us1. For more information on Sumo Logic deployments visit https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security"
# Before using this script, set following environment variables using below commands:
# export SUMOLOGIC_ENV=""
# export SUMOLOGIC_ACCESSID=""
# export SUMOLOGIC_ACCESSKEY=""
#-----------------------------------------------------------------------------------------------------------------------------------------------------------

# Validate Sumo Logic environment/deployment.

if ! [[ "$SUMOLOGIC_ENV" =~ ^(au|ca|ch|de|eu|esc|jp|us2|fed|kr|us1|stag)$ ]]; then
    echo "$SUMOLOGIC_ENV is invalid Sumo Logic deployment. For SUMOLOGIC_ENV, provide one from list : au, ca, ch, de, eu, esc, fed, jp, kr, us1, us2 or stag. For more information on Sumo Logic deployments visit https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security"
    exit 1
fi

# Get Sumo Logic api endpoint based on SUMOLOGIC_ENV
if [ "${SUMOLOGIC_ENV}" == "us1" ]; then
    SUMOLOGIC_BASE_URL="https://api.sumologic.com/api/"
elif [ "${SUMOLOGIC_ENV}" == "stag" ]; then
    SUMOLOGIC_BASE_URL="https://stag-api.sumologic.net/api/"
else
    SUMOLOGIC_BASE_URL="https://api.${SUMOLOGIC_ENV}.sumologic.com/api/"
fi

# awso_apps_list contains apps required for AWS Observability Solution.
# Each entry is "uuid|name" matching the installation_apps_list in local.tf.
# Update the list if new apps are added to the solution.
declare -ra awso_apps_list=(
    "b3210735-0917-459e-8d1e-722fee4c22fe|Amazon ECS(Without Container Insights and Traces)"
    "82ab79f5-3e85-4974-852f-5cb8f8028230|Amazon ElastiCache"
    "32c8b96c-161c-46d4-b81d-235cc0b56b87|Amazon Overview"
    "c32ad59b-ee10-4cd1-8369-3639e8457b1f|Amazon RDS"
    "9c203dfb-6088-4a76-b12e-cc3a78ce0df5|Amazon SNS"
    "8b57f601-c163-4481-8ae7-d6e212516506|Amazon SQS"
    "f1dfe2ea-ee27-4a74-972c-560424b9cb5c|AWS API Gateway"
    "27a17946-e475-4d56-8a8f-bc3fbc0400ca|AWS Application Load Balancer"
    "fb7a2e22-006c-40ea-945c-e73b6b369e7c|AWS Classic Load Balancer"
    "092203f6-9443-47ca-b2b5-6a4c25e8c14c|AWS DynamoDB"
    "f14714b5-6e86-40e7-aa6c-970e9182c0be|AWS EC2"
    "d71cb5f7-bf92-4fac-984f-33fdaea856f7|AWS Lambda"
    "5a6e7695-94a9-4548-a44a-054d4e793432|AWS Network Load Balancer"
    "149c19d7-de3a-483b-a1a7-bbd825916548|Host Metrics (EC2)"
)

function get_app_instances() {
    local RESPONSE
    readonly RESPONSE="$(curl -XGET -s \
        -u "${SUMOLOGIC_ACCESSID}:${SUMOLOGIC_ACCESSKEY}" \
        "${SUMOLOGIC_BASE_URL}"v2/apps/instances)"

   echo "${RESPONSE}"
}

get_app_instances
INSTANCES_RESPONSE=$(get_app_instances)
outputVal=$?

if ! jq -e <<< "${INSTANCES_RESPONSE}" > /dev/null 2>&1; then
    printf "Failed requesting Apps instances API:\n%s\n" "${INSTANCES_RESPONSE}"
    # Credential Issue
    outputVal=2
elif ! jq -e '.data' <<< "${INSTANCES_RESPONSE}" > /dev/null 2>&1; then
    printf "Failed requesting Apps instances API:\n%s\n" "${INSTANCES_RESPONSE}"
    # Permissions/credential issues
    outputVal=3
fi

if [ $outputVal == 0 ]; then
    for ENTRY in "${awso_apps_list[@]}"; do
        APP_UUID="${ENTRY%%|*}"
        APP_NAME="${ENTRY##*|}"
        echo "$APP_NAME - $APP_UUID"

        INSTALLATION_ID=$(echo "${INSTANCES_RESPONSE}" | jq -r ".data[] | select(.uuid == \"${APP_UUID}\") | .id" | head -1)

        if [[ -z "${INSTALLATION_ID}" ]]; then
            # App not installed in Sumo org, skip importing
            continue
        fi

        # App installation exists in Sumo org, hence import
        terraform import \
            "module.app-module.sumologic_app.apps[\"${APP_NAME}\"]" "${INSTALLATION_ID}"
    done
elif [ $outputVal == 2 ]; then
    echo "Error in calling Sumo Logic Apps API."
    echo "User's credentials (SUMOLOGIC_ACCESSID and SUMOLOGIC_ACCESSKEY) are not valid."
elif [ $outputVal == 3 ]; then
    echo "Error in calling Sumo Logic Apps API. The reasons can be:"
    echo "1. Credentials could not be verified. Cross check SUMOLOGIC_ACCESSID and SUMOLOGIC_ACCESSKEY."
    echo "2. You do not have the role capabilities to manage Sumo Logic apps. Please see the Sumo Logic docs on role capabilities https://help.sumologic.com/Manage/Users-and-Roles/Manage-Roles/05-Role-Capabilities"
else
    echo "Error in calling Sumo Logic Apps API. The reasons can be:"
    echo "1. User's credentials (SUMOLOGIC_ACCESSID and SUMOLOGIC_ACCESSKEY) are not associated with SUMOLOGIC_ENV"
    echo "2. You do not have the role capabilities to manage Sumo Logic apps. Please see the Sumo Logic docs on role capabilities https://help.sumologic.com/Manage/Users-and-Roles/Manage-Roles/05-Role-Capabilities"
fi
