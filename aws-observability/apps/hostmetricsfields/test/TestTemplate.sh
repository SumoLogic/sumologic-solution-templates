#!/bin/sh

export AWS_REGION=$1
export AWS_PROFILE=$2
# App to test
export AppName=$3
export InstallType=$4

# Sumo Logic Access Configuration
export Section1aSumoDeployment=$5
export Section1bSumoAccessID=$6
export Section1cSumoAccessKey=$7
export Section1dRemoveSumoResourcesOnDeleteStack=true

export Section2aAccountAlias=${InstallType}
export Section2bRegionList="us-east-1, us-east-2, us-west-1, us-west-2, ap-south-1, ap-northeast-2, ap-southeast-1, ap-southeast-2, ap-northeast-1, ca-central-1, eu-central-1, eu-west-1, eu-west-2, eu-west-3, eu-north-1, sa-east-1, ap-east-1"
export Section2cUpdateVersion=2


# Stack Name
export stackName="${AppName}asda"

aws cloudformation deploy --profile ${AWS_PROFILE} --template-file ./apps/${AppName}/host_metrics_add_fields.template.yaml --region ${AWS_REGION} \
--capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND --stack-name ${stackName} \
--parameter-overrides Section1aSumoDeployment="${Section1aSumoDeployment}" Section1bSumoAccessID="${Section1bSumoAccessID}" \
Section1cSumoAccessKey="${Section1cSumoAccessKey}" Section1dRemoveSumoResourcesOnDeleteStack="${Section1dRemoveSumoResourcesOnDeleteStack}" \
Section2aAccountAlias="${Section2aAccountAlias}" Section2cUpdateVersion="${Section2cUpdateVersion}" Section2bRegionList="${Section2bRegionList}"


