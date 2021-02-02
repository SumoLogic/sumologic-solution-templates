resource "sumologic_metadata_source" "this" {
  for_each = toset(var.manage_metadata_source ? ["this"] : [])

  category      = var.metadata_source_category
  collector_id  = sumologic_collector.hosted["this"].id
  content_type  = "AwsMetadata"
  name          = "${var.account_alias}-${var.metadata_source_name}-${data.aws_region.current.id}"
  paused        = false
  scan_interval = var.scan_interval

  authentication {
    type     = "AWSRoleBasedAuthentication"
    role_arn = aws_iam_role.sumologic_source["this"].arn
  }

  path {
    type                = "AwsMetadataPath"
    limit_to_namespaces = ["AWS/EC2"]
    limit_to_regions    = [data.aws_region.current.id]
  }

  depends_on = [aws_iam_role_policy_attachment.sumologic_source]
}

#TODO: combo into single external data
resource "null_resource" "enterprise_check" {
  triggers = {
    sumologic_access_id   = var.sumologic_access_id
    sumologic_access_key  = var.sumologic_access_key
    sumologic_environment = var.sumologic_environment
    section               = "Account|${terraform.workspace}"
  }

  provisioner "local-exec" {
    command = "python3 ${path.module}/src/main.py"
    environment = {
      ResourceType   = "EnterpriseOrTrialAccountCheck"
      Section        = self.triggers.section
      KeyPrefix      = "1"
      SumoAccessID   = self.triggers.sumologic_access_id
      SumoAccessKey  = self.triggers.sumologic_access_key
      SumoDeployment = self.triggers.sumologic_environment
    }
  }
}

data "external" "sumologic_account" {
  program = ["python3", "${path.module}/src/fetchdata.py"]
  query = {
    Section   = "Account|${terraform.workspace}"
    KeyPrefix = "1"
    Key       = "EnterpriseOrTrialAccountCheck"
  }

  depends_on = [null_resource.enterprise_check]
}
