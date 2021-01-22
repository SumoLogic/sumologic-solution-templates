resource "sumologic_elb_source" "this" {
  for_each = toset(var.manage_alb_logs_source ? ["this"] : [])

  category             = var.alb_logs_source_category
  collector_id         = sumologic_collector.hosted["this"].id
  content_type         = "AwsElbBucket"
  cutoff_relative_time = "-1d"
  description          = "This AwsElbBucket source is created by AWS SAM Application"
  fields = {
    "account"   = var.account_alias
    "namespace" = "aws/applicationelb"
    "region"    = data.aws_region.current.id
  }
  name          = "${var.account_alias}-${var.alb_logs_source_name}-${data.aws_region.current.id}"
  paused        = false
  scan_interval = var.scan_interval

  authentication {
    type     = "AWSRoleBasedAuthentication"
    role_arn = aws_iam_role.sumologic_source["this"].arn
  }

  path {
    type            = "S3BucketPathExpression"
    bucket_name     = var.manage_alb_s3_bucket ? aws_s3_bucket.common["this"].id : var.alb_s3_bucket
    path_expression = "*AWSLogs/*/elasticloadbalancing/${var.alb_s3_bucket_path_expression}"
  }

  depends_on = [aws_iam_role_policy_attachment.sumologic_source, aws_s3_bucket_policy.common] #TODO: problem if not managing role or bucket? same for other four sources
}

resource "aws_sns_topic" "alb_source" {
  for_each = toset(var.manage_alb_logs_source ? ["this"] : [])

  name = "alb-sumo-sns-${var.account_alias}"
}

resource "aws_sns_topic_policy" "alb_source" {
  for_each = toset(var.manage_alb_logs_source ? ["this"] : [])

  arn    = aws_sns_topic.alb_source["this"].arn
  policy = templatefile("${path.module}/templates/sns/policy.tmpl", { bucket_arn = var.manage_alb_s3_bucket ? aws_s3_bucket.common["this"].arn : "arn:aws:s3:::${var.alb_s3_bucket}", sns_topic_arn = aws_sns_topic.alb_source["this"].arn, aws_account = data.aws_caller_identity.current.id })
}

resource "aws_sns_topic_subscription" "alb_source" {
  for_each = toset(var.manage_alb_logs_source ? ["this"] : [])

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
  endpoint               = sumologic_elb_source.this["this"].url
  endpoint_auto_confirms = true
  protocol               = "https"
  topic_arn              = var.manage_alb_s3_bucket ? aws_sns_topic.common["this"].arn : aws_sns_topic.alb_source["this"].arn
}
