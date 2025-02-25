## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.16.2, < 6.0.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.1.0 |
| <a name="requirement_sumologic"></a> [sumologic](#requirement\_sumologic) | >= 2.31.3, < 4.0.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.11.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_sumologic"></a> [sumologic](#provider\_sumologic) | >= 2.31.3, < 4.0.0 |
| <a name="provider_time"></a> [time](#provider\_time) | >= 0.11.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_collection-module"></a> [collection-module](#module\_collection-module) | ../../../source-module | n/a |

## Resources

| Name | Type |
|------|------|
| [sumologic_field.account](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.accountid](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.apiname](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.cacheclusterid](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.clustername](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.dbclusteridentifier](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.dbidentifier](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.dbinstanceidentifier](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.functionname](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.instanceid](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.loadbalancer](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.loadbalancername](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.namespace](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.networkloadbalancer](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.queuename](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.region](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.tablename](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.topicname](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field_extraction_rule.AwsObservabilityAlbAccessLogsFER](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [sumologic_field_extraction_rule.AwsObservabilityApiGatewayCloudTrailLogsFER](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [sumologic_field_extraction_rule.AwsObservabilityDynamoDBCloudTrailLogsFER](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [sumologic_field_extraction_rule.AwsObservabilityEC2CloudTrailLogsFER](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [sumologic_field_extraction_rule.AwsObservabilityECSCloudTrailLogsFER](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [sumologic_field_extraction_rule.AwsObservabilityElastiCacheCloudTrailLogsFER](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [sumologic_field_extraction_rule.AwsObservabilityElbAccessLogsFER](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [sumologic_field_extraction_rule.AwsObservabilityFieldExtractionRule](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [sumologic_field_extraction_rule.AwsObservabilityGenericCloudWatchLogsFER](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [sumologic_field_extraction_rule.AwsObservabilityLambdaCloudWatchLogsFER](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [sumologic_field_extraction_rule.AwsObservabilityRdsCloudTrailLogsFER](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [sumologic_field_extraction_rule.AwsObservabilitySNSCloudTrailLogsFER](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [sumologic_field_extraction_rule.AwsObservabilitySQSCloudTrailLogsFER](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [time_sleep.wait_for_10_seconds](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alb_monitors"></a> [alb\_monitors](#input\_alb\_monitors) | Indicates if the ALB Apps monitors should be enabled. true to disable; false to enable. | `bool` | `true` | no |
| <a name="input_apps_folder"></a> [apps\_folder](#input\_apps\_folder) | Provide a folder name where all the apps will be installed under the Personal folder of the user whose access keys you have entered.<br/>            Default value will be: AWS Observability Apps | `string` | `"AWS Observability Apps"` | no |
| <a name="input_aws_account_alias"></a> [aws\_account\_alias](#input\_aws\_account\_alias) | Provide the Name/Alias for the AWS environment from which you are collecting data. This name will appear in the Sumo Logic Explorer View, metrics, and logs.<br/>            If you are going to deploy the solution in multiple AWS accounts then this value has to be overidden at main.tf file.<br/>            Do not include special characters in the alias. | `string` | n/a | yes |
| <a name="input_classic_lb_details"></a> [classic\_lb\_details](#input\_classic\_lb\_details) | Provide details for the Sumo Logic Classic Load Balancer source. If not provided, then defaults will be used.<br/>            To enable collection of classic load balancer logs, set collect\_classic\_lb\_logs to true and provide configuration information for the bucket.<br/>            If create\_bucket is false, provide a name of an existing S3 bucket where you would like to store loadbalancer logs. If this is empty, a new bucket will be created in the region.<br/>            If create\_bucket is true, the script creates a bucket, the name of the bucket has to be unique; this is achieved internally by generating a random-id and then post-fixing it to the “aws-observability-” string.<br/>            path\_expression - This is required in case the above existing bucket is already configured to receive Classic LB access logs. If this is blank, Sumo Logic will store logs in the path expression: *classicloadbalancing/AWSLogs/*/elasticloadbalancing/*/* | <pre>object({<br/>    source_name     = string<br/>    source_category = string<br/>    description     = string<br/>    bucket_details = object({<br/>      create_bucket        = bool<br/>      bucket_name          = string<br/>      path_expression      = string<br/>      force_destroy_bucket = bool<br/>    })<br/>    fields = map(string)<br/>  })</pre> | <pre>{<br/>  "bucket_details": {<br/>    "bucket_name": "aws-observability-random-id",<br/>    "create_bucket": true,<br/>    "force_destroy_bucket": true,<br/>    "path_expression": "*classicloadbalancing/AWSLogs/<ACCOUNT-ID>/elasticloadbalancing/<REGION-NAME>/*"<br/>  },<br/>  "description": "This source is created using Sumo Logic terraform AWS Observability module to collect AWS Classic LoadBalancer logs.",<br/>  "fields": {},<br/>  "source_category": "aws/observability/clb/logs",<br/>  "source_name": "Classic lb Logs (Region)"<br/>}</pre> | no |
| <a name="input_collect_classic_lb"></a> [collect\_classic\_lb](#input\_collect\_classic\_lb) | Create a Sumo Logic Classic LB Logs Source.<br/>            You have the following options:<br/>			true - to ingest load balancer logs into Sumo Logic. Creates a Sumo Logic Log Source that collects classic load balancer logs from an existing bucket or a new bucket.<br/>			If true, please configure \"classic\_lb\_source\_details\" with configuration information including the bucket name and path expression to ingest load balancer logs.<br/>			false - you are already ingesting load balancer logs into Sumo Logic. | `bool` | `true` | no |
| <a name="input_collect_cloudtrail"></a> [collect\_cloudtrail](#input\_collect\_cloudtrail) | Create a Sumo Logic CloudTrail Logs Source.<br/>            You have the following options:<br/>			true - to ingest cloudtrail logs into Sumo Logic. Creates a Sumo Logic CloudTrail Log Source that collects CloudTrail logs from an existing bucket or new bucket.<br/>			If true, please configure \"cloudtrail\_source\_details\" with configuration information to ingest cloudtrail logs.<br/>			false - you are already ingesting cloudtrail logs into Sumo Logic. | `bool` | `true` | no |
| <a name="input_collect_elb"></a> [collect\_elb](#input\_collect\_elb) | Create a Sumo Logic ALB Logs Source.<br/>            You have the following options:<br/>			true - to ingest load balancer logs into Sumo Logic. Creates a Sumo Logic Log Source that collects application load balancer logs from an existing bucket or a new bucket.<br/>			If true, please configure \"elb\_source\_details\" with configuration information including the bucket name and path expression to ingest load balancer logs.<br/>			false - you are already ingesting load balancer logs into Sumo Logic. | `bool` | `true` | no |
| <a name="input_collect_logs_cloudwatch"></a> [collect\_logs\_cloudwatch](#input\_collect\_logs\_cloudwatch) | Select the kind of Sumo Logic CloudWatch Logs Sources to create<br/>            You have the following options:<br/>            "Lambda Log Forwarder" - Creates a Sumo Logic CloudWatch Log Source that collects CloudWatch logs via a Lambda function.<br/>            "Kinesis Firehose Log Source" - Creates a Sumo Logic Kinesis Firehose Log Source to collect CloudWatch logs.<br/>            "None" - Skips installation of both sources. | `string` | `"Kinesis Firehose Log Source"` | no |
| <a name="input_collect_metric_cloudwatch"></a> [collect\_metric\_cloudwatch](#input\_collect\_metric\_cloudwatch) | Select the kind of CloudWatch Metrics Source to create<br/>            You have the following options:<br/>            "CloudWatch Metrics Source" - Creates Sumo Logic AWS CloudWatch Metrics Sources.<br/>            "Kinesis Firehose Metrics Source" (Recommended) - Creates a Sumo Logic AWS Kinesis Firehose for Metrics Source. Note: This new source has cost and performance benefits over the CloudWatch Metrics Source and is therefore recommended.<br/>            "None" - Skips the Installation of both the Sumo Logic Metric Sources | `string` | `"Kinesis Firehose Metrics Source"` | no |
| <a name="input_collect_rce"></a> [collect\_rce](#input\_collect\_rce) | Select the Sumo Logic Root Cause Explorer Source.<br/>            You have the following options:<br/>            Inventory Source - Creates a Sumo Logic Inventory Source used by Root Cause Explorer.<br/>            Xray Source - Creates a Sumo Logic AWS X-Ray Source that collects X-Ray Trace Metrics from your AWS account.<br/>            Both - Install both Inventory and Xray sources.<br/>            None - Skips installation of both sources. | `string` | `"Both"` | no |
| <a name="input_collector_id"></a> [collector\_id](#input\_collector\_id) | Required if you already have collector. | `string` | `""` | no |
| <a name="input_create_collector"></a> [create\_collector](#input\_create\_collector) | Create a Sumo Logic Collector.<br/>            You have the following options:<br/>			true - If you want to create collector.<br/>			false - If you already have a collector. | `bool` | `true` | no |
| <a name="input_create_s3_bucket"></a> [create\_s3\_bucket](#input\_create\_s3\_bucket) | Create a AWS S3 bucket.<br/>            You have the following options:<br/>			true - If you want to create S3 bucket.<br/>			false - If you already have a S3 bucket. | `bool` | `true` | no |
| <a name="input_ec2metrics_monitors"></a> [ec2metrics\_monitors](#input\_ec2metrics\_monitors) | Indicates if EC2 Metrics Apps monitors should be enabled. true to disable; false to enable. | `bool` | `true` | no |
| <a name="input_ecs_monitors"></a> [ecs\_monitors](#input\_ecs\_monitors) | Indicates if ECS Apps monitors should be enabled. true to disable; false to enable. | `bool` | `true` | no |
| <a name="input_elasticache_monitors"></a> [elasticache\_monitors](#input\_elasticache\_monitors) | Indicates if Elasticache Apps monitors should be enabled. true to disable; false to enable. | `bool` | `true` | no |
| <a name="input_elb_details"></a> [elb\_details](#input\_elb\_details) | Provide details for the Sumo Logic ALB source. If not provided, then defaults will be used.<br/>            To enable collection of application load balancer logs, set collect\_elb\_logs to true and provide configuration information for the bucket.<br/>            If create\_bucket is false, provide a name of an existing S3 bucket where you would like to store loadbalancer logs. If this is empty, a new bucket will be created in the region.<br/>            If create\_bucket is true, the script creates a bucket, the name of the bucket has to be unique; this is achieved internally by generating a random-id and then post-fixing it to the “aws-observability-” string.<br/>            path\_expression - This is required in case the above existing bucket is already configured to receive ALB access logs. If this is blank, Sumo Logic will store logs in the path expression: *elasticloadbalancing/AWSLogs/*/elasticloadbalancing/*/* | <pre>object({<br/>    source_name     = string<br/>    source_category = string<br/>    description     = string<br/>    bucket_details = object({<br/>      create_bucket        = bool<br/>      bucket_name          = string<br/>      path_expression      = string<br/>      force_destroy_bucket = bool<br/>    })<br/>    fields = map(string)<br/>  })</pre> | <pre>{<br/>  "bucket_details": {<br/>    "bucket_name": "aws-observability-random-id",<br/>    "create_bucket": true,<br/>    "force_destroy_bucket": true,<br/>    "path_expression": "*elasticloadbalancing/AWSLogs/<ACCOUNT-ID>/elasticloadbalancing/<REGION-NAME>/*"<br/>  },<br/>  "description": "This source is created using Sumo Logic terraform AWS Observability module to collect AWS Application LoadBalancer logs.",<br/>  "fields": {},<br/>  "source_category": "aws/observability/alb/logs",<br/>  "source_name": "Elb Logs (Region)"<br/>}</pre> | no |
| <a name="input_executeTest1"></a> [executeTest1](#input\_executeTest1) | True - If you want to execute this TestCase | `bool` | `false` | no |
| <a name="input_executeTest2"></a> [executeTest2](#input\_executeTest2) | True - If you want to execute this TestCase | `bool` | `false` | no |
| <a name="input_executeTest3"></a> [executeTest3](#input\_executeTest3) | True - If you want to execute this TestCase | `bool` | `false` | no |
| <a name="input_executeTest4"></a> [executeTest4](#input\_executeTest4) | True - If you want to execute this TestCase | `bool` | `false` | no |
| <a name="input_monitors_folder"></a> [monitors\_folder](#input\_monitors\_folder) | Provide a folder name where all the monitors will be installed under Monitor Folder.<br/>            Default value will be: AWS Observability Monitors | `string` | `"AWS Observability Monitors"` | no |
| <a name="input_s3_name"></a> [s3\_name](#input\_s3\_name) | Required if you already have a S3 bucket. | `string` | `""` | no |
| <a name="input_sumo_api_endpoint"></a> [sumo\_api\_endpoint](#input\_sumo\_api\_endpoint) | n/a | `string` | n/a | yes |
| <a name="input_sumologic_access_id"></a> [sumologic\_access\_id](#input\_sumologic\_access\_id) | Sumo Logic Access ID. Visit https://help.sumologic.com/Manage/Security/Access-Keys#Create_an_access_key | `string` | n/a | yes |
| <a name="input_sumologic_access_key"></a> [sumologic\_access\_key](#input\_sumologic\_access\_key) | Sumo Logic Access Key. Visit https://help.sumologic.com/Manage/Security/Access-Keys#Create_an_access_key | `string` | n/a | yes |
| <a name="input_sumologic_environment"></a> [sumologic\_environment](#input\_sumologic\_environment) | Enter au, ca, de, eu, fed, jp, kr, us1 or us2. For more information on Sumo Logic deployments visit https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security | `string` | n/a | yes |
| <a name="input_sumologic_folder_installation_location"></a> [sumologic\_folder\_installation\_location](#input\_sumologic\_folder\_installation\_location) | Indicates where to install the app folder. Enter "Personal Folder" for installing in "Personal" folder and "Admin Recommended Folder" for installing in "Admin Recommended" folder. | `string` | `"Personal Folder"` | no |
| <a name="input_sumologic_folder_share_with_org"></a> [sumologic\_folder\_share\_with\_org](#input\_sumologic\_folder\_share\_with\_org) | Indicates if AWS Observability folder should be shared (view access) with entire organization. true to enable; false to disable. | `bool` | `true` | no |
| <a name="input_sumologic_organization_id"></a> [sumologic\_organization\_id](#input\_sumologic\_organization\_id) | You can find your org on the Preferences page in the Sumo Logic UI. For more information, see the Preferences Page topic. Your org ID will be used to configure the IAM Role for Sumo Logic AWS Sources."<br/>            For more details, visit https://help.sumologic.com/01Start-Here/05Customize-Your-Sumo-Logic-Experience/Preferences-Page | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb_auto_enable_stack"></a> [alb\_auto\_enable\_stack](#output\_alb\_auto\_enable\_stack) | This output contains ALB auto enable CloudFormation Name. |
| <a name="output_alb_sns_sub"></a> [alb\_sns\_sub](#output\_alb\_sns\_sub) | This output contains ALB AWS SNS subscription arn. |
| <a name="output_alb_sns_topic"></a> [alb\_sns\_topic](#output\_alb\_sns\_topic) | This output contains AWS SNS topic arn. |
| <a name="output_aws_iam_role"></a> [aws\_iam\_role](#output\_aws\_iam\_role) | This output contains IAM role arn. |
| <a name="output_aws_s3"></a> [aws\_s3](#output\_aws\_s3) | This output contains AWS S3 bucket name. |
| <a name="output_aws_sns_topic"></a> [aws\_sns\_topic](#output\_aws\_sns\_topic) | This output contains AWS SNS topic arn. |
| <a name="output_classic_lb_sns_sub"></a> [classic\_lb\_sns\_sub](#output\_classic\_lb\_sns\_sub) | This output contains Classic ELB AWS SNS subscription arn. |
| <a name="output_classic_lb_sns_topic"></a> [classic\_lb\_sns\_topic](#output\_classic\_lb\_sns\_topic) | This output contains AWS SNS topic arn. |
| <a name="output_clb_auto_enable_stack"></a> [clb\_auto\_enable\_stack](#output\_clb\_auto\_enable\_stack) | This output contains CLB auto enable CloudFormation Name. |
| <a name="output_cloudtrail_sns_sub"></a> [cloudtrail\_sns\_sub](#output\_cloudtrail\_sns\_sub) | This output contains Cloudtrail AWS SNS subscription arn. |
| <a name="output_cloudtrail_sns_topic"></a> [cloudtrail\_sns\_topic](#output\_cloudtrail\_sns\_topic) | This output contains AWS SNS topic arn. |
| <a name="output_collection_folder_id"></a> [collection\_folder\_id](#output\_collection\_folder\_id) | This output contains sumologic Collections output. |
| <a name="output_cw_logs_auto_enable_stack"></a> [cw\_logs\_auto\_enable\_stack](#output\_cw\_logs\_auto\_enable\_stack) | This output contains CloudWatch logs cloudFormation stack. |
| <a name="output_cw_metrics_stream"></a> [cw\_metrics\_stream](#output\_cw\_metrics\_stream) | This output contains CloudWatch metrics stream Name. |
| <a name="output_kf_logs_auto_enable_stack"></a> [kf\_logs\_auto\_enable\_stack](#output\_kf\_logs\_auto\_enable\_stack) | This output contains Kinesis Firehose for logs auto enable CloudFormation Name. |
| <a name="output_kf_logs_stream"></a> [kf\_logs\_stream](#output\_kf\_logs\_stream) | This output contains Kinesis Firehose for logs stream Name. |
| <a name="output_kf_metrics_stream"></a> [kf\_metrics\_stream](#output\_kf\_metrics\_stream) | This output contains Kinesis Firehose for metrics stream Name. |
| <a name="output_log_forwarder_lambda_name"></a> [log\_forwarder\_lambda\_name](#output\_log\_forwarder\_lambda\_name) | This output contains Lambda logs forwarder Function Name. |
| <a name="output_sumologic_classic_lb_source"></a> [sumologic\_classic\_lb\_source](#output\_sumologic\_classic\_lb\_source) | This output contains sumologic Classic ELB source id. |
| <a name="output_sumologic_cloudtrail_source"></a> [sumologic\_cloudtrail\_source](#output\_sumologic\_cloudtrail\_source) | This output contains sumologic CloudTrail source id. |
| <a name="output_sumologic_cloudwatch_logs_source"></a> [sumologic\_cloudwatch\_logs\_source](#output\_sumologic\_cloudwatch\_logs\_source) | This output contains sumologic CloudWatch log source id. |
| <a name="output_sumologic_collector"></a> [sumologic\_collector](#output\_sumologic\_collector) | This output contains sumologic collector id. |
| <a name="output_sumologic_elb_source"></a> [sumologic\_elb\_source](#output\_sumologic\_elb\_source) | This output contains sumologic ALB source id. |
| <a name="output_sumologic_field_account"></a> [sumologic\_field\_account](#output\_sumologic\_field\_account) | This output contains sumologic Account field id. |
| <a name="output_sumologic_field_accountid"></a> [sumologic\_field\_accountid](#output\_sumologic\_field\_accountid) | This output contains sumologic accountid field id. |
| <a name="output_sumologic_field_apiname"></a> [sumologic\_field\_apiname](#output\_sumologic\_field\_apiname) | This output contains sumologic apiname field id. |
| <a name="output_sumologic_field_cacheclusterid"></a> [sumologic\_field\_cacheclusterid](#output\_sumologic\_field\_cacheclusterid) | This output contains sumologic cacheclusterid field id. |
| <a name="output_sumologic_field_clustername"></a> [sumologic\_field\_clustername](#output\_sumologic\_field\_clustername) | This output contains sumologic clustername field id. |
| <a name="output_sumologic_field_dbidentifier"></a> [sumologic\_field\_dbidentifier](#output\_sumologic\_field\_dbidentifier) | This output contains sumologic dbidentifier field id. |
| <a name="output_sumologic_field_functionname"></a> [sumologic\_field\_functionname](#output\_sumologic\_field\_functionname) | This output contains sumologic functionname field id. |
| <a name="output_sumologic_field_instanceid"></a> [sumologic\_field\_instanceid](#output\_sumologic\_field\_instanceid) | This output contains sumologic instanceid field id. |
| <a name="output_sumologic_field_loadbalancer"></a> [sumologic\_field\_loadbalancer](#output\_sumologic\_field\_loadbalancer) | This output contains sumologic loadbalancer field id. |
| <a name="output_sumologic_field_loadbalancername"></a> [sumologic\_field\_loadbalancername](#output\_sumologic\_field\_loadbalancername) | This output contains sumologic loadbalancername field id. |
| <a name="output_sumologic_field_namespace"></a> [sumologic\_field\_namespace](#output\_sumologic\_field\_namespace) | This output contains sumologic namespace field id. |
| <a name="output_sumologic_field_networkloadbalancer"></a> [sumologic\_field\_networkloadbalancer](#output\_sumologic\_field\_networkloadbalancer) | This output contains sumologic networkloadbalancer field id. |
| <a name="output_sumologic_field_region"></a> [sumologic\_field\_region](#output\_sumologic\_field\_region) | This output contains sumologic Region field id. |
| <a name="output_sumologic_field_tablename"></a> [sumologic\_field\_tablename](#output\_sumologic\_field\_tablename) | This output contains sumologic tablename field id. |
| <a name="output_sumologic_inventory_source"></a> [sumologic\_inventory\_source](#output\_sumologic\_inventory\_source) | This output contains sumologic aws inventory source id. |
| <a name="output_sumologic_kinesis_firehose_for_logs_source"></a> [sumologic\_kinesis\_firehose\_for\_logs\_source](#output\_sumologic\_kinesis\_firehose\_for\_logs\_source) | This output contains sumologic kinesis firehose for logs source id. |
| <a name="output_sumologic_kinesis_firehose_for_metrics_source"></a> [sumologic\_kinesis\_firehose\_for\_metrics\_source](#output\_sumologic\_kinesis\_firehose\_for\_metrics\_source) | This output contains sumologic kinesis firehose for metrics source id. |
| <a name="output_sumologic_xray_source"></a> [sumologic\_xray\_source](#output\_sumologic\_xray\_source) | This output contains sumologic aws xray source id. |
