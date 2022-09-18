# ********************** App ********************** #
locals {
  elasticsearch_app_id = "c1d6cc61-6b12-4404-beb0-928ed6935d88"
  elasticsearch_app_name = "Elasticsearch"
  elasticsearch_app_description = "This folder is created by Terraform.DO NOT DELETE."
}
resource "null_resource" "install_elasticsearch_app" {
  count      = contains(local.database_engines_values, "elasticsearch") ? 1 : 0
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
      curl -s --request POST '${local.sumologic_api_endpoint}/v1/apps/${local.elasticsearch_app_id}/install' \
            --header 'Accept: application/json' \
            --header 'Content-Type: application/json' \
            -u ${var.sumologic_access_id}:${var.sumologic_access_key} \
          --data-raw '{ "name": "${local.elasticsearch_app_name}", "description": "${local.elasticsearch_app_description}", "destinationFolderId": "${sumologic_folder.root_apps_folder.id}"}}'
    EOT
  }
}
