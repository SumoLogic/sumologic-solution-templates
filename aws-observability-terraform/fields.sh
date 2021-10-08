#! /bin/bash

# ----------------------------------------------------------------------------------------------------------------------------------------------------------
# This script imports the existing fields (required by aws observability solution) if field(s) already present in the user's Sumo Logic account.
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
    SUMOLOGIC_BASE_URL="https://api.${SUMOLOGIC_ENV}.sumologic.com/api"
fi

# awso_list contains fields required for AWS Obervablity Solution. Update the list if new field is added to the solution.
declare -ra awso_list=(loadbalancer apiname tablename instanceid clustername cacheclusterid functionname networkloadbalancer account region namespace accountid dbidentifier)

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
        # Function returning with faliure
        return 1
    fi
    
    if ! jq -e '.remaining' <<< "${RESPONSE}" ; then
        printf "Failed requesting fields API:\n%s\n" "${RESPONSE}"
        # Function returning with faliure
        return 1
    fi

    local REMAINING
    readonly REMAINING=$(jq -e '.remaining' <<< "${RESPONSE}")
  
    #if [[ $(( REMAINING - ${#awso_list[*]} )) -ge 13 ]] ; then
    if [ $REMAINING -ge ${#awso_list[*]} ] ; then
        # Function returning with success
        return 0
    else
        # Function returning with faliure
        return 1
    fi
}

# Sumo Logic fields in field schema - Decide to import
if should_create_fields ; then
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
else
    echo "Couldn't automatically create fields"
    echo "You do not have enough field capacity to create the required fields automatically."
    echo "Please refer to https://help.sumologic.com/Manage/Fields to manually create the fields after you have removed unused fields to free up capacity."
fi