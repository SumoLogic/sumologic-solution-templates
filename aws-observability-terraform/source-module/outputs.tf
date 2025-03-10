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
  value       = local.create_cloudtrail_source && var.cloudtrail_source_details.bucket_details.create_bucket ? module.cloudtrail_module["cloudtrail_module"].aws_cloudtrail : {}
  description = "AWS Trail created to send CloudTrail logs to AWS S3 bucket."
}

output "cloudtrail_sns_topic" {
  value       = local.create_cloudtrail_source && !var.cloudtrail_source_details.bucket_details.create_bucket ? module.cloudtrail_module["cloudtrail_module"].aws_sns_topic : {}
  description = "SNS topic created to be attached to an existing cloudtrail bucket."
}

output "cloudtrail_source" {
  value       = local.create_cloudtrail_source ? module.cloudtrail_module["cloudtrail_module"].sumologic_source : null
  description = "Sumo Logic AWS CloudTrail source."
}

output "cloudtrail_sns_subscription" {
  value       = local.create_cloudtrail_source ? module.cloudtrail_module["cloudtrail_module"].aws_sns_subscription : {}
  description = "AWS SNS subscription to Sumo Logic AWS CloudTrail source."
}

output "elb_sns_topic" {
  value       = local.create_elb_source && !var.elb_source_details.bucket_details.create_bucket ? module.elb_module["elb_module"].aws_sns_topic : {}
  description = "SNS topic created to be attached to an existing elb logs bucket."
}

output "elb_source" {
  value       = local.create_elb_source ? module.elb_module["elb_module"].sumologic_source : null
  description = "Sumo Logic AWS ELB source."
}

output "elb_sns_subscription" {
  value       = local.create_elb_source ? module.elb_module["elb_module"].aws_sns_subscription : {}
  description = "AWS SNS subscription to Sumo Logic AWS ELB source."
}

output "elb_auto_enable_stack" {
  value       = local.create_elb_source && var.auto_enable_access_logs != "None" ? module.elb_module["elb_module"].aws_serverlessapplicationrepository_cloudformation_stack : {}
  description = "AWS CloudFormation stack for ALB Auto Enable access logs."
}

output "classic_lb_sns_topic" {
  value       = local.create_classic_lb_source && !var.classic_lb_source_details.bucket_details.create_bucket ? module.classic_lb_module["classic_lb_module"].aws_sns_topic : {}
  description = "SNS topic created to be attached to an existing classic lb logs bucket."
}

output "classic_lb_source" {
  value       = local.create_classic_lb_source ? module.classic_lb_module["classic_lb_module"].sumologic_source : null
  description = "Sumo Logic AWS Classic LB source."
}

output "classic_lb_sns_subscription" {
  value       = local.create_classic_lb_source ? module.classic_lb_module["classic_lb_module"].aws_sns_subscription : {}
  description = "AWS SNS subscription to Sumo Logic AWS Classic LB source."
}

output "classic_lb_auto_enable_stack" {
  value       = local.create_classic_lb_source && var.auto_enable_access_logs != "None" ? module.classic_lb_module["classic_lb_module"].aws_serverlessapplicationrepository_cloudformation_stack : {}
  description = "AWS CloudFormation stack for Classic LB Auto Enable access logs."
}

output "cloudwatch_metrics_source" {
  value = local.create_cw_metrics_source && length(local.aws_namespace) > 0 ? toset([
    for namespace in local.aws_namespace : module.cloudwatch_metrics_source_module[namespace].sumologic_source
  ]) : []
  description = "Sumo Logic AWS CloudWatch Metrics source."
}

output "cloudwatch_custom_metrics_source" {
  value = local.create_cw_metrics_source && length(local.custom_namespace) > 0 ? module.cloudwatch_custom_metrics_source_module["Custom"].sumologic_source : null
  description = "Sumo Logic CloudWatch Custom Metrics source."
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