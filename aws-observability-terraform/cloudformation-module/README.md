# sumologic-aws-observability-terraform

The AWS Observability Solution provides an established framework to simplify the monitoring and troubleshooting of your AWS cloud infrastructure. The AWS Observability Solution can be deployed across multiple accounts and regions:
- minimizing the time it takes to get operational insights across your AWS infrastructure.
- identifying elements that are subject to specific operational issues across your AWS infrastructure.
- minimizing the time it takes to assign operational to the correct business units and functional teams in your AWS infrastructure.

*This Terraform script installs the Sumo Logic AWS Observability solution CloudFormation template in your AWS account to setup all necessary Sumo Logic and AWS Resources.*

*The Terraform solution will deploy the Solution Per AWS Account Per AWS Region only. For deploying as multiple AWS account Multiple AWS regions, please [visit](https://help.sumologic.com/Solutions/AWS_Observability_Solution/03_Set_Up_the_AWS_Observability_Solution#Multi_Account.2C_Multi_Region_installation_using_Stack_Sets).*

For more details, Please look at [Sumo Logic AWS Observability Help Document](https://help.sumologic.com/Solutions/AWS_Observability_Solution/About_the_AWS_Observability_Solution).

## Getting Started

#### Requirements

* [Terraform 0.12.20+](https://www.terraform.io/downloads.html)
* Required Terraform providers (tested on mentioned versions), these providers are automatically installed on `terraform init`:
  * [Null](https://www.terraform.io/docs/providers/null/index.html) "~> 2.1"
  * [AWS Terraform Provider](https://www.terraform.io/docs/providers/aws/index.html) "~> 3.0"
  * [Sumo Logic Terraform Provider](https://www.terraform.io/docs/providers/sumologic/index.html) "~> 2.0"

#### Setup working directory

1. Clone the repository:

```shell
$ git clone https://github.com/SumoLogic/sumologic-solution-templates.git
```
2. Install [Terraform](https://www.terraform.io/) and make sure it's on your PATH.
3. Initialize the Terraform working directory and download the official providers by navigating to the directory `sumologic-solution-templates/aws-observability-terraform` and running `terraform init`. This will install the required Terraform providers i.e. [Sumo Logic Terraform Provider](https://www.terraform.io/docs/providers/sumologic/index.html), [Null](https://www.terraform.io/docs/providers/null/index.html) and [AWS Terraform Provider](https://www.terraform.io/docs/providers/aws/index.html).
4. You can choose which Sumo Logic apps, Sumo Logic sources and AWS S3 Buckets to install by updating various flags in `main_variables.auto.tfvars`.
5. Update the placeholder values in `main_variables.auto.tfvars` so they correspond with your Sumo Logic and AWS environments. See the [list of input parameters](#configurable-parameters) below.
6. Update the AWS provider in `main.tf` so it correspond to the AWS environment and region where you would like to deploy the Solution.

#### Deploy Sumo Logic - AWS Observability Solution

To deploy Sumo Logic - AWS Observability Solution, navigate to the directory `sumologic-solution-templates/aws-observability-terraform` and execute the below commands:

```shell
$ terraform plan
$ terraform apply
```
#### Uninstall Sumo Logic - AWS Observability Solution

To uninstall the solution, navigate to the directory `sumologic-solution-templates/aws-observability-terraform` and execute the below command:

```shell
$ terraform destroy
```
There are times when you want to plan the destroy prior to executing the command. To do so, add the -destroy flag to the terraform plan command and then apply the destroy command, for example:

```shell
$ terraform plan -destroy
$ terraform destroy
```

## Configurable Parameters

Configure the following parameters in `main_variables.auto.tfvars`. For more details on the parameters, [visit](https://help.sumologic.com/Solutions/AWS_Observability_Solution/03_Set_Up_the_AWS_Observability_Solution#Configuration_prompts_and_input).

| Parameter |Description |Default Value
| --- | --- | --- |
| CloudFormationStackName | A unique name for your AWS CloudFormation Stack | |
| Section1aSumoLogicDeployment | Enter au, ca, de, eu, jp, us2, in, fed or us1. [Visit](https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security) | |
| Section1bSumoLogicAccessID | Sumo Logic Access ID. [Visit](https://help.sumologic.com/Manage/Security/Access-Keys#Create_an_access_key) | |
| Section1cSumoLogicAccessKey| Sumo Logic Access Key. | |
| Section1dSumoLogicOrganizationId | Appears on the Account Overview page that displays information about your Sumo Logic organization. Used for IAM Role in Sumo Logic AWS Sources. [Visit](https://help.sumologic.com/01Start-Here/05Customize-Your-Sumo-Logic-Experience/Preferences-Page) | |
| Section1eSumoLogicResourceRemoveOnDeleteStack | To delete collectors, sources and apps when the stack is deleted, set this parameter to True. Default is True. Deletes the resources created by the stack. Deletion of updated resources will be skipped. | true |
| Section2aAccountAlias | Provide an Alias for AWS account for identification in Sumo Logic Explorer View, metrics and logs. Please do not include special characters. | |
| Section3aInstallObservabilityApps | Yes - Installs Apps (EC2, Application Load Balancer, RDS, API Gateway, Lambda, Dynamo DB, ECS, ElastiCache and NLB) and Alerts for the Sumo Logic AWS Observability Solution. All the Apps are installed in the folder 'AWS Observability'.<br><br> No - Skips the installation of Apps and Alerts. | Yes |
| Section4aCreateMetricsSourceOptions | CloudWatch Metrics Source - Creates Sumo Logic AWS CloudWatch Metrics Sources.<br><br> Kinesis Firehose Metrics Source -  Creates a Sumo Logic AWS Kinesis Firehose for Metrics Source. | Kinesis Firehose Metrics Source |
| Section4bMetricsNameSpaces | Provide Comma delimited list of the namespaces which will be used for both AWS CLoudWatch Metrics and Inventory Sources. Default will be AWS/ApplicationELB, AWS/ApiGateway, AWS/DynamoDB, AWS/Lambda, AWS/RDS, AWS/ECS, AWS/ElastiCache, AWS/ELB, AWS/NetworkELB, AWS/SQS, AWS/SNS. AWS/AutoScaling will be appended to Namespaces for Inventory Sources. | AWS/ApplicationELB, AWS/ApiGateway, AWS/DynamoDB, AWS/Lambda, AWS/RDS, AWS/ECS, AWS/ElastiCache, AWS/ELB, AWS/NetworkELB, AWS/SQS, AWS/SNS |
| Section4cCloudWatchExistingSourceAPIUrl | Required when already collecting CloudWatch Metrics. Provide the existing Sumo Logic CloudWatch Metrics Source API URL. Account Field will be added to the Source. For Source API URL, [visit](https://help.sumologic.com/03Send-Data/Sources/03Use-JSON-to-Configure-Sources/Local-Configuration-File-Management/View-or-Download-Source-JSON-Configuration) | |
| Section5aAutoEnableS3LogsALBResourcesOptions | New - Automatically enables S3 logging for newly created ALB resources to collect logs for ALB resources. This does not affect ALB resources already collecting logs.<br><br> Existing - Automatically enables S3 logging for existing ALB resources to collect logs for ALB resources.<br><br> Both - Automatically enables S3 logging for new and existing ALB resources.<br><br> None - Skips Automatic S3 Logging enable for ALB resources. | Both |
| Section5bALBCreateLogSource | Yes - Creates a Sumo Logic ALB Log Source that collects ALB logs from an existing bucket or a new bucket.<br><br> No - If you already have an ALB source collecting ALB logs into Sumo Logic. | Yes |
| Section5cALBLogsSourceUrl | Required when already collecting ALB logs in Sumo Logic. Provide the existing Sumo Logic ALB Source API URL. Account, region and namespace Fields will be added to the Source. For Source API URL, [visit](https://help.sumologic.com/03Send-Data/Sources/03Use-JSON-to-Configure-Sources/Local-Configuration-File-Management/View-or-Download-Source-JSON-Configuration) | |
| Section5dALBS3LogsBucketName | If you selected 'No' to creating a new source above, skip this step. Provide a name of existing S3 bucket name where you would like to store ALB logs. If this is empty, a new bucket will be created in the region. | |
| Section5eALBS3BucketPathExpression | This is required in case the above existing bucket is already configured to receive ALB access logs. If this is blank, Sumo Logic will store logs in the path expression: *AWSLogs/*/elasticloadbalancing/* | *AWSLogs/*/elasticloadbalancing/* |
| Section6aCreateCloudTrailLogSource | Yes - Creates a Sumo Logic CloudTrail Log Source that collects CloudTrail logs from an existing bucket or a new bucket.<br><br> No - If you already have a CloudTrail Log source collecting CloudTrail logs into Sumo Logic. | Yes |
| Section6bCloudTrailLogsSourceUrl | Required when already collecting CloudTrail logs in Sumo Logic. Provide the existing Sumo Logic CloudTrail Source API URL. Account Field will be added to the Source. For Source API URL, [visit](https://help.sumologic.com/03Send-Data/Sources/03Use-JSON-to-Configure-Sources/Local-Configuration-File-Management/View-or-Download-Source-JSON-Configuration) | |
| Section6cCloudTrailLogsBucketName | If you selected 'No' to creating a new source above, skip this step. Provide a name of existing S3 bucket name where you would like to store CloudTrail logs. If this is empty, a new bucket will be created in the region. | |
| Section6dCloudTrailBucketPathExpression | This is required in case the above existing bucket is already configured to receive CloudTrail logs. If this is blank, Sumo Logic will store logs in the path expression: AWSLogs/*/CloudTrail/* | AWSLogs/*/CloudTrail/* |
| Section7aLambdaCreateCloudWatchLogsSourceOptions | Lambda Log Forwarder - Creates a Sumo Logic CloudWatch Log Source that collects CloudWatch logs via a Lambda function.<br><br> Kinesis Firehose Log Source - Creates a Sumo Logic Kinesis Firehose Source to collect CloudWatch logs. | Kinesis Firehose Log Source |
| Section7bLambdaCloudWatchLogsSourceUrl | Required when already collecting Lambda CloudWatch logs in Sumo Logic. Provide the existing Sumo Logic Lambda CloudWatch Source API URL. Account, region and namespace Fields will be added to the Source. For Source API URL, [visit](https://help.sumologic.com/03Send-Data/Sources/03Use-JSON-to-Configure-Sources/Local-Configuration-File-Management/View-or-Download-Source-JSON-Configuration) | |
| Section7cAutoSubscribeLogGroupsLambdaOptions | New - Automatically subscribes new log groups to lambda to send logs to Sumo Logic.<br><br> Existing - Automatically subscribes existing log groups to lambda to send logs to Sumo Logic.<br><br> Both - Automatically subscribes new and existing log groups.<br><br> None - Skips Automatic subscription. | Both |
| Section7dAutoSubscribeLambdaLogGroupPattern | Enter regex for matching logGroups. Regex will check for the name. [Visit](https://help.sumologic.com/03Send-Data/Collect-from-Other-Data-Sources/Auto-Subscribe_AWS_Log_Groups_to_a_Lambda_Function#Configuring_parameters) | lambda |
| Section8aRootCauseExplorerOptions | Inventory Source - Creates a Sumo Logic Inventory Source used by Root Cause Explorer.<br><br> Xray Source - Creates a Sumo Logic AWS X-Ray Source that collects X-Ray Trace Metrics from your AWS account. | Both |

## License

The AWS Observability Terraform is licensed under the apache v2.0 license.

## Issues

Raise issues at [Issues](https://github.com/SumoLogic/sumologic-solution-templates/issues)

## Contributing

* Fork the project on [Github](https://github.com/SumoLogic/sumologic-solution-templates).
* Make your feature addition or fix bug, write tests and commit.
* Create a pull request with one of the maintainer as Reviewer.