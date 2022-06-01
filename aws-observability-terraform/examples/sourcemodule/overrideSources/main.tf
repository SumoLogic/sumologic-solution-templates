# The below module is used to install AWS and Sumo Logic resources to collect logs and metrics from AWS into Sumo Logic.
# NOTE - For multi account and multi region deployment, copy the module and provide different aws provider for region and account.
#
module "collection-module" {
  source = "../../../source-module"

  aws_account_alias         = var.aws_account_alias
  sumologic_organization_id = var.sumologic_organization_id
  access_id                 = var.sumologic_access_id
  access_key                = var.sumologic_access_key
  environment               = var.sumologic_environment

  sumologic_existing_collector_details = {
    create_collector = var.create_collector
    collector_id = var.collector_id
  }

  # ALB logs
  # elb_source_url = "https://api.sumologic.com/api/v1/collectors/185689129/sources/916197188"
  collect_elb_logs = var.collect_elb
  elb_source_details = {
    source_name     = "Elb Logs us-east-1"
    source_category = "aws/observability/alb/logs"
    description     = "This source is created using the Sumo Logic terraform AWS Observability module to collect AWS ELB logs."
    bucket_details = {
        create_bucket        = var.create_s3_bucket
        bucket_name          = var.s3_name
        path_expression      = "*AWSLogs/*/elasticloadbalancing/*/*"
        force_destroy_bucket = false
    }
    fields = {}
  }

  # CLB logs
  # classic_lb_log_source_url = "https://api.sumologic.com/api/v1/collectors/185689129/sources/916197188"
  collect_classic_lb_logs = var.collect_classic_lb
  classic_lb_source_details = {
  source_name     = "Classic lb Logs us-east-1"
  source_category = "aws/observability/clb/logs"
  description     = "This source is created using Sumo Logic terraform AWS Observability module to collect AWS Classic LoadBalancer logs."
  bucket_details = {
      create_bucket        = var.create_s3_bucket
      bucket_name          = var.s3_name
      path_expression      = "*AWSLogs/*/elasticloadbalancing/*/*"
      force_destroy_bucket = false
  }
  fields = {}
}

  # CW logs 
  # logs_source_url = "https://api.sumologic.com/api/v1/collectors/185689129/sources/915277706"
  collect_cloudwatch_logs = var.collect_logs_cloudwatch
  cloudwatch_logs_source_details = {
  "bucket_details": {
    "bucket_name": var.s3_name,
    "create_bucket": var.create_s3_bucket,
    "force_destroy_bucket": true
  },
  "lambda_log_forwarder_config": {
   "email_id": "abc@example.com",
   "include_log_group_info": true,
   "log_format": "Others",
   "log_stream_prefix": [],
   "workers": 4
 },
  "description": "This source is created using Sumo Logic terraform AWS Observability module to collect AWS Cloudwatch Logs.",
  "fields": {},
  "source_category": "aws/observability/cloudwatch/logs",
  "source_name": "CloudWatch Logs (Region)"
}
  
  # Enable Collection of Cloudtrail logs
  collect_cloudtrail_logs   = var.collect_cloudtrail
  cloudtrail_source_details = {
  source_name     = "CloudTrail Logs us-east-1"
  source_category = "aws/observability/cloudtrail/logs"
  description     = "This source is created using Sumo Logic terraform AWS Observability module to collect AWS cloudtrail logs."
  bucket_details = {
      create_bucket        = var.create_s3_bucket
      bucket_name          = var.s3_name
      path_expression      = "AWSLogs/*/CloudTrail/*/*"
      force_destroy_bucket = false
  }
  fields = {}
}

  # Collect CW metrics
  collect_cloudwatch_metrics = var.collect_metric_cloudwatch
  cloudwatch_metrics_source_details = {
  "bucket_details": {
    "bucket_name": var.s3_name,
    "create_bucket": var.create_s3_bucket,
    "force_destroy_bucket": true
  },
  "description": "This source is created using Sumo Logic terraform AWS Observability module to collect AWS Cloudwatch metrics.",
  "fields": {},
  "limit_to_namespaces": [
    "AWS/ApiGateway",
    "AWS/ApplicationELB",
    "AWS/AppStream",
    "AWS/CloudFront",
    "AWS/DMS",
    "AWS/DX",
    "AWS/DynamoDB",
    "AWS/EBS",
    "AWS/EC2",
    "AWS/EC2Spot",
    "AWS/EFS",
    "AWS/ElastiCache",
    "AWS/ElasticBeanstalk",
    "AWS/ElasticMapReduce",
    "AWS/ELB",
    "AWS/ECS",
    "AWS/Firehose",
    "AWS/Inspector",
    "AWS/Kinesis",
    "AWS/KinesisAnalytics",
    "AWS/KinesisVideo",
    "AWS/KMS",
    "AWS/Lambda",
    "AWS/Logs",
    "AWS/ML",
    "AWS/NATGateway",
    "AWS/NetworkELB",
    "AWS/OpsWorks",
    "AWS/RDS",
    "AWS/Redshift",
    "AWS/Route53",
    "AWS/S3",
    "AWS/SageMaker",
    "AWS/SQS",
    "AWS/StorageGateway",
    "AWS/VPN",
    "AWS/WorkSpaces"
    ],
  "source_category": "aws/observability/cloudwatch/metrics/us-east-1",
  "source_name": "CloudWatch Metrics us-east-1"
}

  # RCE
  collect_root_cause_data = var.collect_rce
}