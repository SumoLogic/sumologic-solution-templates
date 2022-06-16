module "overview_module" {
  source = "SumoLogic/sumo-logic-integrations/sumologic//sumologic"

  access_id   = var.access_id
  access_key  = var.access_key
  environment = var.environment

  # ********************** No Metric Rules for Overview ********************** #

  # ********************** Fields ********************** #
  # managed_fields = {
  #   "account" = {
  #     field_name = "account"
  #     data_type  = "String"
  #     state      = true
  #   },
  #   "region" = {
  #     field_name = "region"
  #     data_type  = "String"
  #     state      = true
  #   },
  #   "namespace" = {
  #     field_name = "namespace"
  #     data_type  = "String"
  #     state      = true
  #   },
  #   "accountId" = {
  #     field_name = "accountid"
  #     data_type  = "String"
  #     state      = true
  #   }
  # }

  # ********************** No FERs for Overview ********************** #

  # ********************** Apps - Account and Region Level dashboards only ********************** #
  managed_apps = {
    "OverviewApp" = {
      content_json = join("", [var.json_file_directory_path, "/aws-observability/json/Overview-App.json"])
      folder_id    = var.app_folder_id
    }
  }

  # ********************** Monitors ********************** #
}

# ********************** Create Explore Hierarchy ********************** #
# locals {
#   api_endpoint      = var.environment == "us1" ? "https://api.sumologic.com/api" : "https://api.${var.environment}.sumologic.com/api"
#   hierarchy_name    = "AWS Observability"
#   hierarchy_level   = jsonencode({ "entityType": "account","nextLevelsWithConditions": [ ],"nextLevel": { "entityType": "region","nextLevelsWithConditions": [ ],"nextLevel": { "entityType": "namespace","nextLevelsWithConditions": [ { "condition": "AWS/ApplicationElb","level": { "entityType": "loadbalancer","nextLevelsWithConditions": [ ] } },{ "condition": "AWS/ApiGateway","level": { "entityType": "apiname","nextLevelsWithConditions": [ ] } },{ "condition": "AWS/DynamoDB","level": { "entityType": "tablename","nextLevelsWithConditions": [ ] } },{ "condition": "AWS/EC2","level": { "entityType": "instanceid","nextLevelsWithConditions": [ ] } },{ "condition": "AWS/RDS","level": { "entityType": "dbidentifier","nextLevelsWithConditions": [ ] } },{ "condition": "AWS/Lambda","level": { "entityType": "functionname","nextLevelsWithConditions": [ ] } },{ "condition": "AWS/ECS","level": { "entityType": "clustername","nextLevelsWithConditions": [ ] } },{ "condition": "AWS/ElastiCache","level": { "entityType": "cacheclusterid","nextLevelsWithConditions": [ ] } },{ "condition": "AWS/NetworkELB","level": { "entityType": "networkloadbalancer","nextLevelsWithConditions": [ ] } } ] } } })
# }
# resource "null_resource" "SumoLogicExploreHierarchy" {
#   triggers = {
#     api_endpoint      = local.api_endpoint
#     hierarchy_name    = local.hierarchy_name
#     hierarchy_level   = local.hierarchy_level
#     access_id         = var.access_id
#     access_key        = var.access_key
#   }

#   provisioner "local-exec" {
#     when    = create
#     command = <<EOT
#         curl -s --request POST '${local.api_endpoint}/v1/entities/hierarchies' \
#             --header 'Accept: application/json' \
#             --header 'Content-Type: application/json' \
#             -u ${var.access_id}:${var.access_key} \
#             --data-raw '{"name": "${self.triggers.hierarchy_name}", "filter": null, "level": ${self.triggers.hierarchy_level}}'
#     EOT
#   }
#}