# This TF is solely used to create common IAM Role
# 1. Create an IAM role with assume role policy to trust sumologic org.
# 2. Add CloudTrail Policy
# 3. Add ELB policy
# 4. Add CloudWatch metrics policy
# 5. Add Root Cause sources policy

resource "aws_iam_role" "sumologic_iam_role" {
  for_each = toset(local.create_iam_role ? ["sumologic_iam_role"] : [])

  name = "SumoLogic-Aws-Observability-Module-${random_string.aws_random.id}"
  path = "/"

  assume_role_policy = templatefile("${path.module}/templates/iam_assume_role_policy.tmpl", {
    SUMO_LOGIC_ACCOUNT_ID = local.sumo_account_id,
    ENVIRONMENT           = data.sumologic_caller_identity.current.environment,
    SUMO_LOGIC_ORG_ID     = var.sumologic_organization_id
  })
}

# Sumo Logic CloudTrail Source Policy Attachment
resource "aws_iam_policy" "cloudtrail_policy" {
  for_each = toset(var.collect_cloudtrail_logs && local.create_iam_role ? ["cloudtrail_policy"] : [])

  policy = templatefile("${path.module}/templates/iam_s3_source_policy.tmpl", {
    POLICY_NAME = "CloudTrailSourcePolicy"
    BUCKET_NAME = local.create_common_bucket ? local.common_bucket_name : var.cloudtrail_source_details.bucket_details.bucket_name
  })
}

resource "aws_iam_role_policy_attachment" "cloudtrail_policy_attach" {
  for_each = toset(var.collect_cloudtrail_logs && local.create_iam_role ? ["cloudtrail_policy_attach"] : [])

  policy_arn = aws_iam_policy.cloudtrail_policy["cloudtrail_policy"].arn
  role       = aws_iam_role.sumologic_iam_role["sumologic_iam_role"].arn
}

# Sumo Logic ELB Source Policy Attachment
resource "aws_iam_policy" "elb_policy" {
  for_each = toset(var.collect_elb_logs && local.create_iam_role ? ["elb_policy"] : [])

  policy = templatefile("${path.module}/templates/iam_s3_source_policy.tmpl", {
    POLICY_NAME = "ElbSourcePolicy"
    BUCKET_NAME = local.create_common_bucket ? local.common_bucket_name : var.elb_source_details.bucket_details.bucket_name
  })
}

resource "aws_iam_role_policy_attachment" "elb_policy_attach" {
  for_each = toset(var.collect_elb_logs && local.create_iam_role ? ["elb_policy_attach"] : [])

  policy_arn = aws_iam_policy.elb_policy["elb_policy"].arn
  role       = aws_iam_role.sumologic_iam_role["sumologic_iam_role"].arn
}

# Sumo Logic CloudWatch Metrics Source Policy Attachment
resource "aws_iam_policy" "cw_metrics_policy" {
  for_each = toset(local.create_metric_source && local.create_iam_role ? ["cw_metrics_policy"] : [])

  policy = templatefile("${path.module}/templates/iam_cw_metrics_source_policy.tmpl", {})
}

resource "aws_iam_role_policy_attachment" "cw_metrics_policy_attach" {
  for_each = toset(local.create_metric_source && local.create_iam_role ? ["cw_metrics_policy_attach"] : [])

  policy_arn = aws_iam_policy.cw_metrics_policy["cw_metrics_policy"].arn
  role       = aws_iam_role.sumologic_iam_role["sumologic_iam_role"].arn
}