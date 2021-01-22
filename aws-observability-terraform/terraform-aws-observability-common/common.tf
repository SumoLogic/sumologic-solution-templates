resource "aws_sns_topic" "common" {
  for_each = toset(local.manage_target_s3_bucket ? ["this"] : [])

  name = "sumo-sns-topic-${var.account_alias}"
}

resource "aws_sns_topic_policy" "common" {
  for_each = toset(local.manage_target_s3_bucket ? ["this"] : [])

  arn    = aws_sns_topic.common["this"].arn
  policy = templatefile("${path.module}/templates/sns/policy.tmpl", { bucket_arn = aws_s3_bucket.common["this"].arn, sns_topic_arn = aws_sns_topic.common["this"].arn, aws_account = data.aws_caller_identity.current.id })
}

resource "aws_s3_bucket" "common" {
  for_each = toset(local.manage_target_s3_bucket ? ["this"] : [])

  bucket = "aws-observability-logs-${var.account_alias}-${data.aws_region.current.id}"
  #force_delete = true
}

resource "aws_s3_bucket_notification" "common" {
  for_each = toset(local.manage_target_s3_bucket ? ["this"] : [])

  bucket = aws_s3_bucket.common["this"].id

  topic {
    topic_arn = aws_sns_topic.common["this"].arn
    events    = ["s3:ObjectCreated:Put"]
  }
}

resource "aws_s3_bucket_policy" "common" {
  for_each = toset(local.manage_target_s3_bucket ? ["this"] : [])

  bucket = aws_s3_bucket.common["this"].id
  policy = templatefile("${path.module}/templates/s3/common.tmpl", { common_s3_bucket_arn = aws_s3_bucket.common["this"].arn, elb_account_id = local.region_to_elb_account_id[data.aws_region.current.id] })
}

resource "aws_cloudtrail" "common" {
  for_each = toset(var.manage_cloudtrail_bucket ? ["this"] : [])

  include_global_service_events = false
  name                          = "Aws-Observability-${var.account_alias}"
  s3_bucket_name                = aws_s3_bucket.common["this"].id

  depends_on = [aws_s3_bucket_policy.common]
}
