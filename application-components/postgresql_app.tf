# ********************** App ********************** #
locals {
  postgresql_app_id = "5722da9c-83b3-4c59-bc80-43dc7c50125b"
  postgresql_app_name = "PostgreSQL"
  postgresql_app_description = "This folder is created by Terraform.DO NOT DELETE."
}
resource "null_resource" "install_postgresql_app" {
  count      = contains(local.database_engines_values, "postgresql") ? 1 : 0
  triggers = {
    api_endpoint      = local.sumologic_api_endpoint
    organization      = var.sumologic_organization_id
    solution_version = local.solution_version
  }
  depends_on = [
    sumologic_folder.root_apps_folder
  ]
  provisioner "local-exec" {
    command = <<EOT
      curl -s --request POST '${local.sumologic_api_endpoint}/v1/apps/${local.postgresql_app_id}/install' \
            --header 'Accept: application/json' \
            --header 'Content-Type: application/json' \
            -u ${var.sumologic_access_id}:${var.sumologic_access_key} \
          --data-raw '{ "name": "${local.postgresql_app_name}", "description": "${local.postgresql_app_description}", "destinationFolderId": "${sumologic_folder.root_apps_folder.id}"}}'
    EOT
  }
}
