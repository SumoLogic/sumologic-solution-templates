# ********************** App ********************** #
locals {
  oracle_app_id = "83e571b4-08e9-4b21-a06c-800bb2ef0b4c"
  oracle_app_name = "Oracle"
  oracle_app_description = "This folder is created by Terraform.DO NOT DELETE."
}
resource "null_resource" "install_oracle_app" {
  count      = contains(local.database_engines_values, "oracle") ? 1 : 0
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
      curl -s --request POST '${local.sumologic_api_endpoint}/v1/apps/${local.oracle_app_id}/install' \
            --header 'Accept: application/json' \
            --header 'Content-Type: application/json' \
            -u ${var.sumologic_access_id}:${var.sumologic_access_key} \
          --data-raw '{ "name": "${local.oracle_app_name}", "description": "${local.oracle_app_description}", "destinationFolderId": "${sumologic_folder.root_apps_folder.id}"}}'
    EOT
  }
}
