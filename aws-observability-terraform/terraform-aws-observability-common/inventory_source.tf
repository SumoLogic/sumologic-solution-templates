resource "sumologic_aws_inventory_source" "this" {
  for_each = toset(var.manage_aws_inventory_source ? ["this"] : [])

  category      = var.aws_inventory_source_category
  collector_id  = sumologic_collector.hosted["this"].id
  content_type  = "AwsInventory"
  description   = "This AwsInventory source is created by AWS SAM Application"
  name          = "${var.account_alias}-${var.aws_inventory_source_name}-${data.aws_region.current.id}"
  paused        = false
  scan_interval = var.scan_interval

  authentication {
    type     = "AWSRoleBasedAuthentication"
    role_arn = aws_iam_role.sumologic_source["this"].arn
  }

  path {
    type                = "AwsInventoryPath"
    limit_to_regions    = [data.aws_region.current.id]
    limit_to_namespaces = concat(var.cloudwatch_metrics_namespaces, ["AWS/AutoScaling"])
  }

  depends_on = [aws_iam_role_policy_attachment.sumologic_inventory["this"]]
}
