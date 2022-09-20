# ********************** App ********************** #
locals {
  mariadb_app_id          = "6a41c72f-fc02-47c6-a5fe-bc58bd4af50f"
  mariadb_app_name        = "MariaDB"
  mariadb_app_description = "This folder is created by Terraform.DO NOT DELETE."
}
resource "null_resource" "install_mariadb_app" {
  count = contains(local.all_components_values, "mariadb") ? 1 : 0
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
      curl -s --request POST '${local.sumologic_api_endpoint}/v1/apps/${local.mariadb_app_id}/install' \
            --header 'Accept: application/json' \
            --header 'Content-Type: application/json' \
            -u ${var.sumologic_access_id}:${var.sumologic_access_key} \
          --data-raw '{ "name": "${local.mariadb_app_name}", "description": "${local.mariadb_app_description}", "destinationFolderId": "${sumologic_folder.root_apps_folder.id}"}}'
    EOT
  }
}
