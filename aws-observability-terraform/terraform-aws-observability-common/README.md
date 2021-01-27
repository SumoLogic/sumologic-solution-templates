# terraform-aws-observability-common

Terraform module to setup Sumo Logic Sources and supporting AWS Resources for CloudTrail, ALB, Lambda CloudWatch Logs, CloudWatch Metrics, XRay, and Inventory.

## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 0.13 |
| aws | ~> 3.0 |
| external | ~> 2.0 |
| null | ~> 2.0 |
| sumologic | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 3.0 |
| external | ~> 2.0 |
| null | ~> 2.0 |
| sumologic | ~> 2.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| account\_alias | Provide an Alias for the AWS account for identification in Sumo Logic Explorer View, metrics, and logs. Please do not include special characters. | `string` | n/a | yes |
| alb\_logs\_source\_category | ALB logs source category. | `string` | `"aws/observability/alb/logs"` | no |
| alb\_logs\_source\_name | Name for the ALB logs source. | `string` | `"alb-logs"` | no |
| alb\_s3\_bucket | The preconfigured S3 bucket for ALB logs if the bucket is not managed in this module config. | `string` | `""` | no |
| alb\_s3\_bucket\_path\_expression | Path expression to match one or more S3 objects; e.g. 'ABC\*.log' or 'ABC.log'. | `string` | `"*"` | no |
| app\_bucket | S3 bucket name storing app JSON files to configure installations | `string` | `"sumologic-appdev-aws-sam-apps"` | no |
| aws\_inventory\_source\_category | The source category for the AWS inventory source | `string` | `"aws/observability/inventory"` | no |
| aws\_inventory\_source\_name | The Sumo Logic AWS Inventory Source name | `string` | `"inventory-aws"` | no |
| aws\_xray\_source\_category | The source category for the AWS xray source | `string` | `"aws/observability/xray"` | no |
| aws\_xray\_source\_name | The Sumo Logic AWS XRay Source name | `string` | `"xray-aws"` | no |
| cloudtrail\_logs\_s3\_bucket | The preconfigured S3 bucket for Cloudtrail logs if the bucket is not managed in this module config. | `string` | `""` | no |
| cloudtrail\_logs\_source\_category | Cloudtrail logs source category. | `string` | `"aws/observability/cloudtrail/logs"` | no |
| cloudtrail\_logs\_source\_name | Name for the Cloudtrail logs source. | `string` | `"cloudtrail-logs"` | no |
| cloudtrail\_s3\_bucket\_path\_expression | Path expression to match one or more S3 objects; e.g. 'ABC\*.log' or 'ABC.log'. | `string` | `"*"` | no |
| cloudwatch\_logs\_source\_category | Cloudwatch logs source category. | `string` | `"aws/observability/cloudwatch/logs"` | no |
| cloudwatch\_logs\_source\_name | Name for the Cloudwatch logs source. | `string` | `"cloudwatch-logs"` | no |
| cloudwatch\_metrics\_namespaces | List of the Cloudwatch metrics namespaces. | `list(string)` | <pre>[<br>  "AWS/ApplicationELB",<br>  "AWS/ApiGateway",<br>  "AWS/DynamoDB",<br>  "AWS/Lambda",<br>  "AWS/RDS",<br>  "AWS/ECS",<br>  "AWS/ElastiCache",<br>  "AWS/ELB",<br>  "AWS/NetworkELB"<br>]</pre> | no |
| cloudwatch\_metrics\_source\_category | Cloudwatch metrics source category. | `string` | `"aws/observability/cloudwatch/metrics"` | no |
| cloudwatch\_metrics\_source\_name | Cloudwatch metrics source name to override the default. If unspecified, the default name will be used. | `string` | `"cloudwatch-metrics"` | no |
| collector\_name | Name of the SumoLogic collector. | `string` | `"aws-observability"` | no |
| email\_id | Email for receiving alerts. A confirmation email is sent after the deployment is complete. It can be confirmed to subscribe for alerts. | `string` | `"test@gmail.com"` | no |
| include\_log\_group\_info | Enable loggroup/logstream values in logs. | `bool` | `true` | no |
| log\_format | Service for Cloudwatch logs source. | `string` | `"Others"` | no |
| log\_stream\_prefix | LogStream name prefixes to filter by logStream. Please note this is separate from a logGroup. This is used only to send certain logStreams within a Cloudwatch logGroup(s). LogGroups still need to be subscribed to the created Lambda function regardless of this input value. | `list(string)` | `[]` | no |
| manage\_alb\_logs\_source | Whether to manage the Sumo Logic ALB Log Source with provided bucket Name. | `bool` | `false` | no |
| manage\_alb\_s3\_bucket | Whether to manage the S3 bucket for ALB. Do not enable if you preconfigured a S3 bucket for this purpose. | `bool` | `false` | no |
| manage\_aws\_inventory\_source | Whether to manage the Sumo Logic AWS Inventory Source | `bool` | `true` | no |
| manage\_aws\_xray\_source | Whether to manage the Sumo Logic AWS XRay Source | `bool` | `true` | no |
| manage\_cloudtrail\_bucket | Whether to manage the Cloudtrail S3 bucket. Do not enable if you preconfigured a S3 bucket for Cloudtrail. | `bool` | `false` | no |
| manage\_cloudtrail\_logs\_source | Whether to manage the Sumo Logic Cloud Trail Log Source with provided bucket Name. | `bool` | `false` | no |
| manage\_cloudwatch\_logs\_source | Whether to manage the Sumo Logic Cloud Watch Log Source. | `bool` | `false` | no |
| manage\_cloudwatch\_metrics\_source | Whether to manage a Sumo Logic CloudWatch Metrics Source which collects Metrics for multiple Namespaces from the region selected. Do not enable if you preconfigured a CloudWatch Metrics Source to collect ALB metrics. | `string` | `false` | no |
| manage\_metadata\_source | Whether to manage the SumoLogic MetaData Source. A common metadata source will be managed with the region selected. Do not enable if you preconfigured a MetaData Source. | `bool` | `false` | no |
| managed\_apps | The list of applications to manage within the Sumo Logic AWS Observability Solution | <pre>map(object({<br>    app_version    = string<br>    config_version = string<br>    json           = string<br>  }))</pre> | <pre>{<br>  "RootCause": {<br>    "app_version": "V1.0.1",<br>    "config_version": "v2.1.0",<br>    "json": "Rce-App"<br>  }<br>}</pre> | no |
| metadata\_source\_category | EC2 metadata source category. | `string` | `"aws/observability/ec2/metadata"` | no |
| metadata\_source\_name | Metadata source name to override the default. If unspecified, the default name will be used. | `string` | `"metadata"` | no |
| scan\_interval | The scan interval to fetch metrics into Sumo Logic. | `number` | `300000` | no |
| sumologic\_access\_id | SumoLogic access id for API invocations. | `string` | n/a | yes |
| sumologic\_access\_key | SumoLogic access key for API invocations. | `string` | n/a | yes |
| sumologic\_environment | SumoLogic environment abbreviation. | `string` | n/a | yes |
| sumologic\_organization\_id | Appears on the Account Overview page that displays information about your Sumo Logic organization. Used for IAM Role in Sumo Logic AWS Sources. | `string` | n/a | yes |
| templates\_bucket | Prefix of the S3 bucket containing nested CFTs and Lambda code. | `string` | `"appdevzipfiles"` | no |
| workers | Number of lambda function invocations for Cloudwatch logs source Dead Letter Queue processing. | `number` | `4` | no |

## Outputs

| Name | Description |
|------|-------------|
| alb\_sns\_topic\_name | ALB SNS Topic Name |
| alb\_sns\_topic\_policy\_name | ALB SNS Topic Policy Name |
| alb\_sns\_topic\_subscription | ALB SNS Topic Policy Name |
| cloudtrail\_common\_name | AWS cloudtrail common name |
| cloudwatch\_logs\_source\_lambda\_arn | Cloudwatch logs source lambda arn. |
| cloudwatch\_metrics\_namespaces | CloudWatch Metrics Namespaces for Inventory Source. |
| common\_bucket | Exported attributes for the common bucket. |
| enterprise\_account | Check whether SumoLogic account is enterprise. |
| paid\_account | Check whether SumoLogic account is paid. |
