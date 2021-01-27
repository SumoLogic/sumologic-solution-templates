output "common_bucket" {
  value       = local.manage_target_s3_bucket ? aws_s3_bucket.common : {}
  description = "Exported attributes for the common bucket."
}

output "cloudwatch_logs_source_lambda_arn" {
  value       = var.manage_cloudwatch_logs_source ? aws_lambda_function.cloudwatch_logs_source_logs["this"].arn : ""
  description = "Cloudwatch logs source lambda arn."
}

output "enterprise_account" {
  value       = data.external.sumologic_account.result.enterprise
  description = "Check whether SumoLogic account is enterprise."
}

output "paid_account" {
  value       = data.external.sumologic_account.result.paid
  description = "Check whether SumoLogic account is paid."
}

output "cloudwatch_metrics_namespaces" {
  value       = var.cloudwatch_metrics_namespaces
  description = "CloudWatch Metrics Namespaces for Inventory Source."
}

// added outputs for testing
output "alb_sns_topic_name" {
  value       = local.manage_alb_sns_topic ? aws_sns_topic.alb_source["this"].name : ""
  description = "ALB SNS topic name"
}

output "sumologic_elb_source" {
  value       = var.manage_alb_logs_source ? sumologic_elb_source.this["this"].name : ""
  description = "Sumologic ELB source"
}

output "common_sns_topic_name" {
  value       = local.manage_target_s3_bucket ? aws_sns_topic.common["this"].name : ""
  description = "SNS topic for common bucket"
}

output "aws_sns_topic_policy_common_name" {
  value       = local.manage_target_s3_bucket ? aws_sns_topic_policy.common["this"].arn : ""
  description = "SNS topic policy for common S3 bucket"
}

output "sumologic_aws_xray_source_name" {
  value       = var.manage_aws_xray_source ? sumologic_aws_xray_source.this["this"].name : ""
  description = "X-ray source"
}

output "sumologic_aws_metadata_source_name" {
  value       = var.manage_metadata_source ? sumologic_metadata_source.this["this"].name : ""
  description = "Metadata source"
}

output "sumologic_aws_inventory_source_name" {
  value       = var.manage_aws_inventory_source ? sumologic_aws_inventory_source.this["this"].name : ""
  description = "Inventory source"
}

output "aws_cloudwatch_logs_name" {
  value       = var.manage_cloudwatch_logs_source ? sumologic_http_source.cloudwatch_logs["this"].name : ""
  description = "Cloudwatch logs name"
}

output "sumologic_collector_name" {
  value       = local.manage_collector ? sumologic_collector.hosted["this"].name : ""
  description = "Collector name"
}

output "aws_iam_role_sumologic_source_name" {
  value       = local.manage_sumologic_source_role ? aws_iam_role.sumologic_source["this"].name : ""
  description = "Sumologic source IAM role"
}

output "aws_iam_policy_sumologic_source_name" {
  value       = local.manage_sumologic_source_role ? aws_iam_policy.sumologic_source["this"].name : ""
  description = "Sumologic source IAM Policy"
}

output "aws_iam_policy_sumologic_inventory_name" {
  value       = local.manage_sumologic_source_role ? aws_iam_policy.sumologic_inventory["this"].name : ""
  description = "Sumologic inventory IAM Policy"
}

output "aws_iam_role_cw_logs_source_lambda_name" {
  value       = var.manage_cloudwatch_logs_source ? aws_iam_role.cloudwatch_logs_source_lambda["this"].name : ""
  description = "Cloudwatch logs source lambda IAM role"
}

output "aws_iam_policy_cw_logs_source_lambda_logs_name" {
  value       = var.manage_cloudwatch_logs_source ? aws_iam_policy.cloudwatch_logs_source_lambda_logs["this"].name : ""
  description = "Cloudwatch logs source lambda logs IAM policy"
}

output "aws_iam_policy_cw_logs_source_lambda_sqs_name" {
  value       = var.manage_cloudwatch_logs_source ? aws_iam_policy.cloudwatch_logs_source_lambda_sqs["this"].name : ""
  description = "Cloudwatch lgos source lambda queue IAM Policy"
}

output "aws_iam_policy_cw_logs_source_lambda_lambda_name" {
  value       = var.manage_cloudwatch_logs_source ? aws_iam_policy.cloudwatch_logs_source_lambda_lambda["this"].name : ""
  description = "Cloudwatch logs source lambda IAM Policy"
}

output "aws_lambda_function_cloudwatch_logs_source" {
  value       = var.manage_cloudwatch_logs_source ? aws_lambda_function.cloudwatch_logs_source_logs["this"].function_name : ""
  description = "Cloudwatch logs source lambda"
}

output "aws_lambda_function_cloudwatch_logs_source_process_deadletter" {
  value       = var.manage_cloudwatch_logs_source ? aws_lambda_function.cloudwatch_logs_source_process_deadletter["this"].function_name : ""
  description = "Cloudwatch logs source proccess lambda"
}

output "aws_sqs_queue_cloudwatch_logs_source_deadletter" {
  value       = var.manage_cloudwatch_logs_source ? aws_sqs_queue.cloudwatch_logs_source_deadletter["this"].name : ""
  description = "SQS queue logs source"
}

output "aws_sns_topic_cloudwatch_logs_source_email" {
  value       = var.manage_cloudwatch_logs_source ? aws_sns_topic.cloudwatch_logs_source_email["this"].name : ""
  description = "Cloudwatch logs SNS topic source email"
}

output "cloudtrail_common_name" {
  value       = var.manage_cloudtrail_bucket ? aws_cloudtrail.common["this"].name : ""
  description = "AWS Cloudtrail common name"
}
