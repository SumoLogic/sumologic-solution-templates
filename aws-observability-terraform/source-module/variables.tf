variable "environment" {
 type        = string
 description = "Enter au, ca, de, eu, fed, in, jp, kr, us1 or us2. For more information on Sumo Logic deployments visit https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security"

 validation {
  condition = contains([
    "au",
    "ca",
    "de",
    "eu",
    "fed",
    "in",
    "jp",
    "kr",
    "us1",
    "us2"], var.environment)
  error_message = "The value must be one of au, ca, de, eu, fed, in, jp, kr, us1 or us2."
  }
}

variable "access_id" {
 type        = string
 description = "Sumo Logic Access ID. Visit https://help.sumologic.com/Manage/Security/Access-Keys#Create_an_access_key"

 validation {
   condition     = can(regex("\\w+", var.access_id))
   error_message = "The SumoLogic access ID must contain valid characters."
 }
}

variable "access_key" {
 type        = string
 description = "Sumo Logic Access Key. Visit https://help.sumologic.com/Manage/Security/Access-Keys#Create_an_access_key"
 sensitive = true
 validation {
   condition     = can(regex("\\w+", var.access_key))
   error_message = "The SumoLogic access key must contain valid characters."
 }
}

variable "cloudwatch_metrics_source_url" {
  type        = string
  description = "Required if you are already collecting CloudWatch Metrics. Provide the existing Sumo Logic Metrics Source API URL. If the URL is of “CloudWatch Metric source” - account and accountID fields will be added to the Source. If the URL is of “Kinesis Firehose Metrics source” - account field will be added to the Source. For information on how to determine the URL, see [View or Download Source JSON Configuration](https://help.sumologic.com/03Send-Data/Sources/03Use-JSON-to-Configure-Sources/Local-Configuration-File-Management/View-or-Download-Source-JSON-Configuration)."
  default = ""
}

variable "cloudtrail_source_url" {
  type        = string
  description = "Required if you are already collecting CloudTrail logs. Provide the existing Sumo Logic CloudTrail Source API URL. The account field will be added to the Source. For information on how to determine the URL, see [View or Download Source JSON Configuration](https://help.sumologic.com/03Send-Data/Sources/03Use-JSON-to-Configure-Sources/Local-Configuration-File-Management/View-or-Download-Source-JSON-Configuration)."
  default = ""
}

variable "elb_log_source_url" {
  type        = string
  description = "Required if you are already collecting ALB logs. Provide the existing Sumo Logic ALB Source API URL. The account, accountid, and region fields will be added to the Source. For information on how to determine the URL, see [View or Download Source JSON Configuration](https://help.sumologic.com/03Send-Data/Sources/03Use-JSON-to-Configure-Sources/Local-Configuration-File-Management/View-or-Download-Source-JSON-Configuration)."
  default = ""
}

variable "classic_lb_log_source_url" {
  type        = string
  description = "Required if you are already collecting Classic LB logs. Provide the existing Sumo Logic Classic LB Source API URL. The account, accountid, and region fields will be added to the Source. For information on how to determine the URL, see [View or Download Source JSON Configuration](https://help.sumologic.com/03Send-Data/Sources/03Use-JSON-to-Configure-Sources/Local-Configuration-File-Management/View-or-Download-Source-JSON-Configuration)."
  default = ""
}

variable "cloudwatch_logs_source_url" {
  type        = string
  description = "Required if you are already collecting AWS Lambda CloudWatch logs. Provide the existing Sumo Logic AWS Lambda CloudWatch Source API URL. The account, accountid, region and namespace fields will be added to the Source. For information on how to determine the URL, see [View or Download Source JSON Configuration](https://help.sumologic.com/03Send-Data/Sources/03Use-JSON-to-Configure-Sources/Local-Configuration-File-Management/View-or-Download-Source-JSON-Configuration)."
  default = ""
}

variable "aws_account_alias" {
  type        = string
  description = <<EOT
            Provide the Name/Alias for the AWS environment from which you are collecting data. This name will appear in the Sumo Logic Explorer View, metrics, and logs.
            Please leave this blank if you are going to deploy the solution in multiple AWS accounts.
            Do not include special characters in the alias.
        EOT
  validation {
    condition     = can(regex("[a-z0-9]*", var.aws_account_alias))
    error_message = "Alias must only contain lowercase letters, number and length less than or equal to 30 characters."
  }
}

variable "sumologic_organization_id" {
  type        = string
  description = <<EOT
            You can find your org on the Preferences page in the Sumo Logic UI. For more information, see the Preferences Page topic. Your org ID will be used to configure the IAM Role for Sumo Logic AWS Sources."
            For more details, visit https://help.sumologic.com/01Start-Here/05Customize-Your-Sumo-Logic-Experience/Preferences-Page
        EOT
  validation {
    condition     = can(regex("\\w+", var.sumologic_organization_id))
    error_message = "The organization ID must contain valid characters."
  }
}

variable "existing_iam_details" {
  type = object({
    create_iam_role = bool
    iam_role_arn    = string
  })
  description = <<EOT
			Provide an existing AWS IAM role arn value which provides access to AWS S3 Buckets, AWS CloudWatch Metrics API and Sumo Logic Inventory data.
			If kept empty, a new IAM role will be created with the required permissions.
			For more details on permissions, check the iam policy tmpl files at /source-module/templates folder.
		EOT
  default = {
    create_iam_role = true
    iam_role_arn    = ""
  }
}

variable "wait_for_seconds" {
  type        = number
  description = <<EOT
            wait_for_seconds is used to delay sumo logic source creation. The value is in seconds. This helps persisting the IAM role in the AWS system.
            Default value is 180 seconds.
            If the AWS IAM role is created outside the module, the value can be decreased to 1 second.
        EOT
  default     = 180
}

variable "sumologic_existing_collector_details" {
  type = object({
    create_collector = bool
    collector_id     = string
  })
  description = <<EOT
			Provide an existing Sumo Logic Collector ID. For more details, visit https://help.sumologic.com/03Send-Data/Sources/03Use-JSON-to-Configure-Sources/Local-Configuration-File-Management/View-or-Download-Source-JSON-Configuration
			If provided, all the provided sources will be created within the collector.
			If kept empty, a new Collector will be created and all provided sources will be created within that collector.
		EOT
  default = {
    create_collector = true
    collector_id     = ""
  }
}

variable "sumologic_collector_details" {
  type = object({
    collector_name = string
    description    = string
    fields         = map(string)
  })
  description = <<EOT
			Provide details for the Sumo Logic collector. If not provided, then defaults will be used.
			The Collector will be created if any new source will be created and \"sumologic_existing_collector_id\" is empty.
		EOT
  default = {
    collector_name = "AWS Observability (AWS Account Alias) (Account ID)"
    description    = "This collector is created using Sumo Logic terraform AWS Observability module."
    fields         = {}
  }
}

variable "collect_cloudtrail_logs" {
  type        = bool
  description = <<EOT
            Create a Sumo Logic CloudTrail Logs Source.
            You have the following options:
			true - to ingest cloudtrail logs into Sumo Logic. Creates a Sumo Logic CloudTrail Log Source that collects CloudTrail logs from an existing bucket or new bucket.
			If true, please configure \"cloudtrail_source_details\" with configuration information to ingest cloudtrail logs.
			false - you are already ingesting cloudtrail logs into Sumo Logic.
		EOT
  default     = true
}

variable "cloudtrail_source_details" {
  type = object({
    source_name     = string
    source_category = string
    description     = string
    bucket_details = object({
      create_bucket        = bool
      bucket_name          = string
      path_expression      = string
      force_destroy_bucket = bool
    })
    fields = map(string)
  })
  description = <<EOT
            Provide details for the Sumo Logic CloudTrail source. If not provided, then defaults will be used.
            To enable, set collect_cloudtrail_logs to true and provide configuration information for the bucket at bucket_details.
            If create_bucket is false, provide a name of an existing S3 bucket where you would like to store CloudTrail logs. If this is empty, a new bucket will be created in the region.
            If create_bucket is true, the script creates a bucket, the name of the bucket has to be unique; this is achieved internally by generating a random-id and then post-fixing it to the “aws-observability-” string.
            path_expression - This is required in case the above existing bucket is already configured to receive CloudTrail logs. If this is blank, Sumo Logic will store logs in the path expression AWSLogs/*/CloudTrail/*/*.
        EOT
  default = {
    source_name     = "CloudTrail Logs (Region)"
    source_category = "aws/observability/cloudtrail/logs"
    description     = "This source is created using Sumo Logic terraform AWS Observability module to collect AWS cloudtrail logs."
    bucket_details = {
      create_bucket        = true
      bucket_name          = "aws-observability-random-id"
      path_expression      = "AWSLogs/<ACCOUNT-ID>/CloudTrail/<REGION-NAME>/*"
      force_destroy_bucket = true
    }
    fields = {}
  }
  validation {
    condition     = can(regex("[a-z0-9-.]{3,63}$", var.cloudtrail_source_details.bucket_details.bucket_name))
    error_message = "3-63 characters; must contain only lowercase letters, numbers, hyphen or period. For more details - https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html."
  }
}

variable "collect_elb_logs" {
  type        = bool
  description = <<EOT
            Create a Sumo Logic ALB Logs Source.
            You have the following options:
			true - to ingest load balancer logs into Sumo Logic. Creates a Sumo Logic Log Source that collects application load balancer logs from an existing bucket or a new bucket.
			If true, please configure \"elb_source_details\" with configuration information including the bucket name and path expression to ingest load balancer logs.
			false - you are already ingesting load balancer logs into Sumo Logic.
		EOT
  default     = true
}

variable "collect_classic_lb_logs" {
  type        = bool
  description = <<EOT
            Create a Sumo Logic Classic LB Logs Source.
            You have the following options:
			true - to ingest load balancer logs into Sumo Logic. Creates a Sumo Logic Log Source that collects classic load balancer logs from an existing bucket or a new bucket.
			If true, please configure \"classic_lb_source_details\" with configuration information including the bucket name and path expression to ingest load balancer logs.
			false - you are already ingesting load balancer logs into Sumo Logic.
		EOT
  default     = true
}

variable "elb_source_details" {
  type = object({
    source_name     = string
    source_category = string
    description     = string
    bucket_details = object({
      create_bucket        = bool
      bucket_name          = string
      path_expression      = string
      force_destroy_bucket = bool
    })
    fields = map(string)
  })
  description = <<EOT
            Provide details for the Sumo Logic ALB source. If not provided, then defaults will be used.
            To enable collection of application load balancer logs, set collect_elb_logs to true and provide configuration information for the bucket.
            If create_bucket is false, provide a name of an existing S3 bucket where you would like to store loadbalancer logs. If this is empty, a new bucket will be created in the region.
            If create_bucket is true, the script creates a bucket, the name of the bucket has to be unique; this is achieved internally by generating a random-id and then post-fixing it to the “aws-observability-” string.
            path_expression - This is required in case the above existing bucket is already configured to receive ALB access logs. If this is blank, Sumo Logic will store logs in the path expression: *elasticloadbalancing/AWSLogs/*/elasticloadbalancing/*/*
        EOT
  default = {
    source_name     = "Elb Logs (Region)"
    source_category = "aws/observability/alb/logs"
    description     = "This source is created using Sumo Logic terraform AWS Observability module to collect AWS Application LoadBalancer logs."
    bucket_details = {
      create_bucket        = true
      bucket_name          = "aws-observability-random-id"
      path_expression      = "*elasticloadbalancing/AWSLogs/<ACCOUNT-ID>/elasticloadbalancing/<REGION-NAME>/*"
      force_destroy_bucket = true
    }
    fields = {}
  }
  validation {
    condition     = can(regex("[a-z0-9-.]{3,63}$", var.elb_source_details.bucket_details.bucket_name))
    error_message = "3-63 characters; must contain only lowercase letters, numbers, hyphen or period. For more details - https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html."
  }
}

variable "classic_lb_source_details" {
  type = object({
    source_name     = string
    source_category = string
    description     = string
    bucket_details = object({
      create_bucket        = bool
      bucket_name          = string
      path_expression      = string
      force_destroy_bucket = bool
    })
    fields = map(string)
  })
  description = <<EOT
            Provide details for the Sumo Logic Classic Load Balancer source. If not provided, then defaults will be used.
            To enable collection of classic load balancer logs, set collect_classic_lb_logs to true and provide configuration information for the bucket.
            If create_bucket is false, provide a name of an existing S3 bucket where you would like to store loadbalancer logs. If this is empty, a new bucket will be created in the region.
            If create_bucket is true, the script creates a bucket, the name of the bucket has to be unique; this is achieved internally by generating a random-id and then post-fixing it to the “aws-observability-” string.
            path_expression - This is required in case the above existing bucket is already configured to receive Classic LB access logs. If this is blank, Sumo Logic will store logs in the path expression: *classicloadbalancing/AWSLogs/*/elasticloadbalancing/*/*
        EOT
  default = {
    source_name     = "Classic lb Logs (Region)"
    source_category = "aws/observability/clb/logs"
    description     = "This source is created using Sumo Logic terraform AWS Observability module to collect AWS Classic LoadBalancer logs."
    bucket_details = {
      create_bucket        = true
      bucket_name          = "aws-observability-random-id"
      path_expression      = "*classicloadbalancing/AWSLogs/<ACCOUNT-ID>/elasticloadbalancing/<REGION-NAME>/*"
      force_destroy_bucket = true
    }
    fields = {}
  }
  validation {
    condition     = can(regex("[a-z0-9-.]{3,63}$", var.classic_lb_source_details.bucket_details.bucket_name))
    error_message = "3-63 characters; must contain only lowercase letters, numbers, hyphen or period. For more details - https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html."
  }
}

variable "auto_enable_access_logs" {
  type        = string
  description = <<EOT
            Enable Application Load Balancer (ALB) Access logging.
            You have the following options:
            New - Automatically enables access logging for newly created ALB resources to collect logs for ALB resources. This does not affect ALB resources already collecting logs.
            Existing - Automatically enables access logging for existing ALB resources to collect logs for ALB resources.
            Both - Automatically enables access logging for new and existing ALB resources.
            None - Skips Automatic access Logging enable for ALB resources.
        EOT
  validation {
    condition = contains([
      "New",
      "Existing",
      "Both",
    "None", ], var.auto_enable_access_logs)
    error_message = "The value must be one of New, Existing, Both and None."
  }
  default = "Both"
}

variable "auto_enable_classic_lb_access_logs" {
  type        = string
  description = <<EOT
            Enable Classic Load Balancer (CLB) Access logging.
            You have the following options:
            New - Automatically enables access logging for newly created CLB resources to collect logs for CLB resources. This does not affect CLB resources already collecting logs.
            Existing - Automatically enables access logging for existing CLB resources to collect logs for CLB resources.
            Both - Automatically enables access logging for new and existing CLB resources.
            None - Skips Automatic access Logging enable for CLB resources.
        EOT
  validation {
    condition = contains([
      "New",
      "Existing",
      "Both",
    "None", ], var.auto_enable_classic_lb_access_logs)
    error_message = "The value must be one of New, Existing, Both and None."
  }
  default = "Both"
}

variable "collect_cloudwatch_metrics" {
  type        = string
  description = <<EOT
            Select the kind of CloudWatch Metrics Source to create
            You have the following options:
            "CloudWatch Metrics Source" - Creates Sumo Logic AWS CloudWatch Metrics Sources.
            "Kinesis Firehose Metrics Source" (Recommended) - Creates a Sumo Logic AWS Kinesis Firehose for Metrics Source. Note: This new source has cost and performance benefits over the CloudWatch Metrics Source and is therefore recommended.
            "None" - Skips the Installation of both the Sumo Logic Metric Sources
        EOT
  validation {
    condition = contains([
      "CloudWatch Metrics Source",
      "Kinesis Firehose Metrics Source",
    "None", ], var.collect_cloudwatch_metrics)
    error_message = "The value must be one of \"CloudWatch Metrics Source\", \"Kinesis Firehose Metrics Source\", and None."
  }
  default = "Kinesis Firehose Metrics Source"
}

variable "cloudwatch_metrics_source_details" {
  type = object({
    source_name         = string
    source_category     = string
    description         = string
    limit_to_namespaces = list(string)
    tag_filters = list(object({
      type      = string
      namespace = string
      tags      = list(string)
    }))
    fields              = map(string)
    bucket_details = object({
      create_bucket        = bool
      bucket_name          = string
      force_destroy_bucket = bool
    })
  })
  description = <<EOT
            Provide details for the Sumo Logic Cloudwatch Metrics source. If not provided, then defaults will be used.
            limit_to_namespaces - Enter a comma-delimited list of the namespaces which will be used for both AWS CloudWatch Metrics Source.
            See this list of AWS services that publish CloudWatch metrics: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/aws-services-cloudwatch-metrics.html
        EOT
  default = {
    source_name         = "CloudWatch Metrics (Region)"
    source_category     = "aws/observability/cloudwatch/metrics"
    description         = "This source is created using Sumo Logic terraform AWS Observability module to collect AWS Cloudwatch metrics."
    limit_to_namespaces = ["AWS/ApplicationELB", "AWS/ApiGateway", "AWS/DynamoDB", "AWS/Lambda", "AWS/RDS", "AWS/ECS", "AWS/ElastiCache", "AWS/ELB", "AWS/NetworkELB", "AWS/SQS", "AWS/SNS", "AWS/EC2"]
    tag_filters         = []
    fields              = {}
    bucket_details = {
      create_bucket        = true
      bucket_name          = "aws-observability-random-id"
      force_destroy_bucket = true
    }
  }
}

variable "collect_cloudwatch_logs" {
  type        = string
  description = <<EOT
            Select the kind of Sumo Logic CloudWatch Logs Sources to create
            You have the following options:
            "Lambda Log Forwarder" - Creates a Sumo Logic CloudWatch Log Source that collects CloudWatch logs via a Lambda function.
            "Kinesis Firehose Log Source" - Creates a Sumo Logic Kinesis Firehose Log Source to collect CloudWatch logs.
            "None" - Skips installation of both sources.
        EOT
  validation {
    condition = contains([
      "Lambda Log Forwarder",
      "Kinesis Firehose Log Source",
    "None", ], var.collect_cloudwatch_logs)
    error_message = "The value must be one of \"Lambda Log Forwarder\", \"Kinesis Firehose Log Source\", and None."
  }
  default = "Kinesis Firehose Log Source"
}

variable "cloudwatch_logs_source_details" {
  type = object({
    source_name     = string
    source_category = string
    description     = string
    fields          = map(string)
    bucket_details = object({
      create_bucket        = bool
      bucket_name          = string
      force_destroy_bucket = bool
    })
    lambda_log_forwarder_config = object({
      email_id               = string
      workers                = number
      log_format             = string
      include_log_group_info = bool
      log_stream_prefix      = list(string)
    })
  })
  description = <<EOT
            Provide details for the Sumo Logic Cloudwatch Logs source. If not provided, then defaults will be used.

            Use bucket_details section with Kinesis Firehose Log Source:
            If create_bucket is false, provide a name of an existing S3 bucket where you would like to store cloudwatch logs. If this is empty, a new bucket will be created.
            If create_bucket is true, the script creates a bucket, the name of the bucket has to be unique; this is achieved internally by generating a random-id and then post-fixing it to the “aws-observability-” string.

            Use lambda_log_forwarder_config section with Lambda Log Forwarder:
            Provide your email_id to receive alerts. You will receive a confirmation email after the deployment is complete. Follow the instructions in this email to validate the address.
            IncludeLogGroupInfo:  Set to true to include loggroup/logstream values in logs. For AWS Lambda logs, IncludeLogGroupInfo must be set to true
            logformat: For Lambda, the value should be set to “Others”.
            log_stream_prefix: Enter a comma-separated list of logStream name prefixes to filter by logStream. Please note this is separate from a logGroup. This is used to only send certain logStreams within a CloudWatch logGroup(s). LogGroup(s) still need to be subscribed to the created Lambda function.
            workers: Number of lambda function invocations for Cloudwatch logs source Dead Letter Queue processing.
        EOT
  default = {
    source_name     = "CloudWatch Logs (Region)"
    source_category = "aws/observability/cloudwatch/logs"
    description     = "This source is created using Sumo Logic terraform AWS Observability module to collect AWS Cloudwatch Logs."
    fields          = {}
    bucket_details = {
      create_bucket        = true
      bucket_name          = "aws-observability-random-id"
      force_destroy_bucket = true
    }
    lambda_log_forwarder_config = {
      email_id               = "test@gmail.com"
      workers                = 4
      log_format             = "Others"
      include_log_group_info = true
      log_stream_prefix      = []
    }
  }
  validation {
    condition     = can(regex("\\w+@\\w+\\.\\w+", var.cloudwatch_logs_source_details.lambda_log_forwarder_config.email_id))
    error_message = "Email address must be valid."
  }
  validation {
    condition     = contains(["VPC-RAW", "VPC-JSON", "Others"], var.cloudwatch_logs_source_details.lambda_log_forwarder_config.log_format)
    error_message = "Log format service must be one of VPC-RAW, VPC-JSON, or Others."
  }
}

variable "auto_enable_logs_subscription" {
  type        = string
  description = <<EOT
            Subscribe log groups to Sumo Logic Lambda Forwarder.
            You have the following options:
            New - Automatically subscribes new log groups to send logs to Sumo Logic.
            Existing - Automatically subscribes existing log groups to send logs to Sumo Logic.
            Both - Automatically subscribes new and existing log groups.
            None - Skips Automatic subscription.
        EOT
  validation {
    condition = contains([
      "New",
      "Existing",
      "Both",
    "None", ], var.auto_enable_logs_subscription)
    error_message = "The value must be one of New, Existing, Both and None."
  }
  default = "Both"
}

variable "auto_enable_logs_subscription_options" {
  type = object({
    filter = string
    tags_filter = string
  })

  description = <<EOT
		filter - Enter regex for matching logGroups. Regex will check for the name.
        tags_filter - Enter comma separated key value pairs for filtering logGroups using tags. Ex KeyName1=string,KeyName2=string. This is optional leave it blank if tag based filtering is not needed.
        Visit https://help.sumologic.com/docs/send-data/collect-from-other-data-sources/autosubscribe-arn-destination/#configuringparameters
	EOT

  default = {
    filter = "apigateway|lambda|rds"
    tags_filter = null
  }
}

variable "collect_root_cause_data" {
  type        = string
  description = <<EOT
            Select the Sumo Logic Root Cause Explorer Source.
            You have the following options:
            Inventory Source - Creates a Sumo Logic Inventory Source used by Root Cause Explorer.
            Xray Source - Creates a Sumo Logic AWS X-Ray Source that collects X-Ray Trace Metrics from your AWS account.
            Both - Install both Inventory and Xray sources.
            None - Skips installation of both sources.
        EOT
  validation {
    condition = contains([
      "Inventory Source",
      "Xray Source",
      "Both",
    "None", ], var.collect_root_cause_data)
    error_message = "The value must be one of \"Inventory Source\", \"Xray Source\", \"Both\" and None."
  }
  default = "Both"
}

variable "inventory_source_details" {
  type = object({
    source_name         = string
    source_category     = string
    description         = string
    limit_to_namespaces = list(string)
    fields              = map(string)
  })
  description = "Provide details for the Sumo Logic AWS Inventory source. If not provided, then defaults will be used."
  default = {
    source_name         = "AWS Inventory (Region)"
    source_category     = "aws/observability/inventory"
    description         = "This source is created using Sumo Logic terraform AWS Observability module to collect AWS inventory metadata."
    limit_to_namespaces = ["AWS/ApplicationELB", "AWS/ApiGateway", "AWS/DynamoDB", "AWS/Lambda", "AWS/RDS", "AWS/ECS", "AWS/ElastiCache", "AWS/ELB", "AWS/NetworkELB", "AWS/SQS", "AWS/SNS", "AWS/AutoScaling", "AWS/EC2"]
    fields              = {}
  }
  validation {
    # regex check that each element of the input namespaces is one of the accepted values, contains check if any of the can function returns was false, return false from logical if any of the returns were false
    condition     = contains([for namespace in var.inventory_source_details.limit_to_namespaces : can(regex("AWS/(?:ApplicationELB|ApiGateway|DynamoDB|Lambda|RDS|ECS|ElastiCache|ELB|NetworkELB|SQS|SNS|AutoScaling|EC2)", namespace))], false) != true
    error_message = "Namespaces should be from provided default list \"AWS/ApplicationELB\", \"AWS/ApiGateway\", \"AWS/DynamoDB\", \"AWS/Lambda\", \"AWS/RDS\", \"AWS/ECS\", \"AWS/ElastiCache\", \"AWS/ELB\", \"AWS/NetworkELB\", \"AWS/SQS\", \"AWS/SNS\", \"AWS/AutoScaling\", \"AWS/EC2\"."
  }
}

variable "xray_source_details" {
  type = object({
    source_name     = string
    source_category = string
    description     = string
    fields          = map(string)
  })
  description = "Provide details for the Sumo Logic AWS XRAY source. If not provided, then defaults will be used."
  default = {
    source_name     = "AWS Xray (Region)"
    source_category = "aws/observability/xray"
    description     = "This source is created using Sumo Logic terraform AWS Observability module to collect AWS Xray metrics."
    fields          = {}
  }
}