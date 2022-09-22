# ********************** App ********************** #
locals {
  cassandra_app_id          = "e98f457e-ec29-4b26-8477-f371424d37a5"
  cassandra_app_name        = "Cassandra"
  cassandra_app_description = "This folder is created by Terraform.DO NOT DELETE."
}

resource "null_resource" "install_cassandra_app" {
  count = contains(local.all_components_values, "cassandra") ? 1 : 0
  triggers = {
    api_endpoint     = local.sumologic_api_endpoint
    organization     = var.sumologic_organization_id
    solution_version = local.solution_version
    root_folder_id   = local.parent_folder_id
  }
  # Wrong assumption - If there is an update to root_apps_folder then there will always be an automatic update to install_cassandra_app since it's a dependency.
  # But that is not actually how Terraform works, by design: the dependency edges are used for ordering, but the direct attribute values are used for diffing.
  depends_on = [
    sumologic_folder.admin_root_apps_folder,
    sumologic_folder.personal_root_apps_folder
  ]
  provisioner "local-exec" {
    command = <<EOT
      curl -s --request POST '${local.sumologic_api_endpoint}/v1/apps/${local.cassandra_app_id}/install' \
            --header 'Accept: application/json' \
            --header 'Content-Type: application/json' \
            --header 'isAdminMode: ${local.is_adminMode}' \
            -u ${var.sumologic_access_id}:${var.sumologic_access_key} \
          --data-raw '{ "name": "${local.cassandra_app_name}", "description": "${local.cassandra_app_description}", "destinationFolderId": "${local.parent_folder_id}"}}'
    EOT
  }
}
