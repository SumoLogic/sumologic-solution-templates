#!/bin/sh

echo "Testing for Master Template....................."

export AWS_REGION=$1
export AWS_PROFILE=$2
export TEMPLATE_S3_BUCKET="cf-templates-1qpf3unpuo1hw-ap-south-1"
# App to test
export AppName=$3
export InstallType=$4

export uid=`cat /dev/random | LC_CTYPE=C tr -dc "[:lower:]" | head -c 6`

# Sumo Logic Access Configuration
export Section1aSumoLogicDeployment=$5
export Section1bSumoLogicAccessID=$6
export Section1cSumoLogicAccessKey=$7
export Section1dSumoLogicOrganizationId=$8
export Section1eSumoLogicResourceRemoveOnDeleteStack=true

export Section2aAccountAlias="${InstallType}"
export Section6fAutoEnableS3LogsFilterExpression=".*"
export Section7dAutoSubscribeLambdaLogGroupPattern=".*"

export Section3aInstallObservabilityApps="No"
export Section4aCreateMetricsSourcesOptions="None"
export Section5bALBCreateLogSource="No"
export Section5aAutoEnableS3LogsALBResourcesOptions="None"
export Section6aCreateCloudTrailLogSource="No"
export Section7aLambdaCreateCloudWatchLogsSource="No"
export Section7cAutoSubscribeLogGroupsLambdaOptions="None"


# By Default, we create explorer view, Metric Rules and FER, as we need them for each case.
# Stack Name
export stackName="${AppName}-${InstallType}"

# onlyapps - Installs only the apps in Sumo Logic.
if [[ "${InstallType}" == "onlyapps" ]]
then
    export Section3aInstallObservabilityApps="Yes"
# onlys3autoenableexisting - Enable S3 logging for existing ALB. Needs an existing bucket or takes if new bucket is created otherwise stack creation fails.
elif [[ "${InstallType}" == "onlys3autoenableexisting" ]]
then
    export Section5aAutoEnableS3LogsALBResourcesOptions="Existing"
    export Section5dALBS3LogsBucketName="sumologiclambdahelper-${AWS_REGION}"
# onlys3autoenablenew - Enable S3 logging for new ALB. Needs an existing bucket or takes if new bucket is created otherwise stack creation fails.
elif [[ "${InstallType}" == "onlys3autoenablenew" ]]
then
    export Section5aAutoEnableS3LogsALBResourcesOptions="New"
    export Section5dALBS3LogsBucketName="sumologiclambdahelper-${AWS_REGION}"
# onlys3autoenable - Enable S3 logging for both ALB. Needs an existing bucket or takes if new bucket is created otherwise stack creation fails.
elif [[ "${InstallType}" == "onlys3autoenable" ]]
then
    export Section5aAutoEnableS3LogsALBResourcesOptions="Both"
    export Section5dALBS3LogsBucketName="sumologiclambdahelper-${AWS_REGION}"
# onlymetricssourceemptyname - Only Creates the CloudWatch Metrics Source with "" EMPTY namespaces.
elif [[ "${InstallType}" == "onlymetricssourceemptyname" ]]
then
    export Section4aCreateMetricsSourcesOptions="CloudWatchMetrics"
    export Section4bMetricsNameSpaces=""
# onlymetricssourcewithname - Only Creates the CloudWatch Metrics Source with namespaces AWS/ApplicationELB, AWS/ApiGateway, AWS/DynamoDB, AWS/Lambda, AWS/RDS.
elif [[ "${InstallType}" == "onlymetricssourcewithname" ]]
then
    export Section4aCreateMetricsSourcesOptions="CloudWatchMetrics"
    export Section4bMetricsNameSpaces="AWS/EC2, AWS/ApplicationELB, AWS/ApiGateway, AWS/DynamoDB, AWS/Lambda, AWS/RDS, AWS/EBS, AWS/ECS, AWS/ElastiCache, AWS/ELB, AWS/NetworkELB, AWS/Redshift, AWS/Kinesis, AWS/AutoScaling"
# updateexistingmetricsource - update the existing metric source
elif [[ "${InstallType}" == "updatemetricsource" ]]
then
    export Section4cCloudWatchExistingSourceAPIUrl="https://api.sumologic.com/api/v1/collectors/171619902/sources/796322092"
# onlyanomalywithname - Only Creates the Anamoly Source with namespaces AWS/ApplicationELB, AWS/ApiGateway, AWS/DynamoDB, AWS/Lambda, AWS/RDS.
elif [[ "${InstallType}" == "onlyanomalywithname" ]]
then
    export Section4aCreateMetricsSourcesOptions="InventorySource"
    export Section4bMetricsNameSpaces="AWS/EC2, AWS/ApplicationELB, AWS/ApiGateway, AWS/DynamoDB, AWS/Lambda, AWS/RDS, AWS/EBS, AWS/ECS, AWS/ElastiCache, AWS/ELB, AWS/NetworkELB, AWS/Redshift, AWS/Kinesis, AWS/AutoScaling"
# onlycloudtrailwithbucket - Only Creates the CloudTrail Logs Source with new Bucket.
elif [[ "${InstallType}" == "onlycloudtrailwithbucket" ]]
then
    export Section6aCreateCloudTrailLogSource="Yes"
# onlycloudtrailexisbucket - Only Creates the CloudTrail Logs Source with existing Bucket. If no "" empty bucket provided with empty bucket name, it fails.
elif [[ "${InstallType}" == "onlycloudtrailexisbucket" ]]
then
    export Section6aCreateCloudTrailLogSource="Yes"
    export Section6dCloudTrailBucketPathExpression="AWSLogs/Sourabh/Test"
    export Section6cCloudTrailLogsBucketName="sumologiclambdahelper-${AWS_REGION}"
# updatecloudtrailsource - Only updates the CloudTrail Logs Source with if Collector name and source name is provided.
elif [[ "${InstallType}" == "updatecloudtrailsource" ]]
then
    export Section6bCloudTrailLogsSourceUrl="https://api.sumologic.com/api/v1/collectors/171619902/sources/794157405"
# cwlogssourceonly - Creates a Cloudwatch logs source, with lambda function of log group connector.
elif [[ "${InstallType}" == "cwlogssourceonly" ]]
then
    export Section7aLambdaCreateCloudWatchLogsSource="Yes"
# cwlogssourcenewlambdaautosub - Creates a Cloudwatch logs source, with lambda function of log group connector with auto subscribe only for new lambda.
elif [[ "${InstallType}" == "cwlogssourcenewlambdaautosub" ]]
then
    export Section7aLambdaCreateCloudWatchLogsSource="Yes"
    export Section7cAutoSubscribeLogGroupsLambdaOptions="New"
# cwlogssourceexitlambdaautosub - Creates a Cloudwatch logs source, with lambda function of log group connector WITHOUT auto subscribe only for new lambda.
elif [[ "${InstallType}" == "cwlogssourceexitlambdaautosub" ]]
then
    export Section7aLambdaCreateCloudWatchLogsSource="Yes"
    export Section7cAutoSubscribeLogGroupsLambdaOptions="Existing"
# cwlogssourcebothlambdaautosub - Creates a Cloudwatch logs source, with lambda function of log group connector WITH auto subscribe only for new and existing lambda.
elif [[ "${InstallType}" == "cwlogssourcebothlambdaautosub" ]]
then
    export Section7aLambdaCreateCloudWatchLogsSource="Yes"
    export Section7cAutoSubscribeLogGroupsLambdaOptions="Both"
    export Section7dAutoSubscribeLambdaLogGroupPattern="lambda"
# cwlogssourcebothlambdaautosub - update the cloudwatch source if collector name and source name is provided.
elif [[ "${InstallType}" == "updatecwlogssource" ]]
then
    export Section7bLambdaCloudWatchLogsSourceUrl="https://api.sumologic.com/api/v1/collectors/171619902/sources/794162256"
# albsourcewithbukcetwithauto - Creates only ALB source with new bucket along with auto subscribe.
elif [[ "${InstallType}" == "albsourcewithbukcetwithauto" ]]
then
    export Section5bALBCreateLogSource="Yes"
    export Section5aAutoEnableS3LogsALBResourcesOptions="Both"
# albsourceexistingbukcet - Creates only ALB source with new existing bucket.
elif [[ "${InstallType}" == "albsourceexistingbukcet" ]]
then
    export Section5bALBCreateLogSource="Yes"
    export Section5dALBS3LogsBucketName="sumologiclambdahelper-${AWS_REGION}"
    export Section5eALBS3BucketPathExpression="Labs/ALB/sourabh"
# updatealbsource - updates only ALB source with provided collector and source.
elif [[ "${InstallType}" == "updatealbsource" ]]
then
    export Section5cALBLogsSourceUrl="https://api.sumologic.com/api/v1/collectors/171619902/sources/794166127"
# onlysources - creates all sources with common bucket creation for ALB and CloudTrail with auto enable option.
elif [[ "${InstallType}" == "onlysources" ]]
then
    export Section4aCreateMetricsSourcesOptions="Both"
    export Section5bALBCreateLogSource="Yes"
    export Section6aCreateCloudTrailLogSource="Yes"
    export Section7aLambdaCreateCloudWatchLogsSource="Yes"
    export Section5aAutoEnableS3LogsALBResourcesOptions="Existing"
# albexistingcloudtrialnew - creates ALB source with existing bucket and CloudTrail with new bucket. Create CW metrics source also.
elif [[ "${InstallType}" == "albexistingcloudtrialnew" ]]
then
    export Section4aCreateMetricsSourcesOptions="CloudWatchMetrics"
    export Section4bMetricsNameSpaces="AWS/ApplicationELB, AWS/ApiGateway"
    export Section5bALBCreateLogSource="Yes"
    export Section5dALBS3LogsBucketName="sumologiclambdahelper-${AWS_REGION}"
    export Section5eALBS3BucketPathExpression="Labs/ALB/asasdas"
    export Section6aCreateCloudTrailLogSource="Yes"
# albnewcloudtrialexisting - creates ALB source with new bucket and CloudTrail with Existing bucket. Create EC2 source also.
elif [[ "${InstallType}" == "albnewcloudtrialexisting" ]]
then
    export Section5bALBCreateLogSource="Yes"
    export Section6aCreateCloudTrailLogSource="Yes"
    export Section6dCloudTrailBucketPathExpression="AWSLogs/Sourabh/Test"
    export Section6cCloudTrailLogsBucketName="sumologiclambdahelper-${AWS_REGION}"
# albec2apiappall - creates everything for EC2, ALB and API Gateway apps.
elif [[ "${InstallType}" == "albec2apiappall" ]]
then
    export Section3aInstallObservabilityApps="Yes"
    export Section5aAutoEnableS3LogsALBResourcesOptions="Both"
    export Section4aCreateMetricsSourcesOptions="CloudWatchMetrics"
    export Section4bMetricsNameSpaces="AWS/ApplicationELB, AWS/ApiGateway"
    export Section5bALBCreateLogSource="Yes"
    export Section6aCreateCloudTrailLogSource="Yes"
# rdsdynamolambdaappall - creates everything for RDS, DYNAMO DB and LAMBDA apps.
elif [[ "${InstallType}" == "rdsdynamolambdaappall" ]]
then
    export Section3aInstallObservabilityApps="Yes"
    export Section7cAutoSubscribeLogGroupsLambdaOptions="Both"
    export Section7dAutoSubscribeLambdaLogGroupPattern="lambda"
    export Section4aCreateMetricsSourcesOptions="InventorySource"
    export Section4bMetricsNameSpaces="AWS/DynamoDB, AWS/Lambda, AWS/RDS"
    export Section6aCreateCloudTrailLogSource="Yes"
    export Section7aLambdaCreateCloudWatchLogsSource="Yes"
# onlyappswithexistingsources - Install Apps with existing sources. This should Update the CloudTrail, CloudWatch and ALB sources.
elif [[ "${InstallType}" == "onlyappswithexistingsources" ]]
then
    export Section3aInstallObservabilityApps="No"
    export Section5aAutoEnableS3LogsALBResourcesOptions="None"
    export Section5dALBS3LogsBucketName="sumologiclambdahelper-${AWS_REGION}"
    export Section7cAutoSubscribeLogGroupsLambdaOptions="None"
    export Section7dAutoSubscribeLambdaLogGroupPattern="lambda"
    export Section5cALBLogsSourceUrl="https://api.sumologic.com/api/v1/collectors/171619902/sources/794170215"
    export Section6bCloudTrailLogsSourceUrl="https://api.sumologic.com/api/v1/collectors/171619902/sources/794170202"
    export Section7bLambdaCloudWatchLogsSourceUrl="https://api.sumologic.com/api/v1/collectors/171619902/sources/794170214"
    export Section4cCloudWatchExistingSourceAPIUrl=""
# defaultparameters - Install CF with default parameters.
elif [[ "${InstallType}" == "defaultparameters" ]]
then
    echo "Doing Default Installation .............................."
    aws cloudformation deploy --profile ${AWS_PROFILE} --template-file ./templates/sumologic_observability.master.template.yaml --region ${AWS_REGION} \
    --capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND --stack-name ${stackName} \
    --parameter-overrides Section1aSumoLogicDeployment="${Section1aSumoLogicDeployment}" Section1bSumoLogicAccessID="${Section1bSumoLogicAccessID}" \
    Section1cSumoLogicAccessKey="${Section1cSumoLogicAccessKey}" Section1dSumoLogicOrganizationId="${Section1dSumoLogicOrganizationId}" \
    Section1eSumoLogicResourceRemoveOnDeleteStack="${Section1eSumoLogicResourceRemoveOnDeleteStack}" Section2aAccountAlias="${Section2aAccountAlias}"
else
    echo "No Valid Choice."
fi

if [[ "${InstallType}" != "defaultparameters" ]]
then
    aws cloudformation deploy --profile ${AWS_PROFILE} --template-file ./templates/sumologic_observability.master.template.yaml --region ${AWS_REGION} \
    --capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND --stack-name ${stackName} \
    --parameter-overrides Section1aSumoLogicDeployment="${Section1aSumoLogicDeployment}" Section1bSumoLogicAccessID="${Section1bSumoLogicAccessID}" \
    Section1cSumoLogicAccessKey="${Section1cSumoLogicAccessKey}" Section1dSumoLogicOrganizationId="${Section1dSumoLogicOrganizationId}" \
    Section1eSumoLogicResourceRemoveOnDeleteStack="${Section1eSumoLogicResourceRemoveOnDeleteStack}" Section2aAccountAlias="${Section2aAccountAlias}" \
    Section2dTagAWSResourcesFilterExpression="${Section2dTagAWSResourcesFilterExpression}" Section3aInstallObservabilityApps="${Section3aInstallObservabilityApps}" \
    Section4aCreateMetricsSourcesOptions="${Section4aCreateMetricsSourcesOptions}" \
    Section4bMetricsNameSpaces="${Section4bMetricsNameSpaces}" Section5bALBCreateLogSource="${Section5bALBCreateLogSource}" Section5dALBS3LogsBucketName="${Section5dALBS3LogsBucketName}" \
    Section5eALBS3BucketPathExpression="${Section5eALBS3BucketPathExpression}" Section5cALBLogsSourceUrl="${Section5cALBLogsSourceUrl}" Section5aAutoEnableS3LogsALBResourcesOptions="${Section5aAutoEnableS3LogsALBResourcesOptions}" \
    Section6fAutoEnableS3LogsFilterExpression="${Section6fAutoEnableS3LogsFilterExpression}" Section6aCreateCloudTrailLogSource="${Section6aCreateCloudTrailLogSource}" \
    Section6cCloudTrailLogsBucketName="${Section6cCloudTrailLogsBucketName}" Section6dCloudTrailBucketPathExpression="${Section6dCloudTrailBucketPathExpression}" \
    Section6bCloudTrailLogsSourceUrl="${Section6bCloudTrailLogsSourceUrl}" Section7aLambdaCreateCloudWatchLogsSource="${Section7aLambdaCreateCloudWatchLogsSource}" \
    Section7bLambdaCloudWatchLogsSourceUrl="${Section7bLambdaCloudWatchLogsSourceUrl}" Section7cAutoSubscribeLogGroupsLambdaOptions="${Section7cAutoSubscribeLogGroupsLambdaOptions}" \
    Section7dAutoSubscribeLambdaLogGroupPattern="${Section7dAutoSubscribeLambdaLogGroupPattern}" Section4cCloudWatchExistingSourceAPIUrl="${Section4cCloudWatchExistingSourceAPIUrl}"
fi