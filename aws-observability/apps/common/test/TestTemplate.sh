#!/bin/sh

export AWS_REGION=$1
export AWS_PROFILE=$2
# App to test
export AppName=$3
export InstallType=$4

export uid=`cat /dev/random | LC_CTYPE=C tr -dc "[:lower:]" | head -c 6`

# Sumo Logic Access Configuration
export SumoLogicDeployment=$5
export SumoLogicAccessID=$6
export SumoLogicAccessKey=$7
export SumoLogicOrganizationId=$8
export RemoveSumoLogicResourcesOnDeleteStack=true

export AccountAlias=${InstallType}
export CollectorName="Sourabh Collector ${InstallType}"
export CloudWatchMetricsNameSpaces="AWS/RDS"
export AwsInventoryNamespaces="AWS/RDS"

export CreateMetaDataSource="No"
export CreateCloudWatchMetricsSource="No"
export CreateALBLogSource="No"
export CreateALBS3Bucket="No"
export CreateCloudTrailLogSource="No"
export CreateCloudTrailBucket="No"
export CreateCloudWatchLogSource="No"
export CreateAwsInventorySource="No"

if [[ "${InstallType}" == "onlymetadatasource" ]]
then
    export CreateMetaDataSource="Yes"
    export MetaDataSourceName="metadata ${AppName} ${InstallType}"
elif [[ "${InstallType}" == "onlycwsource" ]]
then
    export CreateCloudWatchMetricsSource="Yes"
    export CloudWatchMetricsSourceName="CloudWatch Metrics ${AppName} ${InstallType}"
elif [[ "${InstallType}" == "onlyinventorysource" ]]
then
    export CreateAwsInventorySource="Yes"
    export AwsInventorySourceName="Inventory ${AppName} ${InstallType}"
elif [[ "${InstallType}" == "onlyalbwithnewbucket" ]]
then
    export CreateALBLogSource="Yes"
    export CreateALBS3Bucket="Yes"
    export ALBLogsSourceName="ALB Logs ${AppName} ${InstallType}"
    export ALBS3LogsBucketName="sumologiclambdahelper-${AWS_REGION}"
    export ALBS3BucketPathExpression="elasticloadbalancing"
elif [[ "${InstallType}" == "onlyalbwithexitingbucket" ]]
then
    export CreateALBLogSource="Yes"
    export CreateALBS3Bucket="No"
    export ALBLogsSourceName="ALB Logs ${AppName} ${InstallType}"
    export ALBS3LogsBucketName="sumologiclambdahelper-${AWS_REGION}"
    export ALBS3BucketPathExpression="elasticloadbalancing"
elif [[ "${InstallType}" == "onlyctwithnewbucket" ]]
then
    export CreateCloudTrailLogSource="Yes"
    export CreateCloudTrailBucket="Yes"
    export CloudTrailLogsBucketName="sumologiclambdahelper-${AWS_REGION}"
    export CloudTrailBucketPathExpression="cloudtrail"
    export CloudTrailLogsSourceName="CloudTrail Logs ${AppName} ${InstallType}"
elif [[ "${InstallType}" == "onlyctwithexistingbucket" ]]
then
    export CreateCloudTrailLogSource="Yes"
    export CreateCloudTrailBucket="No"
    export CloudTrailLogsBucketName="sumologiclambdahelper-${AWS_REGION}"
    export CloudTrailBucketPathExpression="cloudtrail"
    export CloudTrailLogsSourceName="CloudTrail Logs ${AppName} ${InstallType}"
elif [[ "${InstallType}" == "onlycwlogs" ]]
then
    export CreateCloudWatchLogSource="Yes"
    export CloudWatchLogsSourceName="CloudWatch Logs ${AppName} ${InstallType}"
elif [[ "${InstallType}" == "albexibucketctnewbucket" ]]
then
    export CreateCloudTrailLogSource="Yes"
    export CreateCloudTrailBucket="Yes"
    export CloudTrailLogsSourceName="CloudTrail Logs ${AppName} ${InstallType}"
    export CreateALBLogSource="Yes"
    export CreateALBS3Bucket="No"
    export ALBLogsSourceName="ALB Logs ${AppName} ${InstallType}"
    export ALBS3LogsBucketName="sumologiclambdahelper-${AWS_REGION}"
    export ALBS3BucketPathExpression="elasticloadbalancing"
elif [[ "${InstallType}" == "albnewbucketctexisbucket" ]]
then
    export CreateCloudTrailLogSource="Yes"
    export CreateCloudTrailBucket="No"
    export CloudTrailLogsBucketName="sumologiclambdahelper-${AWS_REGION}"
    export CloudTrailBucketPathExpression="cloudtrail"
    export CloudTrailLogsSourceName="CloudTrail Logs ${AppName} ${InstallType}"
    export CreateALBLogSource="Yes"
    export CreateALBS3Bucket="Yes"
    export ALBLogsSourceName="ALB Logs ${AppName} ${InstallType}"
elif [[ "${InstallType}" == "albctwithnewbucket" ]]
then
    export CreateCloudTrailLogSource="Yes"
    export CreateCloudTrailBucket="Yes"
    export CloudTrailLogsSourceName="CloudTrail Logs ${AppName} ${InstallType}"
    export CreateALBLogSource="Yes"
    export CreateALBS3Bucket="Yes"
    export ALBLogsSourceName="ALB Logs ${AppName} ${InstallType}"
elif [[ "${InstallType}" == "albctwithexisbucket" ]]
then
    export CreateCloudTrailLogSource="Yes"
    export CreateCloudTrailBucket="No"
    export CloudTrailLogsBucketName="sumologiclambdahelper-${AWS_REGION}"
    export CloudTrailBucketPathExpression="cloudtrail"
    export CloudTrailLogsSourceName="CloudTrail Logs ${AppName} ${InstallType}"
    export CreateALBLogSource="Yes"
    export CreateALBS3Bucket="No"
    export ALBLogsSourceName="ALB Logs ${AppName} ${InstallType}"
    export ALBS3LogsBucketName="sumologiclambdahelper-${AWS_REGION}"
    export ALBS3BucketPathExpression="elasticloadbalancing"
elif [[ "${InstallType}" == "all" ]]
then
    export CreateMetaDataSource="Yes"
    export MetaDataSourceName="metadata ${AppName} ${InstallType}"
    export CreateCloudWatchMetricsSource="Yes"
    export CloudWatchMetricsSourceName="CloudWatch Metrics ${AppName} ${InstallType}"
    export CreateALBLogSource="Yes"
    export CreateALBS3Bucket="Yes"
    export ALBLogsSourceName="ALB Logs ${AppName} ${InstallType}"
    export CreateCloudTrailLogSource="Yes"
    export CreateCloudTrailBucket="Yes"
    export CloudTrailLogsSourceName="CloudTrail Logs ${AppName} ${InstallType}"
    export CreateCloudWatchLogSource="Yes"
    export CloudWatchLogsSourceName="CloudWatch Logs ${AppName} ${InstallType}"
    export ALBS3BucketPathExpression="elasticloadbalancing"
    export CloudTrailBucketPathExpression="cloudtrail"
    export CreateAwsInventorySource="Yes"
    export AwsInventorySourceName="Inventory ${AppName} ${InstallType}"
else
    echo "No Valid Choice."
fi

# Stack Name
export stackName="${AppName}-${InstallType}"

aws cloudformation deploy --profile ${AWS_PROFILE} --template-file ./apps/${AppName}/resources.template.yaml --region ${AWS_REGION} \
--capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND --stack-name ${stackName} \
--parameter-overrides SumoLogicDeployment="${SumoLogicDeployment}" SumoLogicAccessID="${SumoLogicAccessID}" \
SumoLogicAccessKey="${SumoLogicAccessKey}" SumoLogicOrganizationId="${SumoLogicOrganizationId}" \
RemoveSumoLogicResourcesOnDeleteStack="${RemoveSumoLogicResourcesOnDeleteStack}" AccountAlias="${AccountAlias}" \
CollectorName="${CollectorName}" CreateMetaDataSource="${CreateMetaDataSource}" \
MetaDataSourceName="${MetaDataSourceName}" CreateCloudWatchMetricsSource="${CreateCloudWatchMetricsSource}" \
CloudWatchMetricsSourceName="${CloudWatchMetricsSourceName}" CloudWatchMetricsSourceName="${CloudWatchMetricsSourceName}" \
CreateALBLogSource="${CreateALBLogSource}" CreateALBS3Bucket="${CreateALBS3Bucket}" \
ALBLogsSourceName="${ALBLogsSourceName}" CreateCloudTrailLogSource="${CreateCloudTrailLogSource}" \
CreateCloudTrailBucket="${CreateCloudTrailBucket}" CloudTrailLogsSourceName="${CloudTrailLogsSourceName}" \
CreateCloudWatchLogSource="${CreateCloudWatchLogSource}" CloudWatchLogsSourceName="${CloudWatchLogsSourceName}" \
CloudTrailLogsBucketName="${CloudTrailLogsBucketName}" CloudTrailBucketPathExpression="${CloudTrailBucketPathExpression}" \
ALBS3LogsBucketName="${ALBS3LogsBucketName}" ALBS3BucketPathExpression="${ALBS3BucketPathExpression}" CloudWatchMetricsNameSpaces="${CloudWatchMetricsNameSpaces}" \
CreateAwsInventorySource="${CreateAwsInventorySource}" AwsInventorySourceName="${AwsInventorySourceName}" AwsInventoryNamespaces="${AwsInventoryNamespaces}"