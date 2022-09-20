# ********************** App ********************** #
locals {
  sqlserver_app_id          = "208123e2-6546-49c6-9b99-829d9b2f8c88"
  sqlserver_app_name        = "SQL Server"
  sqlserver_app_description = "This folder is created by Terraform.DO NOT DELETE."
}
resource "null_resource" "install_sqlserver_app" {
  count = contains(local.all_components_values, "sqlserver") ? 1 : 0
  triggers = {
    api_endpoint     = local.sumologic_api_endpoint
    organization     = var.sumologic_organization_id
    solution_version = local.solution_version
  }
  depends_on = [
    sumologic_folder.root_apps_folder
  ]
  provisioner "local-exec" {
    command = <<EOT
      curl -s --request POST '${local.sumologic_api_endpoint}/v1/apps/${local.sqlserver_app_id}/install' \
            --header 'Accept: application/json' \
            --header 'Content-Type: application/json' \
            -u ${var.sumologic_access_id}:${var.sumologic_access_key} \
          --data-raw '{ "name": "${local.sqlserver_app_name}", "description": "${local.sqlserver_app_description}", "destinationFolderId": "${sumologic_folder.root_apps_folder.id}"}}'
    EOT
  }
}
