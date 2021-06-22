# This TF is solely used to create common AWS S3 bucket.
# 1. Create an AWS S3 Bucket.
# 2. Add CloudTrail Policy
# 3. Add ELB policy

resource "aws_s3_bucket" "s3_bucket" {
  for_each = toset(local.create_common_bucket ? ["s3_bucket"] : [])

  bucket        = local.common_bucket_name
  force_destroy = local.common_force_destroy
  acl           = "private"
}

resource "aws_s3_bucket_policy" "cloudtrail_policy" {
  for_each = toset(var.cloudtrail_source_details.bucket_details.create_bucket ? ["cloudtrail_policy"] : [])

  bucket = aws_s3_bucket.s3_bucket["s3_bucket"].id

  policy = templatefile("${path.module}/templates/cloudtrail_bucket_policy.tmpl", {
    BUCKET_NAME = local.common_bucket_name
  })
}

resource "aws_s3_bucket_policy" "elb_policy" {
  for_each = toset(var.elb_source_details.bucket_details.create_bucket ? ["elb_policy"] : [])

  bucket = aws_s3_bucket.s3_bucket["s3_bucket"].id

  policy = templatefile("${path.module}/templates/elb_bucket_policy.tmpl", {
    BUCKET_NAME     = local.common_bucket_name
    ELB_ACCCOUNT_ID = local.region_to_elb_account_id[local.aws_region]
  })
}

resource "aws_sns_topic" "sns_topic" {
  for_each = toset(local.create_common_bucket ? ["sns_topic"] : [])

  name = "SumoLogic-Aws-Observability-Module-${random_string.aws_random.id}"
  policy = templatefile("${path.module}/templates/sns_topic_policy.tmpl", {
    BUCKET_NAME    = local.common_bucket_name,
    AWS_REGION     = local.aws_region,
    SNS_TOPIC_NAME = "SumoLogic-Aws-Observability-Module-${random_string.aws_random.id}",
    AWS_ACCOUNT    = local.aws_account_id
  })
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  for_each = toset(local.create_common_bucket ? ["bucket_notification"] : [])

  bucket = aws_s3_bucket.s3_bucket["s3_bucket"].id

  topic {
    topic_arn = aws_sns_topic.sns_topic["sns_topic"].arn
    events    = ["s3:ObjectCreated:Put"]
  }
}