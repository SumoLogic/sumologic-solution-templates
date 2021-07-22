# Sumo Logic - AWS Observability Solution Terraform

# This terraform script is used to deploy the AWS Observability CloudFormation Template.
# For more information on Setting up AWS Observability, Please refer - https://help.sumologic.com/Solutions/AWS_Observability_Solution/03_Set_Up_the_AWS_Observability_Solution

# Configure the AWS Provider. Please configure the aws provider with required settings.
provider "aws" {
  version = "~> 3.0"
}

# Sumo Logic Provider
provider "sumologic" {
  access_id   = var.Section1bSumoLogicAccessID
  access_key  = var.Section1cSumoLogicAccessKey
  environment = var.Section1aSumoLogicDeployment
}

# Fetch the Personal folder to test the Access Key and Access ID.
data "sumologic_personal_folder" "personalFolder" {}

resource "aws_cloudformation_stack" "aws-observability" {
  name = var.CloudFormationStackName

  parameters = {
    # Sumo Logic Access Configuration (Required)
    Section1aSumoLogicDeployment                  = var.Section1aSumoLogicDeployment
    Section1bSumoLogicAccessID                    = var.Section1bSumoLogicAccessID
    Section1cSumoLogicAccessKey                   = var.Section1cSumoLogicAccessKey
    Section1dSumoLogicOrganizationId              = var.Section1dSumoLogicOrganizationId
    Section1eSumoLogicResourceRemoveOnDeleteStack = var.Section1eSumoLogicResourceRemoveOnDeleteStack
    # AWS Account Alias
    Section2aAccountAlias = var.Section2aAccountAlias
    # Sumo Logic AWS Observability Apps
    Section3aInstallObservabilityApps = var.Section3aInstallObservabilityApps
    # Sumo Logic AWS CloudWatch Metrics and Inventory Source
    Section4aCreateMetricsSourceOptions     = var.Section4aCreateMetricsSourceOptions
    Section4bMetricsNameSpaces              = var.Section4bMetricsNameSpaces
    Section4cCloudWatchExistingSourceAPIUrl = var.Section4cCloudWatchExistingSourceAPIUrl
    # Sumo Logic AWS ALB Log Source
    Section5aAutoEnableS3LogsALBResourcesOptions = var.Section5aAutoEnableS3LogsALBResourcesOptions
    Section5bALBCreateLogSource                  = var.Section5bALBCreateLogSource
    Section5cALBLogsSourceUrl                    = var.Section5cALBLogsSourceUrl
    Section5dALBS3LogsBucketName                 = var.Section5dALBS3LogsBucketName
    Section5eALBS3BucketPathExpression           = var.Section5eALBS3BucketPathExpression
    # Sumo Logic AWS CloudTrail Source
    Section6aCreateCloudTrailLogSource      = var.Section6aCreateCloudTrailLogSource
    Section6bCloudTrailLogsSourceUrl        = var.Section6bCloudTrailLogsSourceUrl
    Section6cCloudTrailLogsBucketName       = var.Section6cCloudTrailLogsBucketName
    Section6dCloudTrailBucketPathExpression = var.Section6dCloudTrailBucketPathExpression
    # Sumo Logic AWS Lambda CloudWatch HTTP Source
    Section7aLambdaCreateCloudWatchLogsSourceOptions = var.Section7aLambdaCreateCloudWatchLogsSourceOptions
    Section7bLambdaCloudWatchLogsSourceUrl           = var.Section7bLambdaCloudWatchLogsSourceUrl
    Section7cAutoSubscribeLogGroupsLambdaOptions     = var.Section7cAutoSubscribeLogGroupsLambdaOptions
    Section7dAutoSubscribeLambdaLogGroupPattern      = var.Section7dAutoSubscribeLambdaLogGroupPattern
    # Sumo Logic AWS X-Ray Source
    Section8aRootCauseExplorerOptions = var.Section8aRootCauseExplorerOptions
  }

  template_url = "https://sumologic-appdev-aws-sam-apps.s3.amazonaws.com/aws-observability-versions/v2.2.0/sumologic_observability.master.template.yaml"

  capabilities = [
    "CAPABILITY_IAM",
    "CAPABILITY_NAMED_IAM",
  "CAPABILITY_AUTO_EXPAND"]
}
