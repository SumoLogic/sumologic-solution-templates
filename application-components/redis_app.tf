# ********************** App ********************** #
locals {
  redis_app_id          = "a5803cb5-8e23-4f30-a03e-d1c9dfd7fd5e"
  redis_app_name        = "Redis"
  redis_app_description = "This folder is created by Terraform.DO NOT DELETE."
}
resource "null_resource" "install_redis_app" {
  count = contains(local.all_components_values, "redis") ? 1 : 0
  triggers = {
    api_endpoint     = local.sumologic_api_endpoint
    organization     = var.sumologic_organization_id
    solution_version = local.solution_version
    root_folder_id   = local.parent_folder_id
  }
  depends_on = [
    sumologic_folder.admin_root_apps_folder,
    sumologic_folder.personal_root_apps_folder
  ]
  provisioner "local-exec" {
    command = <<EOT
      curl -s --request POST '${local.sumologic_api_endpoint}/v1/apps/${local.redis_app_id}/install' \
            --header 'Accept: application/json' \
            --header 'Content-Type: application/json' \
            --header 'isAdminMode: ${local.is_adminMode}' \
            -u ${var.sumologic_access_id}:${var.sumologic_access_key} \
          --data-raw '{ "name": "${local.redis_app_name}", "description": "${local.redis_app_description}", "destinationFolderId": "${local.parent_folder_id}"}}'
    EOT
  }
}
