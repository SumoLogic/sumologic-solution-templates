#!/bin/bash
if ! command -v aws &> /dev/null
then
    echo "aws cli not installed. Please install aws cli and rerun the script"
    exit
fi
now="$(date)"
echo "Script initiated at : $now"
#input to the script is sumo accessId and accessKey
export SUMO_ACCESS_ID=$1
export SUMO_ACCESS_KEY=$2
if [ -z "$AWS_PROFILE" ]
then
    AWS_PROFILE=default
fi
masterTemplateURL="https://sumologic-appdev-aws-sam-apps.s3.amazonaws.com/aws-observability-versions/v2.6.0/sumologic_observability.master.template.yaml"

#identify sumo deployment associated with sumo accessId and accessKey
export apiUrl="https://api.sumologic.com"
response=$(curl -s -i -u "${SUMO_ACCESS_ID}:${SUMO_ACCESS_KEY}" -X GET "${apiUrl}"/api/v1/collectors/)
location=`echo "$response" | grep "location:"`
deployment="us1"

if [ ! -z "$location" ]
then
    IFS='.' read -ra ADDR <<< "$location"
    deployment="${ADDR[1]}"
    apiUrl="https://api.${deployment}.sumologic.com"
fi

#identify sumo OrgId associated with sumo accessId and accessKey
# orgId=`(curl -s -u "${SUMO_ACCESS_ID}:${SUMO_ACCESS_KEY}" -X GET "${apiUrl}"/api/v1/account/contract -H "Accept: application/json") | jq -r '.orgId'`
response1=$(curl -s -u "${SUMO_ACCESS_ID}:${SUMO_ACCESS_KEY}" -X GET "${apiUrl}"/api/v1/account/contract -H "Accept: application/json")
orgId=`echo $response1 | jq -r '.orgId'`
if [ "$orgId" = null ]
then
    errorResponse=`echo $response1 | jq -r '.errors'`
    if [ "$errorResponse" = null ]
    then
        errorResponse=`echo $response1 | jq -r '.message'`
    fi
    echo "Following Error Occured while fetching orgId: $errorResponse"
    exit
fi

echo '[{"ParameterKey": "Section1aSumoLogicDeployment","ParameterValue": "'${deployment}'"},' >param.json  

echo '{"ParameterKey": "Section1bSumoLogicAccessID","ParameterValue": "'${SUMO_ACCESS_ID}'"},' >> param.json

echo '{"ParameterKey": "Section1cSumoLogicAccessKey","ParameterValue": "'${SUMO_ACCESS_KEY}'"},' >> param.json

echo '{"ParameterKey": "Section1dSumoLogicOrganizationId","ParameterValue": "'${orgId}'"},' >> param.json

awsAccountId=`aws sts get-caller-identity --output json | jq -r '.Account'` 
echo '{"ParameterKey": "Section2aAccountAlias","ParameterValue": "'${awsAccountId}'"}' >> param.json

echo ']'>>param.json

#extract stack name into a variable with unique identifier appended
stackName="sumoawsoquicksetup"
now="$(date)"
echo "Script Configuration completed. Triggering CloudFormation Template at : $now"
aws cloudformation create-stack --profile ${AWS_PROFILE} \
  --template-url ${masterTemplateURL} \
  --stack-name ${stackName} \
  --parameter file://param.json \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND
if [ "$?" != 0 ]
then
    echo "Error Occured in aws cloudformation command"
    exit
fi

#remove the parameter json file
rm param.json
now="$(date)"
echo "Script completed at : $now"