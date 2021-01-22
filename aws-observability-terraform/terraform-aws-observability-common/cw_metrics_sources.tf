resource "sumologic_cloudwatch_source" "cloudwatch_metrics_sources" {
  for_each = var.manage_cloudwatch_metrics_source ? toset(var.cloudwatch_metrics_namespaces) : []

  category      = var.cloudwatch_metrics_source_category
  collector_id  = sumologic_collector.hosted["this"].id
  content_type  = "AwsCloudWatch"
  description   = "This AwsCloudWatch source is created by AWS SAM Application"
  fields        = { account = var.account_alias }
  name          = "${var.account_alias}-${var.cloudwatch_metrics_source_name}-${data.aws_region.current.id}-${regex("^AWS/(\\w+)$", each.value)[0]}"
  paused        = false
  scan_interval = local.namespace_scan_interval[regex("^AWS/(\\w+)$", each.value)[0]]

  authentication {
    type     = "AWSRoleBasedAuthentication"
    role_arn = aws_iam_role.sumologic_source["this"].arn
  }

  path {
    type                = "CloudWatchPath"
    limit_to_regions    = [data.aws_region.current.id]
    limit_to_namespaces = [each.value]
  }

  depends_on = [aws_iam_role_policy_attachment.sumologic_source]
}
