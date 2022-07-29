locals {
  aws_account_id = data.aws_caller_identity.current.account_id

  aws_region = data.aws_region.current.id

  sumo_account_id = "926226587429"

  # CloudTrail Source updated Details
  create_cloudtrail_source = var.collect_cloudtrail_logs && var.cloudtrail_source_url == ""
  update_cloudtrail_source = var.collect_cloudtrail_logs ? (var.cloudtrail_source_url == "" ? false : true) : false
  cloudtrail_source_name = var.cloudtrail_source_details.source_name == "CloudTrail Logs (Region)" ? "CloudTrail Logs ${local.aws_region}" : var.cloudtrail_source_details.source_name
  cloudtrail_path_exp    = var.cloudtrail_source_details.bucket_details.create_bucket ? "AWSLogs/${local.aws_account_id}/CloudTrail/${local.aws_region}/*" : var.cloudtrail_source_details.bucket_details.path_expression
  cloudtrail_fields      = merge(var.cloudtrail_source_details.fields, { account = var.aws_account_alias })

  # ALB Source updated Details
  create_elb_source = var.collect_elb_logs && var.elb_log_source_url == ""
  update_elb_source = var.collect_elb_logs ? (var.elb_log_source_url == "" ? false : true) : false
  elb_source_name = var.elb_source_details.source_name == "Elb Logs (Region)" ? "Elb Logs ${local.aws_region}" : var.elb_source_details.source_name
  elb_path_exp    = var.elb_source_details.bucket_details.create_bucket ? "*elasticloadbalancing/AWSLogs/${local.aws_account_id}/elasticloadbalancing/${local.aws_region}/*.log.gz" : "*AWSLogs/${local.aws_account_id}/elasticloadbalancing/${local.aws_region}/*.log.gz"
  elb_fields      = merge(var.elb_source_details.fields, { account = var.aws_account_alias, region = local.aws_region, accountid = local.aws_account_id })

  # Classic ELB Source updated Details
  create_classic_lb_source = var.collect_classic_lb_logs && var.classic_lb_log_source_url == ""
  update_classic_lb_source = var.collect_classic_lb_logs ? (var.classic_lb_log_source_url == "" ? false : true) : false
  classic_lb_source_name = var.classic_lb_source_details.source_name == "Classic lb Logs (Region)" ? "Classic lb Logs ${local.aws_region}" : var.classic_lb_source_details.source_name
  classic_lb_path_exp    = var.classic_lb_source_details.bucket_details.create_bucket ? "*classicloadbalancing/AWSLogs/${local.aws_account_id}/elasticloadbalancing/${local.aws_region}/*.log" : "${var.classic_lb_source_details.bucket_details.path_expression}/AWSLogs/${local.aws_account_id}/elasticloadbalancing/${local.aws_region}/*.log"
  auto_classic_lb_path_exp = var.classic_lb_source_details.bucket_details.path_expression == "*classicloadbalancing/AWSLogs/<ACCOUNT-ID>/elasticloadbalancing/<REGION-NAME>/*" ? "classicloadbalancing" : var.classic_lb_source_details.bucket_details.path_expression
  classic_lb_fields      = merge(var.classic_lb_source_details.fields, { account = var.aws_account_alias, region = local.aws_region, accountid = local.aws_account_id })

  # CloudWatch metrics source updated details
  create_cw_metrics_source = var.collect_cloudwatch_metrics == "CloudWatch Metrics Source" && var.cloudwatch_metrics_source_url == ""
  create_kf_metrics_source = var.collect_cloudwatch_metrics == "Kinesis Firehose Metrics Source" && var.cloudwatch_metrics_source_url == ""
  use_cw_metrics_source = var.collect_cloudwatch_metrics == "CloudWatch Metrics Source"
  use_kf_metrics_source = var.collect_cloudwatch_metrics == "Kinesis Firehose Metrics Source"
  update_metrics_source      = var.collect_cloudwatch_metrics == "None" ? false : (var.cloudwatch_metrics_source_url == "" ? false : true)
  create_metric_source     = var.collect_cloudwatch_metrics == "None" ? false : (local.update_metrics_source ? false : true)
  metrics_source_name      = var.cloudwatch_metrics_source_details.source_name == "CloudWatch Metrics (Region)" ? "CloudWatch Metrics ${local.aws_region}" : var.cloudwatch_metrics_source_details.source_name
  metrics_fields           = local.use_kf_metrics_source ? merge(var.cloudwatch_metrics_source_details.fields, { account = var.aws_account_alias }) : merge(var.cloudwatch_metrics_source_details.fields, { account = var.aws_account_alias, accountid = local.aws_account_id })

  # CloudWatch logs source updated details
  create_llf_logs_source      = var.collect_cloudwatch_logs == "Lambda Log Forwarder" && var.cloudwatch_logs_source_url == ""
  create_kf_logs_source       = var.collect_cloudwatch_logs == "Kinesis Firehose Log Source" && var.cloudwatch_logs_source_url == ""
  update_logs_source          = var.collect_cloudwatch_logs == "None" ? false : (var.cloudwatch_logs_source_url == "" ? false : true)
  create_cw_logs_source       = var.collect_cloudwatch_logs == "None" ? false : (local.update_logs_source ? false : true)
  cloudwatch_logs_source_name = var.cloudwatch_logs_source_details.source_name == "CloudWatch Logs (Region)" ? "CloudWatch Logs ${local.aws_region}" : var.cloudwatch_logs_source_details.source_name
  cloudwatch_logs_fields      = merge(var.cloudwatch_logs_source_details.fields, { account = var.aws_account_alias, region = local.aws_region, namespace = "aws/lambda", accountid = local.aws_account_id })

  # Root Cause sources updated details
  create_inventory_source  = var.collect_root_cause_data == "Inventory Source" || var.collect_root_cause_data == "Both"
  create_xray_source       = var.collect_root_cause_data == "Xray Source" || var.collect_root_cause_data == "Both"
  create_root_cause_source = local.create_inventory_source || local.create_xray_source
  inventory_source_name    = var.inventory_source_details.source_name == "AWS Inventory (Region)" ? "AWS Inventory ${local.aws_region}" : var.inventory_source_details.source_name
  xray_source_name         = var.xray_source_details.source_name == "AWS Xray (Region)" ? "AWS Xray ${local.aws_region}" : var.xray_source_details.source_name

  # Common Bucket details
  create_cloudtrail_bucket      = local.create_cloudtrail_source && var.cloudtrail_source_details.bucket_details.create_bucket
  create_elb_bucket             = local.create_elb_source && var.elb_source_details.bucket_details.create_bucket
  create_classic_lb_bucket      = local.create_classic_lb_source && var.classic_lb_source_details.bucket_details.create_bucket
  create_kf_metrics_fail_bucket = local.create_kf_metrics_source && var.cloudwatch_metrics_source_details.bucket_details.create_bucket
  create_kf_logs_fail_bucket    = local.create_kf_logs_source && var.cloudwatch_logs_source_details.bucket_details.create_bucket
  create_common_bucket          = local.create_cloudtrail_bucket || local.create_elb_bucket || local.create_classic_lb_bucket || local.create_kf_metrics_fail_bucket || local.create_kf_logs_fail_bucket
  common_bucket_name            = local.create_common_bucket ? "aws-observability-${random_string.aws_random.id}" : ""
  common_force_destroy          = local.create_common_bucket && (var.cloudtrail_source_details.bucket_details.force_destroy_bucket || var.elb_source_details.bucket_details.force_destroy_bucket || var.cloudwatch_metrics_source_details.bucket_details.force_destroy_bucket || var.cloudwatch_logs_source_details.bucket_details.force_destroy_bucket)

  create_common_sns_topic = local.create_common_bucket && (local.create_elb_source || local.create_classic_lb_source || local.create_cloudtrail_source)

  # Create an IAM role that provides trust relationship with AWS account
  create_iam_role = var.existing_iam_details.create_iam_role && (local.create_elb_source || local.create_classic_lb_source ||local.create_cloudtrail_source || local.create_kf_metrics_source || local.create_cw_metrics_source || local.create_root_cause_source)

  # Create any Sumo Logic source. Keep on adding to this if any new source is added.
  create_any_source = local.create_cloudtrail_source || local.create_elb_source || local.create_metric_source || local.create_cw_logs_source || local.create_root_cause_source || local.create_classic_lb_source
  

  # Create a new Sumo Logic hosted collector
  create_collector = var.sumologic_existing_collector_details.create_collector && local.create_any_source

  # Collector Name
  collector_name = local.create_collector && var.sumologic_collector_details.collector_name == "AWS Observability (AWS Account Alias) (Account ID)" ? "AWS Observability ${var.aws_account_alias} ${local.aws_account_id}" : var.sumologic_collector_details.collector_name

  # ELB account IDs
  region_to_elb_account_id = {
    "us-east-1"      = "127311923021",
    "us-east-2"      = "033677994240",
    "us-west-1"      = "027434742980",
    "us-west-2"      = "797873946194",
    "af-south-1"     = "098369216593",
    "ca-central-1"   = "985666609251",
    "eu-central-1"   = "054676820928",
    "eu-west-1"      = "156460612806",
    "eu-west-2"      = "652711504416",
    "eu-south-1"     = "635631232127",
    "eu-west-3"      = "009996457667",
    "eu-north-1"     = "897822967062",
    "ap-east-1"      = "754344448648",
    "ap-northeast-1" = "582318560864",
    "ap-northeast-2" = "600734575887",
    "ap-northeast-3" = "383597477331",
    "ap-southeast-1" = "114774131450",
    "ap-southeast-2" = "783225319266",
    "ap-south-1"     = "718504428378",
    "me-south-1"     = "076674570225",
    "sa-east-1"      = "507241528517",
    "us-gov-west-1"  = "048591011584",
    "us-gov-east-1"  = "190560391635",
    "cn-north-1"     = "638102146993",
    "cn-northwest-1" = "037604701340"
  }

  namespace_scan_interval = {
    "ApplicationELB" = 60000,
    "ApiGateway"     = 300000,
    "DynamoDB"       = 300000,
    "Lambda"         = 300000,
    "RDS"            = 300000,
    "ECS"            = 300000,
    "ElastiCache"    = 300000,
    "ELB"            = 300000,
    "NetworkELB"     = 60000,
    "SQS"            = 300000,
    "SNS"            = 300000,
    "EC2"            = 300000,
  }
}