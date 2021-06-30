# AWS Observability Source Module

AWS Observability Source Module can be used to install CloudTrail, ELB, CloudWatch Metrics sources, Kinesis Firehose for Metrics source, CloudWatch Lambda Log Forwarder HTTP source, Kinesis Firehose for Logs source, Inventory and XRay sources.

The module can be used for multi AWS account and multi AWS region installation. Below is an example for multi account and region installation.

```terraform
# Region US-EAST-1, Account Production
provider "aws" {
  profile = "production"
  region  = "us-east-1"
  alias   = "production-us-east-1"
}

module "production-us-east-1" {
  source    = "../source-module"
  providers = { aws = aws.production-us-east-1 }

  aws_account_alias         = "production"
  sumologic_organization_id = "0000000000123456"

  collect_cloudtrail_logs    = true
  collect_elb_logs           = true
  collect_cloudwatch_metrics = "Kinesis Firehose Metrics Source"
  collect_cloudwatch_logs    = "Kinesis Firehose Log Source"
  collect_root_cause_data    = "Both"
}

# Region US-EAST-2, Account Production
provider "aws" {
  profile = "production"
  region  = "us-east-2"
  alias   = "production-us-east-2"
}

module "production-us-east-2" {
  source    = "../source-module"
  providers = { aws = aws.production-us-east-2 }

  aws_account_alias         = "production"
  sumologic_organization_id = "0000000000123456"

  # Use the same collector created for Prodcution account.
  sumologic_existing_collector_details = {
    create_collector = false
    collector_id     = module.production-us-east-1.sumologic_collector["collector"].id
  }

  collect_cloudtrail_logs    = true
  collect_elb_logs           = true
  collect_cloudwatch_metrics = "CloudWatch Metrics Source"
  collect_cloudwatch_logs    = "Lambda Log Forwarder"
  collect_root_cause_data    = "Both"
}

# Region US-WEST-1, Account Development
provider "aws" {
  profile = "development"
  region  = "us-west-1"
  alias   = "development-us-west-1"
}

module "development-us-west-1" {
  source    = "../source-module"
  providers = { aws = aws.development-us-west-1 }

  aws_account_alias         = "development"
  sumologic_organization_id = "0000000000123456"

  collect_cloudtrail_logs    = true
  collect_elb_logs           = true
  collect_cloudwatch_metrics = "Kinesis Firehose Metrics Source"
  collect_cloudwatch_logs    = "Kinesis Firehose Log Source"
  collect_root_cause_data    = "Both"
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13.0 |
| aws | >= 3.42.0 |
| random | >=3.1.0 |
| sumologic | >= 2.9.0 |
| time | >=0.7.1 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 3.42.0 |
| random | >=3.1.0 |
| sumologic | >= 2.9.0 |
| time | >=0.7.1 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| auto\_enable\_access\_logs | New - Automatically enables access logging for newly created ALB resources to collect logs for ALB resources. This does not affect ALB resources already collecting logs.<br>                              Existing - Automatically enables access logging for existing ALB resources to collect logs for ALB resources.<br>                               Both - Automatically enables access logging for new and existing ALB resources.<br>                               None - Skips Automatic access Logging enable for ALB resources. | `string` | `"Both"` | no |
| auto\_enable\_logs\_subscription | New - Automatically subscribes new log groups to send logs to Sumo Logic.<br>                              Existing - Automatically subscribes existing log groups to send logs to Sumo Logic.<br>                           Both - Automatically subscribes new and existing log groups.<br>                                None - Skips Automatic subscription. | `string` | `"Both"` | no |
| auto\_enable\_logs\_subscription\_options | filter - Enter regex for matching logGroups. Regex will check for the name. Visit https://help.sumologic.com/03Send-Data/Collect-from-Other-Data-Sources/Auto-Subscribe_AWS_Log_Groups_to_a_Lambda_Function#Configuring_parameters | <pre>object({<br>    filter = string<br>  })</pre> | <pre>{<br>  "filter": "lambda"<br>}</pre> | no |
| aws\_account\_alias | Provide an Alias for AWS account for identification in Sumo Logic Explorer View, metrics and logs. Please do not include special characters. | `string` | n/a | yes |
| cloudtrail\_source\_details | Provide details for the Sumo Logic CloudTrail source. If not provided, then defaults will be used. | <pre>object({<br>    source_name     = string<br>    source_category = string<br>    description     = string<br>    bucket_details = object({<br>      create_bucket        = bool<br>      bucket_name          = string<br>      path_expression      = string<br>      force_destroy_bucket = bool<br>    })<br>    fields = map(string)<br>  })</pre> | <pre>{<br>  "bucket_details": {<br>    "bucket_name": "aws-observability-random-id",<br>    "create_bucket": true,<br>    "force_destroy_bucket": true,<br>    "path_expression": "AWSLogs/<ACCOUNT-ID>/CloudTrail/<REGION-NAME>/*"<br>  },<br>  "description": "This source is created using Sumo Logic terraform AWS Observability module to collect AWS cloudtrail logs.",<br>  "fields": {},<br>  "source_category": "aws/observability/cloudtrail/logs",<br>  "source_name": "CloudTrail Logs (Region)"<br>}</pre> | no |
| cloudwatch\_logs\_source\_details | Provide details for the Sumo Logic Cloudwatch Logs source. If not provided, then defaults will be used. | <pre>object({<br>    source_name     = string<br>    source_category = string<br>    description     = string<br>    fields          = map(string)<br>    bucket_details = object({<br>      create_bucket        = bool<br>      bucket_name          = string<br>      force_destroy_bucket = bool<br>    })<br>    lambda_log_forwarder_config = object({<br>      email_id               = string<br>      workers                = number<br>      log_format             = string<br>      include_log_group_info = bool<br>      log_stream_prefix      = list(string)<br>    })<br>  })</pre> | <pre>{<br>  "bucket_details": {<br>    "bucket_name": "aws-observability-random-id",<br>    "create_bucket": true,<br>    "force_destroy_bucket": true<br>  },<br>  "description": "This source is created using Sumo Logic terraform AWS Observability module to collect AWS Cloudwatch Logs.",<br>  "fields": {},<br>  "lambda_log_forwarder_config": {<br>    "email_id": "test@gmail.com",<br>    "include_log_group_info": true,<br>    "log_format": "Others",<br>    "log_stream_prefix": [],<br>    "workers": 4<br>  },<br>  "source_category": "aws/observability/cloudwatch/logs",<br>  "source_name": "CloudWatch Logs (Region)"<br>}</pre> | no |
| cloudwatch\_metrics\_source\_details | Provide details for the Sumo Logic Cloudwatch Metrics source. If not provided, then defaults will be used. | <pre>object({<br>    source_name         = string<br>    source_category     = string<br>    description         = string<br>    limit_to_namespaces = list(string)<br>    fields              = map(string)<br>    bucket_details = object({<br>      create_bucket        = bool<br>      bucket_name          = string<br>      force_destroy_bucket = bool<br>    })<br>  })</pre> | <pre>{<br>  "bucket_details": {<br>    "bucket_name": "aws-observability-random-id",<br>    "create_bucket": true,<br>    "force_destroy_bucket": true<br>  },<br>  "description": "This source is created using Sumo Logic terraform AWS Observability module to collect AWS Cloudwatch metrics.",<br>  "fields": {},<br>  "limit_to_namespaces": [<br>    "AWS/ApplicationELB",<br>    "AWS/ApiGateway",<br>    "AWS/DynamoDB",<br>    "AWS/Lambda",<br>    "AWS/RDS",<br>    "AWS/ECS",<br>    "AWS/ElastiCache",<br>    "AWS/ELB",<br>    "AWS/NetworkELB",<br>    "AWS/SQS",<br>    "AWS/SNS"<br>  ],<br>  "source_category": "aws/observability/cloudwatch/metrics",<br>  "source_name": "CloudWatch Metrics (Region)"<br>}</pre> | no |
| collect\_cloudtrail\_logs | Provide \"true\" if you would like to ingest cloudtrail logs into Sumo Logic.<br>                 Please provide \"cloudtrail\_source\_details\" if would like to ingest cloudtrail logs.<br>                       Provide \"false\" if you are already ingesting logs into Sumo Logic. | `bool` | n/a | yes |
| collect\_cloudwatch\_logs | n/a | `string` | n/a | yes |
| collect\_cloudwatch\_metrics | n/a | `string` | n/a | yes |
| collect\_elb\_logs | Provide \"true\" if you would like to ingest Load Balancer logs into Sumo Logic.<br>                     Please provide \"elb\_source\_details\" if would like to ingest load balancer logs.<br>                   Provide \"false\" if you are already ingesting logs into Sumo Logic. | `bool` | n/a | yes |
| collect\_root\_cause\_data | n/a | `string` | n/a | yes |
| elb\_source\_details | Provide details for the Sumo Logic Elb source. If not provided, then defaults will be used. | <pre>object({<br>    source_name     = string<br>    source_category = string<br>    description     = string<br>    bucket_details = object({<br>      create_bucket        = bool<br>      bucket_name          = string<br>      path_expression      = string<br>      force_destroy_bucket = bool<br>    })<br>    fields = map(string)<br>  })</pre> | <pre>{<br>  "bucket_details": {<br>    "bucket_name": "aws-observability-random-id",<br>    "create_bucket": true,<br>    "force_destroy_bucket": true,<br>    "path_expression": "*AWSLogs/<ACCOUNT-ID>/elasticloadbalancing/<REGION-NAME>/*"<br>  },<br>  "description": "This source is created using Sumo Logic terraform AWS Observability module to collect AWS ELB logs.",<br>  "fields": {},<br>  "source_category": "aws/observability/alb/logs",<br>  "source_name": "Elb Logs (Region)"<br>}</pre> | no |
| existing\_iam\_details | Provide an existing AWS IAM role arn value which provides access to AWS S3 Buckets, AWS CloudWatch Metrics API and Sumo Logic Inventory data.<br>                    If kept empty, a new IAM role will be created with the required permissions.<br>                  For more details on permission, check /source-modules/template/sumologic\_aws\_permissions.tmpl file. | <pre>object({<br>    create_iam_role = bool<br>    iam_role_arn    = string<br>  })</pre> | <pre>{<br>  "create_iam_role": true,<br>  "iam_role_arn": ""<br>}</pre> | no |
| inventory\_source\_details | Provide details for the Sumo Logic AWS Inventory source. If not provided, then defaults will be used. | <pre>object({<br>    source_name         = string<br>    source_category     = string<br>    description         = string<br>    limit_to_namespaces = list(string)<br>    fields              = map(string)<br>  })</pre> | <pre>{<br>  "description": "This source is created using Sumo Logic terraform AWS Observability module to collect AWS inventory metadata.",<br>  "fields": {},<br>  "limit_to_namespaces": [<br>    "AWS/ApplicationELB",<br>    "AWS/ApiGateway",<br>    "AWS/DynamoDB",<br>    "AWS/Lambda",<br>    "AWS/RDS",<br>    "AWS/ECS",<br>    "AWS/ElastiCache",<br>    "AWS/ELB",<br>    "AWS/NetworkELB",<br>    "AWS/SQS",<br>    "AWS/SNS",<br>    "AWS/AutoScaling"<br>  ],<br>  "source_category": "aws/observability/inventory",<br>  "source_name": "AWS Inventory (Region)"<br>}</pre> | no |
| sumologic\_collector\_details | Provide details for the Sumo Logic collector. If not provided, then defaults will be used.<br>                        Collector will be created if any new source will be created and \"sumologic\_existing\_collector\_id\" is empty. | <pre>object({<br>    collector_name = string<br>    description    = string<br>    fields         = map(string)<br>  })</pre> | <pre>{<br>  "collector_name": "AWS Observability (AWS Account Alias) (Account ID)",<br>  "description": "This collector is created using Sumo Logic terraform AWS Observability module.",<br>  "fields": {}<br>}</pre> | no |
| sumologic\_existing\_collector\_details | Provide an existing Sumo Logic Collector ID. For more details, visit https://help.sumologic.com/03Send-Data/Sources/03Use-JSON-to-Configure-Sources/Local-Configuration-File-Management/View-or-Download-Source-JSON-Configuration<br>                        If provided, all the provided sources will be created within the collector.<br>                 If kept empty, a new Collector will be created and all provided sources will be created within that collector. | <pre>object({<br>    create_collector = bool<br>    collector_id     = string<br>  })</pre> | <pre>{<br>  "collector_id": "",<br>  "create_collector": true<br>}</pre> | no |
| sumologic\_organization\_id | Appears on the Account Overview page that displays information about your Sumo Logic organization. Used for IAM Role in Sumo Logic AWS Sources. | `string` | n/a | yes |
| wait\_for\_seconds | wait\_for\_seconds is used to delay sumo logic source creation. This helps persisting IAM role in AWS system.<br>        Default value is 180 seconds.<br>        If the AWS IAM role is created outside the module, the value can be decreased to 1 second. | `number` | `180` | no |
| xray\_source\_details | Provide details for the Sumo Logic AWS XRAY source. If not provided, then defaults will be used. | <pre>object({<br>    source_name     = string<br>    source_category = string<br>    description     = string<br>    fields          = map(string)<br>  })</pre> | <pre>{<br>  "description": "This source is created using Sumo Logic terraform AWS Observability module to collect AWS Xray metrics.",<br>  "fields": {},<br>  "source_category": "aws/observability/xray",<br>  "source_name": "AWS Xray (Region)"<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| aws\_cloudtrail | AWS Trail created to send CloudTrail logs to AWS S3 bucket. |
| aws\_cloudwatch\_metric\_stream | CloudWatch metrics stream to send metrics. |
| aws\_iam\_role | Sumo Logic AWS IAM Role for trust relationship. |
| aws\_kinesis\_firehose\_logs\_delivery\_stream | AWS Kinesis firehose delivery stream to send logs to Sumo Logic. |
| aws\_kinesis\_firehose\_metrics\_delivery\_stream | AWS Kinesis firehose delivery stream to send metrics to Sumo Logic. |
| aws\_s3\_bucket | Common S3 Bucket to store CloudTrail, ELB and Failed Kinesis data. |
| aws\_sns\_topic | Common SNS topic attached to the S3 bucket. |
| cloudtrail\_sns\_subscription | AWS SNS subscription to Sumo Logic AWS CloudTrail source. |
| cloudtrail\_sns\_topic | SNS topic created to be attached to an existing cloudtrail bucket. |
| cloudtrail\_source | Sumo Logic AWS CloudTrail source. |
| cloudwatch\_logs\_auto\_subscribe\_stack | AWS CloudFormation stack for Auto Enable logs subscription. |
| cloudwatch\_logs\_lambda\_function | AWS Lambda function to send logs to Sumo Logic. |
| cloudwatch\_logs\_source | Sumo Logic HTTP source. |
| cloudwatch\_metrics\_source | Sumo Logic AWS CloudWatch Metrics source. |
| elb\_auto\_enable\_stack | AWS CloudFormation stack for ALB Auto Enable access logs. |
| elb\_sns\_subscription | AWS SNS subscription to Sumo Logic AWS ELB source. |
| elb\_sns\_topic | SNS topic created to be attached to an existing elb logs bucket. |
| elb\_source | Sumo Logic AWS ELB source. |
| inventory\_source | Sumo Logic AWS Inventory source. |
| kinesis\_firehose\_for\_logs\_auto\_subscribe\_stack | AWS CloudFormation stack for Auto Enable logs subscription. |
| kinesis\_firehose\_for\_logs\_source | Sumo Logic Kinesis Firehose for Logs source. |
| kinesis\_firehose\_for\_metrics\_source | Sumo Logic AWS Kinesis Firehose for Metrics source. |
| sumologic\_collector | Sumo Logic collector details. |
| xray\_source | Sumo Logic AWS Xray source. |
