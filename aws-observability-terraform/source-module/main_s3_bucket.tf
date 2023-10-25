# This TF is solely used to create common AWS S3 bucket.
# 1. Create an AWS S3 Bucket.
# 2. Add CloudTrail Policy
# 3. Add ELB policy

resource "aws_s3_bucket" "s3_bucket" {
  for_each = toset(local.create_common_bucket ? ["s3_bucket"] : [])

  bucket        = local.common_bucket_name
  force_destroy = local.common_force_destroy
}

resource "aws_s3_bucket_policy" "dump_access_logs_to_s3" {
  bucket = aws_s3_bucket.s3_bucket["s3_bucket"].id
  policy = templatefile("${path.module}/templates/s3_bucket_policy.tmpl", {
    BUCKET_NAME     = local.common_bucket_name
    ELB_ACCCOUNT_ID = local.region_to_elb_account_id[local.aws_region]
  })
}

# Default s3 bucket acl is private, if you want to update uncomment the following block
# For more details refer https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl
# resource "aws_s3_bucket_acl" "s3_bucket_acl" {
#   for_each = toset(local.create_common_bucket ? ["s3_bucket_acl"] : [])
#   bucket = aws_s3_bucket.s3_bucket["s3_bucket"].id
#   acl    = "private"
# }

resource "aws_sns_topic" "sns_topic" {
  for_each = toset(local.create_common_sns_topic ? ["sns_topic"] : [])

  name = "SumoLogic-Aws-Observability-Module-${random_string.aws_random.id}"
  policy = templatefile("${path.module}/templates/sns_topic_policy.tmpl", {
    BUCKET_NAME    = local.common_bucket_name,
    AWS_REGION     = local.aws_region,
    SNS_TOPIC_NAME = "SumoLogic-Aws-Observability-Module-${random_string.aws_random.id}",
    AWS_ACCOUNT    = local.aws_account_id
  })
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  for_each = toset(local.create_common_sns_topic ? ["bucket_notification"] : [])

  bucket = aws_s3_bucket.s3_bucket["s3_bucket"].id

  topic {
    topic_arn = aws_sns_topic.sns_topic["sns_topic"].arn
    events    = ["s3:ObjectCreated:Put"]
  }
}