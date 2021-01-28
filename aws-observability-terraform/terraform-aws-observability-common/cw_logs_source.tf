resource "sumologic_http_source" "cloudwatch_logs" {
  for_each = toset(var.manage_cloudwatch_logs_source ? ["this"] : [])

  category     = var.cloudwatch_logs_source_category
  collector_id = sumologic_collector.hosted["this"].id
  fields = {
    "account"   = var.account_alias
    "namespace" = "aws/lambda"
    "region"    = data.aws_region.current.id
  }
  name = "${var.account_alias}-${var.cloudwatch_logs_source_name}-${data.aws_region.current.id}"

  depends_on = [aws_iam_role_policy_attachment.sumologic_source]
}

resource "aws_iam_role" "cloudwatch_logs_source_lambda" {
  for_each = toset(var.manage_cloudwatch_logs_source ? ["this"] : [])

  name = "SumoCWLambdaExecutionRole-${data.aws_region.current.id}"
  path = "/"

  assume_role_policy = templatefile("${path.module}/templates/iam/lambda_assume.tmpl", {})
}

resource "aws_iam_policy" "cloudwatch_logs_source_lambda_sqs" {
  for_each = toset(var.manage_cloudwatch_logs_source ? ["this"] : [])

  name   = "SQSCreateLogs-${data.aws_region.current.id}"
  policy = templatefile("${path.module}/templates/iam/cloudwatch_logs_source_lambda_sqs.tmpl", { cloudwatch_logs_source_deadletter_arn = aws_sqs_queue.cloudwatch_logs_source_deadletter["this"].arn })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_logs_source_lambda_sqs" {
  for_each = toset(var.manage_cloudwatch_logs_source ? ["this"] : [])

  role       = aws_iam_role.cloudwatch_logs_source_lambda["this"].name
  policy_arn = aws_iam_policy.cloudwatch_logs_source_lambda_sqs["this"].arn
}

resource "aws_iam_policy" "cloudwatch_logs_source_lambda_logs" {
  for_each = toset(var.manage_cloudwatch_logs_source ? ["this"] : [])

  name   = "CloudWatchCreateLogs-${data.aws_region.current.id}"
  policy = templatefile("${path.module}/templates/iam/cloudwatch_logs_source_lambda_logs.tmpl", { cloudwatch_logs_source_log_group_arn = aws_cloudwatch_log_group.cloudwatch_logs_source["this"].arn })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_logs_source_lambda_logs" {
  for_each = toset(var.manage_cloudwatch_logs_source ? ["this"] : [])

  role       = aws_iam_role.cloudwatch_logs_source_lambda["this"].name
  policy_arn = aws_iam_policy.cloudwatch_logs_source_lambda_logs["this"].arn
}

resource "aws_iam_policy" "cloudwatch_logs_source_lambda_lambda" {
  for_each = toset(var.manage_cloudwatch_logs_source ? ["this"] : [])

  name   = "InvokeLambda-${data.aws_region.current.id}"
  policy = templatefile("${path.module}/templates/iam/cloudwatch_logs_source_lambda_lambda.tmpl", { cloudwatch_logs_source_lambda_arn = aws_lambda_function.cloudwatch_logs_source_process_deadletter["this"].arn })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_logs_source_lambda_lambda" {
  for_each = toset(var.manage_cloudwatch_logs_source ? ["this"] : [])

  role       = aws_iam_role.cloudwatch_logs_source_lambda["this"].name
  policy_arn = aws_iam_policy.cloudwatch_logs_source_lambda_lambda["this"].arn
}

resource "aws_lambda_function" "cloudwatch_logs_source_logs" {
  for_each = toset(var.manage_cloudwatch_logs_source ? ["this"] : [])

  function_name = "SumoCWLogsLambda"
  handler       = "cloudwatchlogs_lambda.handler"
  runtime       = "nodejs10.x"
  role          = aws_iam_role.cloudwatch_logs_source_lambda["this"].arn
  s3_bucket     = "appdevzipfiles-${data.aws_region.current.id}"
  s3_key        = "cloudwatchlogs-with-dlq.zip"
  timeout       = 300

  dead_letter_config {
    target_arn = aws_sqs_queue.cloudwatch_logs_source_deadletter["this"].arn
  }

  environment {
    variables = {
      "SUMO_ENDPOINT"     = sumologic_http_source.cloudwatch_logs["this"].url,
      "LOG_FORMAT"        = var.log_format,
      "INCLUDE_LOG_INFO"  = var.include_log_group_info,
      "LOG_STREAM_PREFIX" = join(",", var.log_stream_prefix)
    }
  }
}

resource "aws_lambda_permission" "cloudwatch_logs_source_logs" {
  for_each = toset(var.manage_cloudwatch_logs_source ? ["this"] : [])

  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.cloudwatch_logs_source_logs["this"].function_name
  principal      = "logs.${data.aws_region.current.id}.amazonaws.com"
  source_account = data.aws_caller_identity.current.id
}

resource "aws_lambda_function" "cloudwatch_logs_source_process_deadletter" {
  for_each = toset(var.manage_cloudwatch_logs_source ? ["this"] : [])

  function_name = "SumoCWProcessDLQLambda"
  handler       = "DLQProcessor.handler"
  runtime       = "nodejs10.x"
  role          = aws_iam_role.cloudwatch_logs_source_lambda["this"].arn
  s3_bucket     = "appdevzipfiles-${data.aws_region.current.id}"
  s3_key        = "cloudwatchlogs-with-dlq.zip"
  timeout       = 300

  dead_letter_config {
    target_arn = aws_sqs_queue.cloudwatch_logs_source_deadletter["this"].arn
  }

  environment {
    variables = {
      "SUMO_ENDPOINT"     = sumologic_http_source.cloudwatch_logs["this"].url,
      "LOG_FORMAT"        = var.log_format,
      "INCLUDE_LOG_INFO"  = var.include_log_group_info,
      "LOG_STREAM_PREFIX" = join(",", var.log_stream_prefix),
      "TASK_QUEUE_URL"    = aws_sqs_queue.cloudwatch_logs_source_deadletter["this"].id,
      "NUM_OF_WORKERS"    = var.workers
    }
  }
}

resource "aws_lambda_permission" "cloudwatch_logs_source_process_deadletter" {
  for_each = toset(var.manage_cloudwatch_logs_source ? ["this"] : [])

  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudwatch_logs_source_process_deadletter["this"].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cloudwatch_logs_source_process_deadletter["this"].arn
}

resource "aws_cloudwatch_event_rule" "cloudwatch_logs_source_process_deadletter" {
  for_each = toset(var.manage_cloudwatch_logs_source ? ["this"] : [])

  description         = "Events rule for Cron"
  name                = "SumoCWProcessDLQSchedule"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "cloudwatch_logs_source_process_deadletter" {
  for_each = toset(var.manage_cloudwatch_logs_source ? ["this"] : [])

  arn       = aws_lambda_function.cloudwatch_logs_source_process_deadletter["this"].arn
  rule      = aws_cloudwatch_event_rule.cloudwatch_logs_source_process_deadletter["this"].name
  target_id = "TargetFunctionV1"

  depends_on = [aws_lambda_permission.cloudwatch_logs_source_process_deadletter]
}

resource "aws_sqs_queue" "cloudwatch_logs_source_deadletter" {
  for_each = toset(var.manage_cloudwatch_logs_source ? ["this"] : [])

  name = "SumoCWDeadLetterQueue"
}

resource "aws_sns_topic" "cloudwatch_logs_source_email" {
  for_each = toset(var.manage_cloudwatch_logs_source ? ["this"] : [])

  name = "SumoCWEmailSNSTopic"
}

/*resource "aws_sns_topic_subscription" "cloudwatch_logs_source_email" {
  for_each = toset(var.manage_cloudwatch_logs_source ? ["this"] : [])

  endpoint  = var.email_id
  protocol  = "email" #TODO: will not work due to no generated arn
  topic_arn = aws_sns_topic.cloudwatch_logs_source_email["this"].arn
}

resource "aws_cloudwatch_metric_alarm" "cloudwatch_logs_source" {
  for_each = toset(var.manage_cloudwatch_logs_source ? ["this"] : [])

  alarm_actions       = [aws_sns_topic.cloudwatch_logs_source_email["this"].arn]
  alarm_description   = "Notify via email if number of messages in DeadLetterQueue exceeds threshold"
  alarm_name          = "SumoCWSpilloverAlarm"
  comparison_operator = "GreaterThanThreshold"
  dimensions          = { "QueueName" = aws_sqs_queue.cloudwatch_logs_source_deadletter["this"].name }
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 3600
  statistic           = "Sum"
  threshold           = 100000
}*/

resource "aws_cloudwatch_log_group" "cloudwatch_logs_source" {
  for_each = toset(var.manage_cloudwatch_logs_source ? ["this"] : [])

  name              = "SumoCWLogGroup"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_subscription_filter" "cloudwatch_logs_source" {
  for_each = toset(var.manage_cloudwatch_logs_source ? ["this"] : [])

  destination_arn = aws_lambda_function.cloudwatch_logs_source_logs["this"].arn
  filter_pattern  = ""
  log_group_name  = aws_cloudwatch_log_group.cloudwatch_logs_source["this"].name
  name            = "SumoCWLogSubscriptionFilter"

  depends_on = [aws_lambda_permission.cloudwatch_logs_source_logs]
}
