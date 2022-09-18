# ********************** App ********************** #
locals {
  mongodb_app_id = "2e785ce9-026a-4385-90fb-8640287c2c11"
  mongodb_app_name = "MongoDB"
  mongodb_app_description = "This folder is created by Terraform.DO NOT DELETE."
}
resource "null_resource" "install_mongodb_app" {
  count      = contains(local.database_engines_values, "mongodb") ? 1 : 0
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
      curl -s --request POST '${local.sumologic_api_endpoint}/v1/apps/${local.mongodb_app_id}/install' \
            --header 'Accept: application/json' \
            --header 'Content-Type: application/json' \
            -u ${var.sumologic_access_id}:${var.sumologic_access_key} \
          --data-raw '{ "name": "${local.mongodb_app_name}", "description": "${local.mongodb_app_description}", "destinationFolderId": "${sumologic_folder.root_apps_folder.id}"}}'
    EOT
  }
}
