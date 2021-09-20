#! /bin/bash

# awso_list contains fields required for AWS Obervablity Solution. Update the list if new field is added to the solution.
declare -ra awso_list=(loadbalancer apiname tablename instanceid clustername cacheclusterid functionname networkloadbalancer account region namespace accountid dbidentifier dbInstanceIdentifier dbClusterIdentifier)

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