# Sumo Logic - AWS Observability Solution Terraform

# This terraform variables file configures credentials and parameters for AWS Observability CloudFormation stack.
# For more information on Setting up AWS Observability, Please visit - https://help.sumologic.com/Solutions/AWS_Observability_Solution/03_Set_Up_the_AWS_Observability_Solution

## AWS CloudFormation Stack Name. Provide a unique AWS CloudFormation Stack Name.
# Please replace <YOUR STACK NAME> (including brackets) with stack name.
CloudFormationStackName = "<YOUR STACK NAME>"

# For more details on parameters, Please visit - https://help.sumologic.com/Solutions/AWS_Observability_Solution/03_Set_Up_the_AWS_Observability_Solution#Configuration_prompts_and_input

####### BELOW ARE REQUIRED PARAMETERS FOR CLOUDFORMATION STACK #######
# Visit - https://help.sumologic.com/Solutions/AWS_Observability_Solution/03_Set_Up_the_AWS_Observability_Solution#sumo-logic-access-configuration-required
Section1aSumoLogicDeployment                  = "<YOUR SUMO DEPLOYMENT>" # Please replace <YOUR SUMO DEPLOYMENT> (including brackets) with au, ca, de, eu, jp, us2, in, fed or us1.
Section1bSumoLogicAccessID                    = "<YOUR SUMO ACCESS ID>"  # Please replace <YOUR SUMO ACCESS ID> (including brackets) with your Sumo Logic Access ID.
Section1cSumoLogicAccessKey                   = "<YOUR SUMO ACCESS KEY>" # Please replace <YOUR SUMO ACCESS KEY> (including brackets) with your Sumo Logic Access KEY.
Section1dSumoLogicOrganizationId              = "<YOUR SUMO ORG ID>"     # Please replace <YOUR SUMO ORG ID> (including brackets) with your Sumo Logic Organization ID.
Section1eSumoLogicResourceRemoveOnDeleteStack = "true"
Section2aAccountAlias                         = "<YOUR AWS ACCOUNT ALIAS>" # Please replace <YOUR AWS ACCOUNT ALIAS> with an AWS account alias for identification in Sumo Logic Explorer View, metrics and logs.

####### BELOW ARE PARAMETERS WITH DEFAULT VALUES (can be modified as per requirements) FOR CLOUDFORMATION STACK #######

# Visit - https://help.sumologic.com/Solutions/AWS_Observability_Solution/03_Set_Up_the_AWS_Observability_Solution#sumo-logic-aws-observability-apps
Section3aInstallObservabilityApps = "Yes"

## Sumo Logic AWS CloudWatch Metrics and Inventory Source ##
# Visit - https://help.sumologic.com/Solutions/AWS_Observability_Solution/03_Set_Up_the_AWS_Observability_Solution#sumo-logic-aws-cloudwatch-metrics-and-inventory-source
Section4aCreateMetricsSourcesOptions    = "Both"
Section4bMetricsNameSpaces              = "AWS/ApplicationELB, AWS/ApiGateway, AWS/DynamoDB, AWS/Lambda, AWS/RDS, AWS/ECS, AWS/ElastiCache, AWS/ELB, AWS/NetworkELB"
Section4cCloudWatchExistingSourceAPIUrl = ""

## Sumo Logic AWS ALB Log Source ##
# Visit - https://help.sumologic.com/Solutions/AWS_Observability_Solution/03_Set_Up_the_AWS_Observability_Solution#sumo-logic-aws-alb-log-source-details
Section5aAutoEnableS3LogsALBResourcesOptions = "Both"
Section5bALBCreateLogSource                  = "Yes"
Section5cALBLogsSourceUrl                    = ""
Section5dALBS3LogsBucketName                 = ""
Section5eALBS3BucketPathExpression           = "*AWSLogs/*/elasticloadbalancing/*"

## Sumo Logic AWS CloudTrail Source ##
# Visit - https://help.sumologic.com/Solutions/AWS_Observability_Solution/03_Set_Up_the_AWS_Observability_Solution#sumo-logic-aws-cloudtrail-source
Section6aCreateCloudTrailLogSource      = "Yes"
Section6bCloudTrailLogsSourceUrl        = ""
Section6cCloudTrailLogsBucketName       = ""
Section6dCloudTrailBucketPathExpression = "AWSLogs/*/CloudTrail/*"

## Sumo Logic AWS Lambda CloudWatch HTTP Source ##
# Visit - https://help.sumologic.com/Solutions/AWS_Observability_Solution/03_Set_Up_the_AWS_Observability_Solution#sumo-logic-aws-lambda-cloudwatch-logs
Section7aLambdaCreateCloudWatchLogsSource    = "Yes"
Section7bLambdaCloudWatchLogsSourceUrl       = ""
Section7cAutoSubscribeLogGroupsLambdaOptions = "Both"
Section7dAutoSubscribeLambdaLogGroupPattern  = "lambda"

## Sumo Logic AWS X-Ray Source ##
# Visit - https://help.sumologic.com/Solutions/AWS_Observability_Solution/03_Set_Up_the_AWS_Observability_Solution#sumo-logic-aws-x-ray-source
Section8aCreateAwsXraySource = "Yes"