# sumologic
variable "sumologic_environment" {
  type        = string
  description = "SumoLogic environment abbreviation."

  validation {
    condition     = contains(["au", "ca", "de", "eu", "jp", "us1", "us2", "in", "fed"], var.sumologic_environment)
    error_message = "The value must be one of au, ca, de, eu, jp, us1, us2, in, or fed."
  }
}

variable "sumologic_access_id" {
  type        = string
  description = "SumoLogic access id for API invocations."

  validation {
    condition     = can(regex("\\w+", var.sumologic_access_id))
    error_message = "The SumoLogic access ID must contain valid characters."
  }
}

variable "sumologic_access_key" {
  type        = string
  description = "SumoLogic access key for API invocations."

  validation {
    condition     = can(regex("\\w+", var.sumologic_access_key))
    error_message = "The SumoLogic access key must contain valid characters."
  }
}

variable "sumologic_organization_id" {
  type        = string
  description = "Appears on the Account Overview page that displays information about your Sumo Logic organization. Used for IAM Role in Sumo Logic AWS Sources."

  validation {
    condition     = can(regex("\\w+", var.sumologic_organization_id))
    error_message = "The organization ID must contain valid characters."
  }
}

variable "account_alias" {
  type        = string
  description = "Provide an Alias for the AWS account for identification in Sumo Logic Explorer View, metrics, and logs. Please do not include special characters."

  validation {
    condition     = can(regex("[a-z0-9]+", var.account_alias)) && length(var.account_alias) <= 30
    error_message = "Account Alias must only contain lowercase letters and numbers, and a length less than or equal to 30 characters."
  }
}

# collector
variable "collector_name" {
  type        = string
  default     = "aws-observability"
  description = "Name of the SumoLogic collector."
}

variable "scan_interval" {
  type        = number
  default     = 300000
  description = "The scan interval to fetch metrics into Sumo Logic."
}

# metadata source
variable "manage_metadata_source" {
  type        = bool
  default     = false
  description = "Whether to manage the SumoLogic MetaData Source. A common metadata source will be managed with the region selected. Do not enable if you preconfigured a MetaData Source."
}

variable "metadata_source_name" {
  type        = string
  default     = "metadata"
  description = "Metadata source name to override the default. If unspecified, the default name will be used."
}

variable "metadata_source_category" {
  type        = string
  default     = "aws/observability/ec2/metadata"
  description = "EC2 metadata source category."
}

# cloudwatch metrics source
variable "manage_cloudwatch_metrics_source" {
  type        = string
  default     = false
  description = "Whether to manage a Sumo Logic CloudWatch Metrics Source which collects Metrics for multiple Namespaces from the region selected. Do not enable if you preconfigured a CloudWatch Metrics Source to collect ALB metrics."
}

variable "cloudwatch_metrics_source_name" {
  type        = string
  default     = "cloudwatch-metrics"
  description = "Cloudwatch metrics source name to override the default. If unspecified, the default name will be used."
}

variable "cloudwatch_metrics_source_category" {
  type        = string
  default     = "aws/observability/cloudwatch/metrics"
  description = "Cloudwatch metrics source category."
}

variable "cloudwatch_metrics_namespaces" {
  type        = list(string)
  default     = ["AWS/ApplicationELB", "AWS/ApiGateway", "AWS/DynamoDB", "AWS/Lambda", "AWS/RDS", "AWS/ECS", "AWS/ElastiCache", "AWS/ELB", "AWS/NetworkELB"]
  description = "List of the Cloudwatch metrics namespaces."

  validation {
    # regex check that each element of the input namespaces is one of the accepted values, contains check if any of the can function returns was false, return false from logical if any of the returns were false
    condition     = contains([for namespace in var.cloudwatch_metrics_namespaces : can(regex("AWS/(?:ApplicationELB|ApiGateway|DynamoDB|Lambda|RDS|ECS|ElastiCache|ELB|NetworkELB)", namespace))], false) != true
    error_message = "Namespaces should be from provided default list."
  }
}

# alb logs source
variable "manage_alb_logs_source" {
  type        = bool
  default     = false
  description = "Whether to manage the Sumo Logic ALB Log Source with provided bucket Name."
}

variable "manage_alb_s3_bucket" {
  type        = bool
  default     = false
  description = "Whether to manage the S3 bucket for ALB. Do not enable if you preconfigured a S3 bucket for this purpose."
}

variable "alb_s3_bucket" {
  type        = string
  default     = ""
  description = "The preconfigured S3 bucket for ALB logs if the bucket is not managed in this module config."
}

variable "alb_s3_bucket_path_expression" {
  type        = string
  description = "Path expression to match one or more S3 objects; e.g. 'ABC*.log' or 'ABC.log'."
  default     = "*"
}

variable "alb_logs_source_name" {
  type        = string
  description = "Name for the ALB logs source."
  default     = "alb-logs"
}

variable "alb_logs_source_category" {
  type        = string
  default     = "aws/observability/alb/logs"
  description = "ALB logs source category."
}

# cloudtrail logs source
variable "manage_cloudtrail_logs_source" {
  type        = bool
  description = "Whether to manage the Sumo Logic Cloud Trail Log Source with provided bucket Name."
  default     = false
}

variable "manage_cloudtrail_bucket" {
  type        = bool
  description = "Whether to manage the Cloudtrail S3 bucket. Do not enable if you preconfigured a S3 bucket for Cloudtrail."
  default     = false
}

variable "cloudtrail_logs_s3_bucket" {
  type        = string
  description = "The preconfigured S3 bucket for Cloudtrail logs if the bucket is not managed in this module config."
  default     = ""
}

variable "cloudtrail_s3_bucket_path_expression" {
  type        = string
  description = "Path expression to match one or more S3 objects; e.g. 'ABC*.log' or 'ABC.log'."
  default     = "*"
}

variable "cloudtrail_logs_source_name" {
  type        = string
  description = "Name for the Cloudtrail logs source."
  default     = "cloudtrail-logs"
}

variable "cloudtrail_logs_source_category" {
  type        = string
  default     = "aws/observability/cloudtrail/logs"
  description = "Cloudtrail logs source category."
}

# cloudwatch logs source
variable "manage_cloudwatch_logs_source" {
  type        = bool
  description = "Whether to manage the Sumo Logic Cloud Watch Log Source."
  default     = false
}

variable "cloudwatch_logs_source_name" {
  type        = string
  description = "Name for the Cloudwatch logs source."
  default     = "cloudwatch-logs"
}

variable "cloudwatch_logs_source_category" {
  type        = string
  default     = "aws/observability/cloudwatch/logs"
  description = "Cloudwatch logs source category."
}

# aws inventory source
variable "manage_aws_inventory_source" {
  type        = bool
  default     = false
  description = "Whether to manage the Sumo Logic AWS Inventory Source"
}

variable "aws_inventory_source_name" {
  type        = string
  default     = "inventory-aws"
  description = "The Sumo Logic AWS Inventory Source name"
}

variable "aws_inventory_source_category" {
  type        = string
  default     = "aws/observability/inventory"
  description = "The source category for the AWS inventory source"
}

# aws xray source
variable "manage_aws_xray_source" {
  type        = bool
  default     = false
  description = "Whether to manage the Sumo Logic AWS XRay Source"
}

variable "aws_xray_source_name" {
  type        = string
  default     = "xray-aws"
  description = "The Sumo Logic AWS XRay Source name"
}

variable "aws_xray_source_category" {
  type        = string
  default     = "aws/observability/xray"
  description = "The source category for the AWS xray source"
}

# apps
variable "managed_apps" {
  type = map(object({
    app_version    = string
    config_version = string
    json           = string
  }))
  default     = {}
  description = "The list of applications to manage within the Sumo Logic AWS Observability Solution"
}

variable "app_bucket" {
  type        = string
  default     = "sumologic-appdev-aws-sam-apps"
  description = "S3 bucket name storing app JSON files to configure installations"
}

# sns topic
variable "email_id" {
  type        = string
  default     = "test@gmail.com"
  description = "Email for receiving alerts. A confirmation email is sent after the deployment is complete. It can be confirmed to subscribe for alerts."

  validation {
    condition     = can(regex("\\w+@\\w+\\.\\w+", var.email_id))
    error_message = "Email address must be valid."
  }
}

# lambda
variable "workers" {
  type        = number
  default     = 4
  description = "Number of lambda function invocations for Cloudwatch logs source Dead Letter Queue processing."
}

variable "log_format" {
  type        = string
  default     = "Others"
  description = "Service for Cloudwatch logs source."

  validation {
    condition     = contains(["VPC-RAW", "VPC-JSON", "Others"], var.log_format)
    error_message = "Log format service must be be one of VPC-RAW, VPC-JSON, or Others."
  }
}

variable "include_log_group_info" {
  type        = bool
  default     = true
  description = "Enable loggroup/logstream values in logs."
}

variable "log_stream_prefix" {
  type        = list(string)
  default     = []
  description = "LogStream name prefixes to filter by logStream. Please note this is separate from a logGroup. This is used only to send certain logStreams within a Cloudwatch logGroup(s). LogGroups still need to be subscribed to the created Lambda function regardless of this input value."
}

# miscellaneous
variable "templates_bucket" {
  type        = string
  description = "Prefix of the S3 bucket containing nested CFTs and Lambda code."
  default     = "appdevzipfiles"
}

variable "target_bucket_force_destroy" {
  type        = bool
  description = "Whether to force the deletion of the common target S3 bucket (will delete even if not empty)."
  default     = false
}
