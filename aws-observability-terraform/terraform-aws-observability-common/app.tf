# TODO: try to fix up
resource "null_resource" "install_apps" {
  for_each = var.managed_apps

  triggers = {
    app_json_s3_url          = "https://${var.app_bucket}.s3.amazonaws.com/aws-observability-versions/${each.value.config_version}/appjson/${each.value.json}.json"
    app_name                 = "AWS Observability Overview App ${each.key}"
    folder_name              = "Sumo Logic AWS Observability Apps"
    region                   = data.aws_region.current.id
    retain_old_app_on_update = true
    section                  = "${each.key}|${terraform.workspace}"
    sumologic_access_id      = var.sumologic_access_id
    sumologic_access_key     = var.sumologic_access_key
    sumologic_environment    = var.sumologic_environment
    version                  = each.value.app_version
  }

  provisioner "local-exec" {
    command = "python3 ${path.module}/src/main.py"
    environment = {
      ResourceType         = "App"
      Section              = self.triggers.section
      KeyPrefix            = "1"
      AppName              = self.triggers.app_name
      FolderName           = self.triggers.folder_name
      RetainOldAppOnUpdate = self.triggers.retain_old_app_on_update
      Region               = self.triggers.region
      AppJsonS3Url         = self.triggers.app_json_s3_url
      SumoAccessID         = self.triggers.sumologic_access_id
      SumoAccessKey        = self.triggers.sumologic_access_key
      SumoDeployment       = self.triggers.sumologic_environment
      Version              = self.triggers.version
    }
  }
}
