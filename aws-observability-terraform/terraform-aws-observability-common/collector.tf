resource "sumologic_collector" "hosted" {
  for_each = toset(local.manage_collector ? ["this"] : [])

  name     = "${var.collector_name}-${var.account_alias}"
  timezone = "UTC"
}

#TODO: convert to null resource
/*CreateSumoLogicAWSExplorerView:
  Type: Custom::SumoLogicAWSExplorer
  Properties:
    HierarchyName: "AWS Observability"
    HierarchyLevel: {"entityType":"account","nextLevelsWithConditions":[],"nextLevel":{"entityType":"region","nextLevelsWithConditions":[],"nextLevel":{"entityType":"namespace","nextLevelsWithConditions":[{"condition":"AWS/ApplicationElb","level":{"entityType":"loadbalancer","nextLevelsWithConditions":[]}},{"condition":"AWS/ApiGateway","level":{"entityType":"apiname","nextLevelsWithConditions":[]}},{"condition":"AWS/DynamoDB","level":{"entityType":"tablename","nextLevelsWithConditions":[]}},{"condition":"AWS/EC2","level":{"entityType":"instanceid","nextLevelsWithConditions":[]}},{"condition":"AWS/RDS","level":{"entityType":"dbidentifier","nextLevelsWithConditions":[]}},{"condition":"AWS/Lambda","level":{"entityType":"functionname","nextLevelsWithConditions":[]}}]}}}*/

resource "aws_iam_role" "sumologic_source" {
  for_each = toset(local.manage_sumologic_source_role ? ["this"] : [])

  #TODO: current sumologic workaround replication; later best practices
  name = "SumoLogicSource-${data.aws_region.current.id}"
  path = "/"

  assume_role_policy = templatefile("${path.module}/templates/iam/sumologic_assume.tmpl", { sumologic_environment = var.sumologic_environment, sumologic_organization_id = var.sumologic_organization_id })
}

resource "aws_iam_policy" "sumologic_source" {
  for_each = toset(local.manage_sumologic_source_role ? ["this"] : [])

  #TODO: current sumologic workaround replication; later best practices
  name   = "SumoLogicAwsSources-${data.aws_region.current.id}"
  policy = templatefile("${path.module}/templates/iam/sumologic_source.tmpl", {})
}

resource "aws_iam_role_policy_attachment" "sumologic_source" {
  for_each = toset(local.manage_sumologic_source_role ? ["this"] : [])

  role       = aws_iam_role.sumologic_source["this"].name
  policy_arn = aws_iam_policy.sumologic_source["this"].arn
}

resource "aws_iam_policy" "sumologic_inventory" {
  for_each = toset((local.manage_sumologic_source_role && var.manage_aws_inventory_source) ? ["this"] : [])

  #TODO: current sumologic workaround replication; later best practices
  name   = "SumoInventory-${data.aws_region.current.id}"
  policy = templatefile("${path.module}/templates/iam/sumologic_inventory.tmpl", {})
}

resource "aws_iam_role_policy_attachment" "sumologic_inventory" {
  for_each = toset((local.manage_sumologic_source_role && var.manage_aws_inventory_source) ? ["this"] : [])

  role       = aws_iam_role.sumologic_source["this"].name
  policy_arn = aws_iam_policy.sumologic_inventory["this"].arn
}
