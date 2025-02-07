module "rce_module" {
  # source = "SumoLogic/sumo-logic-integrations/sumologic//sumologic"
  source = "git::https://github.com/SumoLogic/terraform-sumologic-sumo-logic-integrations.git//sumologic?ref=SUMO-254952"

  access_id   = var.access_id
  access_key  = var.access_key
  environment = var.environment

  # ********************** No Metric Rules for RCE ********************** #

  # ********************** No Fields for RCE ********************** #

  # ********************** No FERs for RCE ********************** #

  # ********************** Apps - RCE dashboards only ********************** #
  # managed_apps = {
  #   "RceApp" = {
  #     content_json = join("", [var.json_file_directory_path, "/aws-observability/json/Rce-App.json"])
  #     folder_id    = var.app_folder_id
  #   }
  # }

  # ********************** Monitors ********************** #
}

# ********************** Install App from App Catalog ********************** #
locals {
  api_endpoint    = var.environment == "us1" ? "https://api.sumologic.com/api" : "https://api.${var.environment}.sumologic.com/api"
  app_name        = "Global Intelligence for CloudTrail DevOps"
  app_description = "Global Intelligence for AWS CloudTrail - DevOps helps infrastructure engineers configure managed AWS services for outage-resistance and on-call staff to accelerate RCA for incidents by providing insights sourced from error rates and config practices."
  app_id          = "c7e195de-f169-460a-8e8b-7bb23af0ee5e"
  app_datasource  = jsonencode({ "CloudTrailLogSrc" : "account=* eventSource" })
}
resource "null_resource" "SumoLogicCatalogApps" {
  triggers = {
    app_name        = local.app_name
    app_description = local.app_description
    app_id          = local.app_id
    app_datasource  = local.app_datasource
    access_id       = var.access_id
    access_key      = var.access_key
    api_endpoint    = local.api_endpoint
    folder_id       = var.app_folder_id
  }

  provisioner "local-exec" {
    when    = create
    command = <<EOT
        curl -s --request POST '${local.api_endpoint}/v1/apps/${local.app_id}/install' \
            --header 'Accept: application/json' \
            --header 'Content-Type: application/json' \
            -u ${var.access_id}:${var.access_key} \
            --data-raw '{"name": "${self.triggers.app_name}", "description": "${self.triggers.app_description}", "destinationFolderId": "${var.app_folder_id}", "dataSourceValues": ${self.triggers.app_datasource}}'
    EOT
  }
}