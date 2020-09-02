# This script creates Sumo Logic Collector and Sources for Atlassian Systems.
# Configure the Sumo Logic credentials in the sumologic.auto.tvars.

# Sumo Logic Provider
provider "sumologic" {
  access_id   = var.sumo_access_id
  access_key  = var.sumo_access_key
  environment = var.deployment
}

# Create/Delete Collector
resource "sumologic_collector" "atlassian_collector" {
  name     = var.collector_name
  category = "Atlassian"
}

# Create/Delete Jira Cloud Source
resource "sumologic_http_source" "jira_cloud" {
  count        = "${var.install_jira_cloud}" ? 1 : 0
  name         = "Jira Cloud"
  category     = var.jira_cloud_sc
  collector_id = sumologic_collector.atlassian_collector.id
}

# Create/Delete BitBucket Cloud Source
resource "sumologic_http_source" "bitbucket_cloud" {
  count        = "${var.install_bitbucket_cloud}" ? 1 : 0
  name         = "Bitbucket Cloud"
  category     = var.bitbucket_sc
  fields       = { "_convertHeadersToFields" = "true" }
  collector_id = sumologic_collector.atlassian_collector.id
}

# Create/Delete Jira Server Source
resource "sumologic_http_source" "jira_server" {
  count        = "${var.install_jira_server}" ? 1 : 0
  name         = "Jira Server"
  category     = var.jira_server_sc
  collector_id = sumologic_collector.atlassian_collector.id
}

# Create/Delete OpsGenie Source
resource "sumologic_http_source" "opsgenie" {
  count        = "${var.install_opsgenie}" ? 1 : 0
  name         = "OpsGenie"
  category     = var.opsgenie_sc
  collector_id = sumologic_collector.atlassian_collector.id
}

# Sumo Logic - Create/Delete folder for installing the applications
data "sumologic_personal_folder" "personalFolder" {}

# Generate timestamp to add to the folder name.
locals {
  time_stamp = formatdate("DD-MMM-YYYY hh:mm:ss",timestamp())
}

resource "sumologic_folder" "folder" {
  name        = "${var.app_installation_folder} - ${local.time_stamp}"
  description = "Atlassian Applications"
  parent_id   = data.sumologic_personal_folder.personalFolder.id
  depends_on  = [sumologic_collector.atlassian_collector]
}

# Remove slash from Sumo Logic sumo_api_endpoint

locals {
  sumo_api_endpoint_fixed = replace(var.sumo_api_endpoint, "api/", "api")
}

# Install Apps
# Install Jira Cloud
resource "null_resource" "install_jira_cloud_app" {
  count      = "${var.install_jira_cloud}" ? 1 : 0
  depends_on = [sumologic_http_source.jira_cloud]

  provisioner "local-exec" {
    command = <<EOT
        curl -s --request POST '${local.sumo_api_endpoint_fixed}/v1/apps/019757ca-3b08-457c-bd15-7239f1ab66c9/install' \
            --header 'Accept: application/json' \
            --header 'Content-Type: application/json' \
            -u ${var.sumo_access_id}:${var.sumo_access_key} \
            --data-raw '{ "name": "Jira Cloud", "description": "The Sumo Logic App for Jira Cloud provides insights into project management issues that enable you to more effectively plan, assign, track, report, and manage work across multiple teams.", "destinationFolderId": "${sumologic_folder.folder.id}","dataSourceValues": {"jiralogsrc": "_sourceCategory = ${var.jira_cloud_sc}" }}'
    EOT
  }
}

# Install Jira Server
resource "null_resource" "install_jira_server_app" {
  count      = "${var.install_jira_server}" ? 1 : 0
  depends_on = [sumologic_http_source.jira_server]

  provisioner "local-exec" {
    command = <<EOT
        curl -s --request POST '${local.sumo_api_endpoint_fixed}/v1/apps/ec905b32-e514-4c63-baac-0efa3b3a2109/install' \
            --header 'Accept: application/json' \
            --header 'Content-Type: application/json' \
            -u ${var.sumo_access_id}:${var.sumo_access_key} \
            --data-raw '{ "name": "Jira", "description": "The Sumo Logic App for Jira provides insight into Jira usage, request activity, issues, security, sprint events, and user events.", "destinationFolderId": "${sumologic_folder.folder.id}","dataSourceValues": {"jiralogsrc": "_sourceCategory = ${var.jira_server_access_logs_sourcecategory}", "jirawebhooklogsrc": "_sourceCategory = ${var.jira_server_sc}" }}'
    EOT
  }
}

# Install Bitbucket
resource "null_resource" "install_bitbucket_cloud_app" {
  count      = "${var.install_bitbucket_cloud}" ? 1 : 0
  depends_on = [sumologic_http_source.bitbucket_cloud]

  provisioner "local-exec" {
    command = <<EOT
        curl -s --request POST '${local.sumo_api_endpoint_fixed}/v1/apps/3b068c67-069e-417e-a855-ff7549a0606d/install' \
            --header 'Accept: application/json' \
            --header 'Content-Type: application/json' \
            -u ${var.sumo_access_id}:${var.sumo_access_key} \
            --data-raw '{ "name": "Bitbucket", "description": "The Sumo Logic App for Bitbucket provides insights into project management to more effectively plan the deployments.", "destinationFolderId": "${sumologic_folder.folder.id}","dataSourceValues": {"bblogsrc": "_sourceCategory = ${var.bitbucket_sc}" }}'
    EOT
  }
}

# Install Opsgenie
resource "null_resource" "install_Opsgenie_app" {
  count      = "${var.install_opsgenie}" ? 1 : 0
  depends_on = [sumologic_http_source.opsgenie]

  provisioner "local-exec" {
    command = <<EOT
        curl -s --request POST '${local.sumo_api_endpoint_fixed}/v1/apps/05bf2074-0487-486f-8359-3d878fbc1c49/install' \
            --header 'Accept: application/json' \
            --header 'Content-Type: application/json' \
            -u ${var.sumo_access_id}:${var.sumo_access_key} \
            --data-raw '{ "name": "Opsgenie", "description": "The Opsgenie App provides at-a-glance views and detailed analytics for alerts on your DevOps environment.", "destinationFolderId": "${sumologic_folder.folder.id}","dataSourceValues": {"opsgenieLogSrc": "_sourceCategory = ${var.opsgenie_sc}" }}'
    EOT
  }
}

# Install Atlassian Solution App
resource "null_resource" "install_atlassian_app" {
  count = "${var.install_atlassian_app}" ? 1 : 0
  #depends_on = [sumologic_http_source.opsgenie]

  provisioner "local-exec" {
    command = <<EOT
        curl -s --request POST '${local.sumo_api_endpoint_fixed}/v1/apps/332afd45-eb37-4d65-85b5-21eaead37f6b/install' \
            --header 'Accept: application/json' \
            --header 'Content-Type: application/json' \
            -u ${var.sumo_access_id}:${var.sumo_access_key} \
            --data-raw '{ "name": "Atlassian", "description": "The Atlassian App provides insights into critical data across Atlassian applications, including Jira Cloud, Jira Server, Bitbucket, Atlassian Access, and OpsGenie from one pane-of-glass in a seamless dashboard experience.", "destinationFolderId": "${sumologic_folder.folder.id}","dataSourceValues": {"oglogsrc": "_sourceCategory = ${var.opsgenie_sc}","jiralogsrc": "(_sourceCategory = ${var.jira_cloud_sc} or _sourceCategory = ${var.jira_server_sc})","bblogsrc": "_sourceCategory = ${var.bitbucket_sc}" }}'
    EOT
  }
}

# Create/Delete Sumo Logic to OpsGenie Webhook i.e. Connection in Sumo Logic by calling REST API
# https://help.sumologic.com/Manage/Connections-and-Integrations/Webhook-Connections/Webhook_Connection_for_Opsgenie
provider "restapi" {
  alias = "sumo"
  uri   = var.sumo_api_endpoint
  # debug                = true
  write_returns_object = true
  username             = var.sumo_access_id
  password             = var.sumo_access_key
  headers              = { Content-Type = "application/json" }
}

# Create/Delete Field required by BitBucket App in Sumo Logic by calling REST API
resource "restapi_object" "bitbucket_field" {
  provider     = restapi.sumo
  count        = "${var.install_bitbucket_cloud}" ? 1 : 0
  path         = "/v1/fields"
  destroy_path = "/v1/fields/{id}"
  id_attribute = "fieldId"
  data         = <<JSON
  {
      "fieldName": "X-Event-Key"
  }
  JSON
}