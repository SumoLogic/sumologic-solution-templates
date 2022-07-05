#! /bin/bash

# ----------------------------------------------------------------------------------------------------------------------------------------------------------
# This script imports the existing fields and FERs (required by aws observability solution) if field(s) already present in the user's Sumo Logic account.
# For SUMOLOGIC_ENV, provide one from the list : au, ca, de, eu, jp, us2, in, fed or us1. For more information on Sumo Logic deployments visit https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security"
# Before using this script, set following environment variables using below commands:
# export SUMOLOGIC_ENV=""
# export SUMOLOGIC_ACCESSID=""
# export SUMOLOGIC_ACCESSKEY=""
#-----------------------------------------------------------------------------------------------------------------------------------------------------------

# Validate Sumo Logic environment/deployment.
if ! [[ "$SUMOLOGIC_ENV" =~ ^(au|ca|de|eu|jp|us2|in|fed|us1)$ ]]; then
    echo "$SUMOLOGIC_ENV is invalid Sumo Logic deployment. For SUMOLOGIC_ENV, provide one from list : au, ca, de, eu, jp, us2, in, fed or us1. For more information on Sumo Logic deployments visit https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security"
    exit 1
fi

# Get Sumo Logic api endpoint based on SUMOLOGIC_ENV
if [ "${SUMOLOGIC_ENV}" == "us1" ];then
    SUMOLOGIC_BASE_URL="https://api.sumologic.com/api/"
else
    SUMOLOGIC_BASE_URL="https://api.${SUMOLOGIC_ENV}.sumologic.com/api/"
fi

# awso_list contains fields required for AWS Obervablity Solution. Update the list if new field,FER is added to the solution.
declare -ra awso_list=(loadbalancer apiname tablename instanceid clustername cacheclusterid functionname networkloadbalancer account region namespace accountid dbidentifier loadbalancername topicname dbclusteridentifier dbinstanceidentifier)
declare -ra awso_fer_list=(AwsObservabilityAlbAccessLogsFER AwsObservabilityApiGatewayCloudTrailLogsFER AwsObservabilityDynamoDBCloudTrailLogsFER AwsObservabilityEC2CloudTrailLogsFER AwsObservabilityECSCloudTrailLogsFER AwsObservabilityElastiCacheCloudTrailLogsFER AwsObservabilityElbAccessLogsFER AwsObservabilityFieldExtractionRule AwsObservabilityLambdaCloudWatchLogsFER AwsObservabilityGenericCloudWatchLogsFER AwsObservabilityRdsCloudTrailLogsFER AwsObservabilitySNSCloudTrailLogsFER)

function get_remaining_fields() {
    local RESPONSE
    readonly RESPONSE="$(curl -XGET -s \
        -u "${SUMOLOGIC_ACCESSID}:${SUMOLOGIC_ACCESSKEY}" \
        "${SUMOLOGIC_BASE_URL}"v1/fields/quota)"

    echo "${RESPONSE}"
}

# Check if we'd have at least 13 fields remaining after additional fields
# would be created for the collection
function should_create_fields() {
    local RESPONSE
    readonly RESPONSE=$(get_remaining_fields)

    if ! jq -e <<< "${RESPONSE}" ; then
        printf "Failed requesting fields API:\n%s\n" "${RESPONSE}"
        # Credential Issue
        return 2
    fi
    
    if ! jq -e '.remaining' <<< "${RESPONSE}" ; then
        printf "Failed requesting fields API:\n%s\n" "${RESPONSE}"
        # Permissions/credential issuses
        return 3
    fi

    local REMAINING
    readonly REMAINING=$(jq -e '.remaining' <<< "${RESPONSE}")
  
    if [ $REMAINING -ge ${#awso_list[*]} ] ; then
        # Function returning with success
        return 0
    else
        # Capacity not enough to create new fields
        return 1
    fi
}

should_create_fields
outputVal=$?
# Sumo Logic fields in field schema - Decide to import
if [ $outputVal == 0 ] ; then
    # Get list of all fields present in field schema of user's Sumo Logic org.
    readonly FIELDS_RESPONSE="$(curl -XGET -s \
        -u "${SUMOLOGIC_ACCESSID}:${SUMOLOGIC_ACCESSKEY}" \
        "${SUMOLOGIC_BASE_URL}"v1/fields | jq '.data[]' )"

    for FIELD in "${awso_list[@]}" ; do
        FIELD_ID=$( echo "${FIELDS_RESPONSE}" | jq -r "select(.fieldName == \"${FIELD}\") | .fieldId" )
        if [[ -z "${FIELD_ID}" ]]; then
            # If field is not present in Sumo org, skip importing
            continue
        fi
        # Field exist in Sumo org, hence import
        terraform import \
            sumologic_field."${FIELD}" "${FIELD_ID}"
    done
    # Get list of all FER present in field schema of user's Sumo Logic org.
    readonly FER_RESPONSE="$(curl -XGET -s \
        -u "${SUMOLOGIC_ACCESSID}:${SUMOLOGIC_ACCESSKEY}" \
        "${SUMOLOGIC_BASE_URL}"v1/extractionRules | jq '.data[] | del(.parseExpression)' )"

    for FER in "${awso_fer_list[@]}" ; do
        FER_ID=$( echo "${FER_RESPONSE}" | jq -r "select(.name == \"${FER}\") | .id" )
        if [[ -z "${FER_ID}" ]]; then
            # If FER is not present in Sumo org, skip importing
            continue
        fi
        # FER exist in Sumo org, hence import
        terraform import \
            sumologic_field_extraction_rule."${FER}" "${FER_ID}"           
    done
elif [ $outputVal == 1 ] ; then
    echo "Couldn't automatically create fields and FERS"
    echo "You do not have enough field capacity to create the required fields and FERS automatically."
    echo "Please refer to https://help.sumologic.com/Manage/Fields to manually create the fields after you have removed unused fields and FERs to free up capacity."
elif [ $outputVal == 2 ] ; then
    echo "Error in calling Sumo Logic Fields or FER API."
    echo "User's credentials (SUMOLOGIC_ACCESSID and SUMOLOGIC_ACCESSKEY) are not valid."
elif [ $outputVal == 3 ] ; then
    echo "Error in calling Sumo Logic Fields or FERs API. The reasons can be:"
    echo "1. Credentials could not be verified. Cross check SUMOLOGIC_ACCESSID and SUMOLOGIC_ACCESSKEY."
    echo "2. You do not have the role capabilities to create Sumo Logic fields or FERs. Please see the Sumo Logic docs on role capabilities https://help.sumologic.com/Manage/Users-and-Roles/Manage-Roles/05-Role-Capabilities"
else
    echo "Error in calling Sumo Logic Fields or FERs API. The reasons can be:"
    echo "1. User's credentials (SUMOLOGIC_ACCESSID and SUMOLOGIC_ACCESSKEY) are not associated with SUMOLOGIC_ENV"
    echo "2. You do not have the role capabilities to create Sumo Logic fields or FERs. Please see the Sumo Logic docs on role capabilities https://help.sumologic.com/Manage/Users-and-Roles/Manage-Roles/05-Role-Capabilities"
fi