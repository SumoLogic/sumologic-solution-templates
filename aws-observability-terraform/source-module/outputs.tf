output "sumologic_collector" {
  value       = local.create_collector ? sumologic_collector.collector : {}
  description = "Sumo Logic collector details."
}

output "aws_iam_role" {
  value       = local.create_iam_role ? aws_iam_role.sumologic_iam_role : {}
  description = "Sumo Logic AWS IAM Role for trust relationship."
}

output "aws_s3_bucket" {
  value       = local.create_common_bucket ? aws_s3_bucket.s3_bucket : {}
  description = "Common S3 Bucket to store CloudTrail, ELB and Failed Kinesis data."
}

output "aws_sns_topic" {
  value       = local.create_common_sns_topic ? aws_sns_topic.sns_topic : {}
  description = "Common SNS topic attached to the S3 bucket."
}

output "aws_cloudtrail" {
  value       = var.collect_cloudtrail_logs && var.cloudtrail_source_details.bucket_details.create_bucket ? module.cloudtrail_module["cloudtrail_module"].aws_cloudtrail : {}
  description = "AWS Trail created to send CloudTrail logs to AWS S3 bucket."
}

output "cloudtrail_sns_topic" {
  value       = var.collect_cloudtrail_logs && !var.cloudtrail_source_details.bucket_details.create_bucket ? module.cloudtrail_module["cloudtrail_module"].aws_sns_topic : {}
  description = "SNS topic created to be attached to an existing cloudtrail bucket."
}

output "cloudtrail_source" {
  value       = var.collect_cloudtrail_logs ? module.cloudtrail_module["cloudtrail_module"].sumologic_source : null
  description = "Sumo Logic AWS CloudTrail source."
}

output "cloudtrail_sns_subscription" {
  value       = var.collect_cloudtrail_logs ? module.cloudtrail_module["cloudtrail_module"].aws_sns_subscription : {}
  description = "AWS SNS subscription to Sumo Logic AWS CloudTrail source."
}

output "elb_sns_topic" {
  value       = var.collect_elb_logs && !var.elb_source_details.bucket_details.create_bucket ? module.elb_module["elb_module"].aws_sns_topic : {}
  description = "SNS topic created to be attached to an existing elb logs bucket."
}

output "elb_source" {
  value       = var.collect_elb_logs ? module.elb_module["elb_module"].sumologic_source : null
  description = "Sumo Logic AWS ELB source."
}

output "elb_sns_subscription" {
  value       = var.collect_elb_logs ? module.elb_module["elb_module"].aws_sns_subscription : {}
  description = "AWS SNS subscription to Sumo Logic AWS ELB source."
}

output "elb_auto_enable_stack" {
  value       = var.collect_elb_logs && var.auto_enable_access_logs != "None" ? module.elb_module["elb_module"].aws_serverlessapplicationrepository_cloudformation_stack : {}
  description = "AWS CloudFormation stack for ALB Auto Enable access logs."
}

output "cloudwatch_metrics_source" {
  value = local.create_cw_metrics_source ? toset([
    for namespace in var.cloudwatch_metrics_source_details.limit_to_namespaces : module.cloudwatch_metrics_source_module[namespace].sumologic_source
  ]) : []
  description = "Sumo Logic AWS CloudWatch Metrics source."
}

output "kinesis_firehose_for_metrics_source" {
  value       = local.create_kf_metrics_source ? module.kinesis_firehose_for_metrics_source_module["kinesis_firehose_for_metrics_source_module"].sumologic_source : null
  description = "Sumo Logic AWS Kinesis Firehose for Metrics source."
}

output "aws_kinesis_firehose_metrics_delivery_stream" {
  value       = local.create_kf_metrics_source ? module.kinesis_firehose_for_metrics_source_module["kinesis_firehose_for_metrics_source_module"].aws_kinesis_firehose_delivery_stream : null
  description = "AWS Kinesis firehose delivery stream to send metrics to Sumo Logic."
}

output "aws_cloudwatch_metric_stream" {
  value       = local.create_kf_metrics_source ? module.kinesis_firehose_for_metrics_source_module["kinesis_firehose_for_metrics_source_module"].aws_cloudwatch_metric_stream : null
  description = "CloudWatch metrics stream to send metrics."
}

output "cloudwatch_logs_source" {
  value       = local.create_llf_logs_source ? module.cloudwatch_logs_lambda_log_forwarder_module["cloudwatch_logs_lambda_log_forwarder_module"].sumologic_source : null
  description = "Sumo Logic HTTP source."
}

output "cloudwatch_logs_lambda_function" {
  value       = local.create_llf_logs_source ? module.cloudwatch_logs_lambda_log_forwarder_module["cloudwatch_logs_lambda_log_forwarder_module"].aws_cw_lambda_function : null
  description = "AWS Lambda function to send logs to Sumo Logic."
}

output "cloudwatch_logs_auto_subscribe_stack" {
  value       = local.create_llf_logs_source && var.auto_enable_logs_subscription != "None" ? module.cloudwatch_logs_lambda_log_forwarder_module["cloudwatch_logs_lambda_log_forwarder_module"].aws_serverlessapplicationrepository_cloudformation_stack : {}
  description = "AWS CloudFormation stack for Auto Enable logs subscription."
}

output "kinesis_firehose_for_logs_source" {
  value       = local.create_kf_logs_source ? module.kinesis_firehose_for_logs_module["kinesis_firehose_for_logs_module"].sumologic_source : null
  description = "Sumo Logic Kinesis Firehose for Logs source."
}

output "aws_kinesis_firehose_logs_delivery_stream" {
  value       = local.create_kf_logs_source ? module.kinesis_firehose_for_logs_module["kinesis_firehose_for_logs_module"].aws_kinesis_firehose_delivery_stream : null
  description = "AWS Kinesis firehose delivery stream to send logs to Sumo Logic."
}

output "kinesis_firehose_for_logs_auto_subscribe_stack" {
  value       = local.create_kf_logs_source && var.auto_enable_logs_subscription != "None" ? module.kinesis_firehose_for_logs_module["kinesis_firehose_for_logs_module"].aws_serverlessapplicationrepository_cloudformation_stack : {}
  description = "AWS CloudFormation stack for Auto Enable logs subscription."
}

output "inventory_source" {
  value       = local.create_inventory_source ? module.root_cause_sources_module["root_cause_sources_module"].inventory_sumologic_source : null
  description = "Sumo Logic AWS Inventory source."
}

output "xray_source" {
  value       = local.create_xray_source ? module.root_cause_sources_module["root_cause_sources_module"].xray_sumologic_source : null
  description = "Sumo Logic AWS Xray source."
}