variable "sumologic_environment" {
  type        = string
  description = "Enter au, ca, de, eu, fed, jp, kr, us1 or us2. For more information on Sumo Logic deployments visit https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security"

  validation {
    condition = contains([
      "au",
      "ca",
      "de",
      "eu",
      "fed",
      "jp",
      "kr",
      "us1",
      "us2"], var.sumologic_environment)
    error_message = "The value must be one of au, ca, de, eu, fed, jp, kr, us1 or us2."
  }
}

variable "sumologic_access_id" {
  type        = string
  description = "Sumo Logic Access ID. Visit https://help.sumologic.com/Manage/Security/Access-Keys#Create_an_access_key"

  validation {
    condition     = can(regex("\\w+", var.sumologic_access_id))
    error_message = "The SumoLogic access ID must contain valid characters."
  }
}

variable "sumologic_access_key" {
  type        = string
  description = "Sumo Logic Access Key. Visit https://help.sumologic.com/Manage/Security/Access-Keys#Create_an_access_key"
  #sensitive = true

  validation {
    condition     = can(regex("\\w+", var.sumologic_access_key))
    error_message = "The SumoLogic access key must contain valid characters."
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

variable "aws_account_alias" {
  type        = string
  description = <<EOT
            Provide the Name/Alias for the AWS environment from which you are collecting data. This name will appear in the Sumo Logic Explorer View, metrics, and logs.
            If you are going to deploy the solution in multiple AWS accounts then this value has to be overidden at main.tf file.
            Do not include special characters in the alias.
        EOT
  validation {
    condition     = can(regex("[a-z0-9]*", var.aws_account_alias))
    error_message = "Alias must only contain lowercase letters, number and length less than or equal to 30 characters."
  }
}

variable "sumologic_folder_installation_location" {
  type        = string
  description = "Indicates where to install the app folder. Enter \"Personal Folder\" for installing in \"Personal\" folder and \"Admin Recommended Folder\" for installing in \"Admin Recommended\" folder."
  validation {
    condition = contains([
      "Personal Folder",
      "Admin Recommended Folder"], var.sumologic_folder_installation_location)
    error_message = "The value must be one of \"Personal Folder\" or \"Admin Recommended Folder\"."
  }
  default     = "Personal Folder"

}

variable "sumologic_folder_share_with_org" {
  type        = bool
  description = "Indicates if AWS Observability folder should be shared (view access) with entire organization. true to enable; false to disable."
  default     = true

}

variable "sumo_api_endpoint" {
  type = string
  validation {
    condition = contains([
      "https://api.au.sumologic.com/api/",
    "https://api.ca.sumologic.com/api/", "https://api.de.sumologic.com/api/", "https://api.eu.sumologic.com/api/", "https://api.fed.sumologic.com/api/", "https://api.in.sumologic.com/api/", "https://api.jp.sumologic.com/api/", "https://api.sumologic.com/api/", "https://api.us2.sumologic.com/api/", "https://api.kr.sumologic.com/api/"], var.sumo_api_endpoint)
    error_message = "Argument \"sumo_api_endpoint\" must be one of the values specified at https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security."
  }
}

variable "apps_folder" {
  type        = string
  description = <<EOT
            Provide a folder name where all the apps will be installed under the Personal folder of the user whose access keys you have entered.
            Default value will be: AWS Observability Apps
        EOT
  default     = "AWS Observability Apps"
}

variable "monitors_folder" {
  type        = string
  description = <<EOT
            Provide a folder name where all the monitors will be installed under Monitor Folder.
            Default value will be: AWS Observability Monitors
        EOT
  default     = "AWS Observability Monitors"
}

variable "alb_monitors" {
  type        = bool
  description = "Indicates if the ALB Apps monitors should be enabled. true to disable; false to enable."
  default     = true
}

variable "ec2metrics_monitors" {
  type        = bool
  description = "Indicates if EC2 Metrics Apps monitors should be enabled. true to disable; false to enable."
  default     = true
}

variable "ecs_monitors" {
  type        = bool
  description = "Indicates if ECS Apps monitors should be enabled. true to disable; false to enable."
  default     = true
}

variable "elasticache_monitors" {
  type        = bool
  description = "Indicates if Elasticache Apps monitors should be enabled. true to disable; false to enable."
  default     = true
}

variable "collect_elb" {
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

variable "collect_classic_lb" {
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

variable "collect_logs_cloudwatch" {
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
    "None", ], var.collect_logs_cloudwatch)
    error_message = "The value must be one of \"Lambda Log Forwarder\", \"Kinesis Firehose Log Source\", and None."
  }
  default = "Kinesis Firehose Log Source"
}

variable "collect_cloudtrail" {
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

variable "collect_metric_cloudwatch" {
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
    "None", ], var.collect_metric_cloudwatch)
    error_message = "The value must be one of \"CloudWatch Metrics Source\", \"Kinesis Firehose Metrics Source\", and None."
  }
  default = "Kinesis Firehose Metrics Source"
}

variable "elb_details" {
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
    condition     = can(regex("[a-z0-9-.]{3,63}$", var.elb_details.bucket_details.bucket_name))
    error_message = "3-63 characters; must contain only lowercase letters, numbers, hyphen or period. For more details - https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html."
  }
}

variable "classic_lb_details" {
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
    condition     = can(regex("[a-z0-9-.]{3,63}$", var.classic_lb_details.bucket_details.bucket_name))
    error_message = "3-63 characters; must contain only lowercase letters, numbers, hyphen or period. For more details - https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html."
  }
}
variable "create_collector" {
  type        = bool
  description = <<EOT
            Create a Sumo Logic Collector.
            You have the following options:
			true - If you want to create collector.
			false - If you already have a collector.
		EOT
  default     = true
}
variable "collector_id" {
  type        = string
  description = "Required if you already have collector."
  default = ""
}
variable "create_s3_bucket" {
  type        = bool
  description = <<EOT
            Create a AWS S3 bucket.
            You have the following options:
			true - If you want to create S3 bucket.
			false - If you already have a S3 bucket.
		EOT
  default     = true
}
variable "s3_name" {
  type        = string
  description = "Required if you already have a S3 bucket."
  default = ""
}
variable "executeTest1" {
  type        = bool
  description = "True - If you want to execute this TestCase"
  default     = false
}
variable "executeTest2" {
  type        = bool
  description = "True - If you want to execute this TestCase"
  default     = false
}
variable "executeTest3" {
  type        = bool
  description = "True - If you want to execute this TestCase"
  default     = false
}
variable "executeTest4" {
  type        = bool
  description = "True - If you want to execute this TestCase"
  default     = false
}