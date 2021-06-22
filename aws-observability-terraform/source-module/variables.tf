variable "aws_account_alias" {
  type        = string
  description = "Provide an Alias for AWS account for identification in Sumo Logic Explorer View, metrics and logs. Please do not include special characters."
  validation {
    condition     = can(regex("[a-z0-9]+", var.aws_account_alias))
    error_message = "Alias must only contain lowercase letters, number and length less than or equal to 30 characters."
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

variable "iam_role_arn" {
  type        = string
  description = <<EOT
			Provide an existing AWS IAM role arn value which provides access to AWS S3 Buckets, AWS CloudWatch Metrics API and Sumo Logic Inventory data.
			If kept empty, a new IAM role will be created with the required permissions.
			For more details on permission, check /source-modules/template/sumologic_aws_permissions.tmpl file.
		EOT
  default     = ""
}

variable "sumologic_existing_collector_id" {
  type        = string
  description = <<EOT
			Provide an existing Sumo Logic Collector ID. For more details, visit https://help.sumologic.com/03Send-Data/Sources/03Use-JSON-to-Configure-Sources/Local-Configuration-File-Management/View-or-Download-Source-JSON-Configuration
			If provided, all the provided sources will be created within the collector.
			If kept empty, a new Collector will be created and all provided sources will be created within that collector.
		EOT
  default     = ""
}

variable "sumologic_collector_details" {
  type = object({
    collector_name = string
    description    = string
    fields         = map(string)
  })
  description = <<EOT
			Provide details for the Sumo Logic collector. If not provided, then defaults will be used.
			Collector will be created if any new source will be created and \"sumologic_existing_collector_id\" is empty.
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
			Provide \"true\" if you would like to ingest cloudtrail logs into Sumo Logic.
			Please provide \"cloudtrail_source_details\" if would like to ingest cloudtrail logs.
			Provide \"false\" if you are already ingesting logs into Sumo Logic.
		EOT
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
  description = "Provide details for the Sumo Logic CloudTrail source. If not provided, then defaults will be used."
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
			Provide \"true\" if you would like to ingest Load Balancer logs into Sumo Logic.
			Please provide \"elb_source_details\" if would like to ingest load balancer logs.
			Provide \"false\" if you are already ingesting logs into Sumo Logic.
		EOT
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
  description = "Provide details for the Sumo Logic Elb source. If not provided, then defaults will be used."
  default = {
    source_name     = "Elb Logs (Region)"
    source_category = "aws/observability/alb/logs"
    description     = "This source is created using Sumo Logic terraform AWS Observability module to collect AWS ELB logs."
    bucket_details = {
      create_bucket        = true
      bucket_name          = "aws-observability-random-id"
      path_expression      = "*AWSLogs/<ACCOUNT-ID>/elasticloadbalancing/<REGION-NAME>/*"
      force_destroy_bucket = true
    }
    fields = {}
  }
  validation {
    condition     = can(regex("[a-z0-9-.]{3,63}$", var.elb_source_details.bucket_details.bucket_name))
    error_message = "3-63 characters; must contain only lowercase letters, numbers, hyphen or period. For more details - https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html."
  }
}

variable "auto_enable_access_logs" {
  type        = string
  description = <<EOT
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

variable "collect_cloudwatch_metrics" {
  type = string
  description = ""
    validation {
    condition = contains([
      "CloudWatch Metrics Source",
      "Kinesis Firehose Metrics Source",
    "None", ], var.collect_cloudwatch_metrics)
    error_message = "The value must be one of \"CloudWatch Metrics Source\", \"Kinesis Firehose Metrics Source\", and None."
  }
}

variable "cloudwatch_metrics_source_details" {
  type = object({
    source_name         = string
    source_category     = string
    description         = string
    limit_to_namespaces = list(string)
    fields              = map(string)
    bucket_details = object({
      create_bucket        = bool
      bucket_name          = string
      force_destroy_bucket = bool
    })
  })
  description = "Provide details for the Sumo Logic Cloudwatch Metrics source. If not provided, then defaults will be used."
  default = {
    source_name         = "CloudWatch Metrics (Region)"
    source_category     = "aws/observability/cloudwatch/metrics"
    description         = "This source is created using Sumo Logic terraform AWS Observability module to collect AWS Cloudwatch metrics."
    limit_to_namespaces = ["AWS/ApplicationELB", "AWS/ApiGateway", "AWS/DynamoDB", "AWS/Lambda", "AWS/RDS", "AWS/ECS", "AWS/ElastiCache", "AWS/ELB", "AWS/NetworkELB"]
    fields              = {}
    bucket_details = {
      create_bucket        = true
      bucket_name          = "aws-observability-random-id"
      force_destroy_bucket = true
    }
  }
  validation {
    # regex check that each element of the input namespaces is one of the accepted values, contains check if any of the can function returns was false, return false from logical if any of the returns were false
    condition     = contains([for namespace in var.cloudwatch_metrics_source_details.limit_to_namespaces : can(regex("AWS/(?:ApplicationELB|ApiGateway|DynamoDB|Lambda|RDS|ECS|ElastiCache|ELB|NetworkELB)", namespace))], false) != true
    error_message = "Namespaces should be from provided default list \"AWS/ApplicationELB\", \"AWS/ApiGateway\", \"AWS/DynamoDB\", \"AWS/Lambda\", \"AWS/RDS\", \"AWS/ECS\", \"AWS/ElastiCache\", \"AWS/ELB\", \"AWS/NetworkELB\"."
  }
}