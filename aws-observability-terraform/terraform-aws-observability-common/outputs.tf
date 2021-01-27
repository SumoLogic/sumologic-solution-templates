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
  value       = aws_sns_topic.alb_source["this"].name
  description = "ALB SNS Topic Name"
}

output "cloudtrail_common_name" {
  value       = aws_cloudtrail.common["this"].name
  description = "AWS Cloudtrail common name"
}
