# ********************** App ********************** #
locals {
  cassandra_app_id = "e98f457e-ec29-4b26-8477-f371424d37a5"
  cassandra_app_name = "Cassandra"
  cassandra_app_description = "This folder is created by Terraform.DO NOT DELETE."
}
resource "null_resource" "install_cassandra_app" {
  count      = contains(local.database_engines_values, "cassandra") ? 1 : 0
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
      curl -s --request POST '${local.sumologic_api_endpoint}/v1/apps/${local.cassandra_app_id}/install' \
            --header 'Accept: application/json' \
            --header 'Content-Type: application/json' \
            -u ${var.sumologic_access_id}:${var.sumologic_access_key} \
          --data-raw '{ "name": "${local.cassandra_app_name}", "description": "${local.cassandra_app_description}", "destinationFolderId": "${sumologic_folder.root_apps_folder.id}"}}'
    EOT
  }
}
