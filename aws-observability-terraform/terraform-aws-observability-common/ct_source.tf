resource "sumologic_cloudtrail_source" "this" {
  for_each = toset(var.manage_cloudtrail_logs_source ? ["this"] : [])

  category             = var.cloudtrail_logs_source_category
  collector_id         = sumologic_collector.hosted["this"].id
  content_type         = "AwsCloudTrailBucket"
  cutoff_relative_time = "-1d"
  description          = "This AwsCloudTrailBucket source is created by AWS SAM Application"
  fields               = { "account" = var.account_alias }
  name                 = "${var.account_alias}-${var.cloudtrail_logs_source_name}-${data.aws_region.current.id}"
  paused               = false
  scan_interval        = var.scan_interval

  authentication {
    type     = "AWSRoleBasedAuthentication"
    role_arn = aws_iam_role.sumologic_source["this"].arn
  }

  path {
    type            = "S3BucketPathExpression"
    bucket_name     = var.manage_cloudtrail_bucket ? aws_s3_bucket.common["this"].id : var.cloudtrail_logs_s3_bucket
    path_expression = "AWSLogs/${data.aws_caller_identity.current.id}/CloudTrail/${data.aws_region.current.id}/${var.cloudtrail_s3_bucket_path_expression}"
  }

  depends_on = [aws_iam_role_policy_attachment.sumologic_source, aws_s3_bucket_policy.common]
}

resource "aws_sns_topic" "cloudtrail_source" {
  for_each = toset(local.manage_cloudtrail_sns_topic ? ["this"] : [])

  name = "cloudtrail-sumo-sns-${var.account_alias}"
}

resource "aws_sns_topic_policy" "cloudtrail_source" {
  for_each = toset(local.manage_cloudtrail_sns_topic ? ["this"] : [])

  arn    = aws_sns_topic.cloudtrail_source["this"].arn
  policy = templatefile("${path.module}/templates/sns/policy.tmpl", { bucket_arn = var.manage_cloudtrail_bucket ? aws_s3_bucket.common["this"].arn : "arn:aws:s3:::${var.cloudtrail_logs_s3_bucket}", sns_topic_arn = aws_sns_topic.cloudtrail_source["this"].arn, aws_account = data.aws_caller_identity.current.id })
}

resource "aws_sns_topic_subscription" "cloudtrail_source" {
  for_each = toset(var.manage_cloudtrail_logs_source ? ["this"] : [])

  delivery_policy = jsonencode({
    "guaranteed" = false,
    "healthyRetryPolicy" = {
      "numRetries"         = 40,
      "minDelayTarget"     = 10,
      "maxDelayTarget"     = 300,
      "numMinDelayRetries" = 3,
      "numMaxDelayRetries" = 5,
      "numNoDelayRetries"  = 0,
      "backoffFunction"    = "exponential"
    },
    "sicklyRetryPolicy" = null,
    "throttlePolicy"    = null
  })
  endpoint               = sumologic_cloudtrail_source.this["this"].url
  endpoint_auto_confirms = true
  protocol               = "https"
  topic_arn              = var.manage_cloudtrail_bucket ? aws_sns_topic.common["this"].arn : aws_sns_topic.cloudtrail_source["this"].arn
}
