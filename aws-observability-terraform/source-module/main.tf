# AWS Observability Sources
# 1. Create Common Collector
# 2. Create Common IAM role with permissions for alb and cloudtrail S3 Bucket, cloudwatch metrics, inventory and xray source. -> main_iam_role.tf
# 3. S3 Bucket and SNS Topic and policy -> main_s3_bucket.tf

resource "random_string" "aws_random" {
  length  = 10
  upper   = false
  special = false
}

resource "sumologic_collector" "collector" {
  for_each = toset(local.create_collector ? ["collector"] : [])

  name        = local.collector_name
  description = var.sumologic_collector_details.description
  fields      = var.sumologic_collector_details.fields
  timezone    = "UTC"
}

module "cloudtrail_module" {
  for_each = toset(var.collect_cloudtrail_logs ? ["cloudtrail_module"] : [])

  source = "SumoLogic/sumo-logic-integrations/sumologic//aws/cloudtrail"

  create_collector          = false
  create_trail              = local.create_common_bucket ? true : false
  sumologic_organization_id = var.sumologic_organization_id
  source_details = {
    source_name     = local.cloudtrail_source_name
    source_category = var.cloudtrail_source_details.source_category
    description     = var.cloudtrail_source_details.description
    collector_id    = local.create_collector ? sumologic_collector.collector["collector"].id : var.sumologic_existing_collector_id
    bucket_details = {
      create_bucket        = false
      bucket_name          = var.cloudtrail_source_details.bucket_details.create_bucket ? aws_s3_bucket.s3_bucket["s3_bucket"].bucket : var.cloudtrail_source_details.bucket_details.bucket_name
      path_expression      = local.cloudtrail_path_exp
      force_destroy_bucket = false
    }
    paused               = false
    scan_interval        = 60000
    sumo_account_id      = local.sumo_account_id
    cutoff_relative_time = "-1d"
    fields               = local.cloudtrail_fields
    iam_role_arn         = local.create_iam_role ? aws_iam_role.sumologic_iam_role["sumologic_iam_role"].arn : var.iam_role_arn
    sns_topic_arn        = local.create_common_bucket ? aws_sns_topic.sns_topic["sns_topic"].arn : ""
  }
}

module "elb_module" {
  for_each = toset(var.collect_elb_logs ? ["elb_module"] : [])

  source = "SumoLogic/sumo-logic-integrations/sumologic//aws/elb"

  create_collector          = false
  sumologic_organization_id = var.sumologic_organization_id

  source_details = {
    source_name     = local.elb_source_name
    source_category = var.elb_source_details.source_category
    description     = var.elb_source_details.description
    collector_id    = local.create_collector ? sumologic_collector.collector["collector"].id : var.sumologic_existing_collector_id
    bucket_details = {
      create_bucket        = false
      bucket_name          = var.elb_source_details.bucket_details.create_bucket ? aws_s3_bucket.s3_bucket["s3_bucket"].bucket : var.elb_source_details.bucket_details.bucket_name
      path_expression      = local.elb_path_exp
      force_destroy_bucket = false
    }
    paused               = false
    scan_interval        = 60000
    sumo_account_id      = local.sumo_account_id
    cutoff_relative_time = "-1d"
    fields               = local.elb_fields
    iam_role_arn         = local.create_iam_role ? aws_iam_role.sumologic_iam_role["sumologic_iam_role"].arn : var.iam_role_arn
    sns_topic_arn        = local.create_common_bucket ? aws_sns_topic.sns_topic["sns_topic"].arn : ""
  }

  auto_enable_access_logs = var.auto_enable_access_logs
  auto_enable_access_logs_options = {
    filter                 = "'Type': 'application'|'type': 'application'"
    remove_on_delete_stack = true
  }
}

module "cloudwatch_metrics_source_module" {
  for_each = local.create_cw_metrics_source ? toset(var.cloudwatch_metrics_source_details.limit_to_namespaces) : []
  
  source = "SumoLogic/sumo-logic-integrations/sumologic//aws/cloudwatchmetrics"
  
  create_collector = false
  sumologic_organization_id = var.sumologic_organization_id
  
  source_details = {
    source_name = "${local.metrics_source_name} ${regex("^AWS/(\\w+)$", each.value)[0]}"
    source_category = var.cloudwatch_metrics_source_details.source_category
    description = var.cloudwatch_metrics_source_details.description
    collector_id = local.create_collector ? sumologic_collector.collector["collector"].id : var.sumologic_existing_collector_id
    limit_to_namespaces = each.value
    paused = false
    scan_interval = local.namespace_scan_interval[regex("^AWS/(\\w+)$", each.value)[0]]
    sumo_account_id = local.sumo_account_id
    fields = local.metrics_fields
    iam_role_arn = local.create_iam_role ? aws_iam_role.sumologic_iam_role["sumologic_iam_role"].arn : var.iam_role_arn
  }
}

module "kinesis_metrics_source_module" {
  for_each = toset(local.create_kf_metrics_source ? ["kinesis_metrics_source_module"] : [])
  
  source = "SumoLogic/sumo-logic-integrations/sumologic//aws/kinesisfirehoseformetrics"
  
  create_collector = false
  sumologic_organization_id = var.sumologic_organization_id
  
  source_details = {
    source_name = local.metrics_source_name
    source_category = var.cloudwatch_metrics_source_details.source_category
    description = var.cloudwatch_metrics_source_details.description
    collector_id = local.create_collector ? sumologic_collector.collector["collector"].id : var.sumologic_existing_collector_id
    limit_to_namespaces = var.cloudwatch_metrics_source_details.limit_to_namespaces
    sumo_account_id = local.sumo_account_id
    fields = local.metrics_fields
    iam_role_arn = local.create_iam_role ? aws_iam_role.sumologic_iam_role["sumologic_iam_role"].arn : var.iam_role_arn
  }
  
  create_bucket = false
  bucket_details = {
    bucket_name = var.cloudwatch_metrics_source_details.bucket_details.create_bucket ? aws_s3_bucket.s3_bucket["s3_bucket"].bucket : var.cloudwatch_metrics_source_details.bucket_details.bucket_name
    force_destroy_bucket = false
  }
}