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

resource "time_sleep" "wait_for_minutes" {
  create_duration = "${var.wait_for_seconds}s"
}

module "cloudtrail_module" {
  depends_on = [time_sleep.wait_for_minutes]
  for_each   = toset(local.create_cloudtrail_source ? ["cloudtrail_module"] : [])

  source = "SumoLogic/sumo-logic-integrations/sumologic//aws/cloudtrail"

  create_collector          = false
  create_trail              = var.cloudtrail_source_details.bucket_details.create_bucket ? true : false
  sumologic_organization_id = var.sumologic_organization_id
  wait_for_seconds          = 1

  source_details = {
    source_name     = local.cloudtrail_source_name
    source_category = var.cloudtrail_source_details.source_category
    description     = var.cloudtrail_source_details.description
    collector_id    = local.create_collector ? sumologic_collector.collector["collector"].id : var.sumologic_existing_collector_details.collector_id
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
    iam_details = {
      create_iam_role = false
      iam_role_arn    = local.create_iam_role ? aws_iam_role.sumologic_iam_role["sumologic_iam_role"].arn : var.existing_iam_details.iam_role_arn
    }
    sns_topic_details = {
      create_sns_topic = var.cloudtrail_source_details.bucket_details.create_bucket ? false : true
      sns_topic_arn    = var.cloudtrail_source_details.bucket_details.create_bucket ? aws_sns_topic.sns_topic["sns_topic"].arn : ""
    }
  }
}

#ALB module
module "elb_module" {
  depends_on = [time_sleep.wait_for_minutes]
  for_each   = toset(local.create_elb_source ? ["elb_module"] : [])

  source = "SumoLogic/sumo-logic-integrations/sumologic//aws/elb"

  create_collector          = false
  sumologic_organization_id = var.sumologic_organization_id
  wait_for_seconds          = 1

  source_details = {
    source_name     = local.elb_source_name
    source_category = var.elb_source_details.source_category
    description     = var.elb_source_details.description
    collector_id    = local.create_collector ? sumologic_collector.collector["collector"].id : var.sumologic_existing_collector_details.collector_id
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
    iam_details = {
      create_iam_role = false
      iam_role_arn    = local.create_iam_role ? aws_iam_role.sumologic_iam_role["sumologic_iam_role"].arn : var.existing_iam_details.iam_role_arn
    }
    sns_topic_details = {
      create_sns_topic = var.elb_source_details.bucket_details.create_bucket ? false : true
      sns_topic_arn    = var.elb_source_details.bucket_details.create_bucket ? aws_sns_topic.sns_topic["sns_topic"].arn : ""
    }
  }

  auto_enable_access_logs = var.auto_enable_access_logs
  app_semantic_version = "1.0.12"
  auto_enable_access_logs_options = {
    filter                 = "'Type': 'application'|'type': 'application'"
    remove_on_delete_stack = true
  }
}

#CLB module
module "classic_lb_module" {
  depends_on = [time_sleep.wait_for_minutes]
  for_each   = toset(local.create_classic_lb_source ? ["classic_lb_module"] : [])

  source = "SumoLogic/sumo-logic-integrations/sumologic//aws/elasticloadbalancing"

  create_collector          = false
  sumologic_organization_id = var.sumologic_organization_id
  wait_for_seconds          = 1

  source_details = {
    source_name     = local.classic_lb_source_name
    source_category = var.classic_lb_source_details.source_category
    description     = var.classic_lb_source_details.description
    collector_id    = local.create_collector ? sumologic_collector.collector["collector"].id : var.sumologic_existing_collector_details.collector_id
    bucket_details = {
      create_bucket        = false
      bucket_name          = var.classic_lb_source_details.bucket_details.create_bucket ? aws_s3_bucket.s3_bucket["s3_bucket"].bucket : var.classic_lb_source_details.bucket_details.bucket_name
      path_expression      = local.classic_lb_path_exp
      force_destroy_bucket = false
    }
    paused               = false
    scan_interval        = 60000
    sumo_account_id      = local.sumo_account_id
    cutoff_relative_time = "-1d"
    fields               = local.classic_lb_fields
    iam_details = {
      create_iam_role = false
      iam_role_arn    = local.create_iam_role ? aws_iam_role.sumologic_iam_role["sumologic_iam_role"].arn : var.existing_iam_details.iam_role_arn
    }
    sns_topic_details = {
      create_sns_topic = var.classic_lb_source_details.bucket_details.create_bucket ? false : true
      sns_topic_arn    = var.classic_lb_source_details.bucket_details.create_bucket ? aws_sns_topic.sns_topic["sns_topic"].arn : ""
    }
  }
  auto_enable_access_logs = var.auto_enable_classic_lb_access_logs
  app_semantic_version = "1.0.12"
  auto_enable_access_logs_options = {
    bucket_prefix          = local.auto_classic_lb_path_exp
    auto_enable_logging    = "ELB"
    filter                 = "'apiVersion': '2012-06-01'"
    remove_on_delete_stack = true
  }
}

module "cloudwatch_metrics_source_module" {
  depends_on = [time_sleep.wait_for_minutes]
  for_each   = local.create_cw_metrics_source ? toset(var.cloudwatch_metrics_source_details.limit_to_namespaces) : []

  source = "SumoLogic/sumo-logic-integrations/sumologic//aws/cloudwatchmetrics"

  create_collector          = false
  sumologic_organization_id = var.sumologic_organization_id
  wait_for_seconds          = 1

  source_details = {
    source_name         = "${local.metrics_source_name} ${regex("^AWS/(\\w+)$", each.value)[0]}"
    source_category     = var.cloudwatch_metrics_source_details.source_category
    description         = var.cloudwatch_metrics_source_details.description
    collector_id        = local.create_collector ? sumologic_collector.collector["collector"].id : var.sumologic_existing_collector_details.collector_id
    limit_to_namespaces = [each.value]
    limit_to_regions    = [local.aws_region]
    paused              = false
    scan_interval       = lookup(local.namespace_scan_interval,regex("^AWS/(\\w+)$", each.value)[0],"300000")
    sumo_account_id     = local.sumo_account_id
    fields              = local.metrics_fields
    iam_details = {
      create_iam_role = false
      iam_role_arn    = local.create_iam_role ? aws_iam_role.sumologic_iam_role["sumologic_iam_role"].arn : var.existing_iam_details.iam_role_arn
    }
  }
}

module "kinesis_firehose_for_metrics_source_module" {
  depends_on = [time_sleep.wait_for_minutes]
  for_each   = toset(local.create_kf_metrics_source ? ["kinesis_firehose_for_metrics_source_module"] : [])

  source = "SumoLogic/sumo-logic-integrations/sumologic//aws/kinesisfirehoseformetrics"

  create_collector          = false
  sumologic_organization_id = var.sumologic_organization_id
  wait_for_seconds          = 1

  source_details = {
    source_name         = local.metrics_source_name
    source_category     = var.cloudwatch_metrics_source_details.source_category
    description         = var.cloudwatch_metrics_source_details.description
    collector_id        = local.create_collector ? sumologic_collector.collector["collector"].id : var.sumologic_existing_collector_details.collector_id
    limit_to_namespaces = var.cloudwatch_metrics_source_details.limit_to_namespaces
    sumo_account_id     = local.sumo_account_id
    fields              = local.metrics_fields
    iam_details = {
      create_iam_role = false
      iam_role_arn    = local.create_iam_role ? aws_iam_role.sumologic_iam_role["sumologic_iam_role"].arn : var.existing_iam_details.iam_role_arn
    }
  }

  create_bucket = false
  bucket_details = {
    bucket_name          = var.cloudwatch_metrics_source_details.bucket_details.create_bucket ? aws_s3_bucket.s3_bucket["s3_bucket"].bucket : var.cloudwatch_metrics_source_details.bucket_details.bucket_name
    force_destroy_bucket = false
  }
}

module "cloudwatch_logs_lambda_log_forwarder_module" {
  depends_on = [time_sleep.wait_for_minutes]
  for_each   = toset(local.create_llf_logs_source ? ["cloudwatch_logs_lambda_log_forwarder_module"] : [])

  source = "SumoLogic/sumo-logic-integrations/sumologic//aws/cloudwatchlogsforwarder"

  create_collector = false

  # Lambda Log Forwarder configurations
  email_id               = var.cloudwatch_logs_source_details.lambda_log_forwarder_config.email_id
  log_format             = var.cloudwatch_logs_source_details.lambda_log_forwarder_config.log_format
  log_stream_prefix      = var.cloudwatch_logs_source_details.lambda_log_forwarder_config.log_stream_prefix
  include_log_group_info = var.cloudwatch_logs_source_details.lambda_log_forwarder_config.include_log_group_info
  workers                = var.cloudwatch_logs_source_details.lambda_log_forwarder_config.workers

  source_details = {
    source_name     = local.cloudwatch_logs_source_name
    source_category = var.cloudwatch_logs_source_details.source_category
    description     = var.cloudwatch_logs_source_details.description
    collector_id    = local.create_collector ? sumologic_collector.collector["collector"].id : var.sumologic_existing_collector_details.collector_id
    fields          = local.cloudwatch_logs_fields
  }

  auto_enable_logs_subscription = var.auto_enable_logs_subscription
  app_semantic_version = "1.0.11"
  auto_enable_logs_subscription_options = {
    filter = var.auto_enable_logs_subscription_options.filter
  }
}

module "kinesis_firehose_for_logs_module" {
  depends_on = [time_sleep.wait_for_minutes]
  for_each   = toset(local.create_kf_logs_source ? ["kinesis_firehose_for_logs_module"] : [])

  source = "SumoLogic/sumo-logic-integrations/sumologic//aws/kinesisfirehoseforlogs"

  create_collector = false

  source_details = {
    source_name     = local.cloudwatch_logs_source_name
    source_category = var.cloudwatch_logs_source_details.source_category
    description     = var.cloudwatch_logs_source_details.description
    collector_id    = local.create_collector ? sumologic_collector.collector["collector"].id : var.sumologic_existing_collector_details.collector_id
    fields          = local.cloudwatch_logs_fields
  }

  create_bucket = false
  bucket_details = {
    bucket_name          = var.cloudwatch_logs_source_details.bucket_details.create_bucket ? aws_s3_bucket.s3_bucket["s3_bucket"].bucket : var.cloudwatch_logs_source_details.bucket_details.bucket_name
    force_destroy_bucket = false
  }

  auto_enable_logs_subscription = var.auto_enable_logs_subscription
  app_semantic_version = "1.0.11"
  auto_enable_logs_subscription_options = {
    filter = var.auto_enable_logs_subscription_options.filter
  }
}

module "root_cause_sources_module" {
  depends_on = [time_sleep.wait_for_minutes]
  for_each   = toset(local.create_root_cause_source ? ["root_cause_sources_module"] : [])

  source = "SumoLogic/sumo-logic-integrations/sumologic//aws/rootcause"

  create_collector          = false
  sumologic_organization_id = var.sumologic_organization_id

  wait_for_seconds = 1
  iam_details = {
    create_iam_role = false
    iam_role_arn    = local.create_iam_role ? aws_iam_role.sumologic_iam_role["sumologic_iam_role"].arn : var.existing_iam_details.iam_role_arn
  }

  create_inventory_source = local.create_inventory_source
  inventory_source_details = {
    source_name         = local.inventory_source_name
    source_category     = var.inventory_source_details.source_category
    collector_id        = local.create_collector ? sumologic_collector.collector["collector"].id : var.sumologic_existing_collector_details.collector_id
    description         = var.inventory_source_details.description
    limit_to_namespaces = var.inventory_source_details.limit_to_namespaces
    limit_to_regions    = [local.aws_region]
    paused              = false
    scan_interval       = 300000
    sumo_account_id     = local.sumo_account_id
    fields              = var.inventory_source_details.fields
  }

  create_xray_source = local.create_xray_source
  xray_source_details = {
    source_name      = local.xray_source_name
    source_category  = var.xray_source_details.source_category
    collector_id     = local.create_collector ? sumologic_collector.collector["collector"].id : var.sumologic_existing_collector_details.collector_id
    description      = var.xray_source_details.description
    limit_to_regions = [local.aws_region]
    paused           = false
    scan_interval    = 300000
    sumo_account_id  = local.sumo_account_id
    fields           = var.xray_source_details.fields
  }
}